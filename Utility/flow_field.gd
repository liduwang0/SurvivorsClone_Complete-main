extends Node2D

class_name FlowField

# 配置参数
@export var cell_size: int = 32  # 网格单元格大小
@export var field_bounds = Rect2(-400, -400, 800, 800)  # 流场覆盖的区域
@export var update_interval: float = 0.5  # 更新流场的时间间隔
@export var debug_draw: bool = false  # 是否绘制调试信息
@export var tilemap_path: NodePath  # TileMap的路径
@export var obstacle_cost: float = 20.0  # 障碍物成本
@export var only_calculate_visible_area: bool = true  # 是否只计算可见区域内的流场
@export var chunk_size: int = 16  # 分块计算大小，控制一次计算的区域
@export var use_threading: bool = false  # 是否使用线程
@export var visible_area_width: float = 1000.0  # 可见区域宽度
@export var visible_area_height: float = 1000.0  # 可见区域高度

# 内部变量
var grid_size: Vector2i  # 网格尺寸（列数和行数）
var integration_field: Array  # 存储到目标的距离值
var flow_field: Array  # 存储每个单元格的流向向量
var cost_field: Array  # 存储每个单元格的移动成本
var target_cell: Vector2i = Vector2i(-1, -1)  # 目标单元格
var is_ready: bool = false  # 流场是否准备好
var timer: Timer  # 更新计时器
var target_node: Node2D  # 目标节点（通常是玩家）
var obstacles: Array = []  # 存储障碍物节点
var tilemap: TileMap  # TileMap引用

# 线程相关
var _thread: Thread = null
var _mutex: Mutex = null
var _thread_exit: bool = false
var _thread_target_pos: Vector2 = Vector2.ZERO
var _needs_update: bool = false
var _update_completed: bool = false
var _thread_data = {}
var _cached_obstacles = []  # 缓存障碍物位置，线程可安全访问

# 调试绘制
var debug_arrows: Array = []  # 存储调试箭头

# 添加要识别为障碍物的瓦片定义
var obstacle_tiles = [
	# 小松树
	{"source_id": 5, "coords_start": Vector2i(16, 15), "coords_end": Vector2i(16, 16)},
	
	# 恐怖树
	{"source_id": 5, "coords_start": Vector2i(9, 17), "coords_end": Vector2i(9, 18)},
	
	# 枯树
	{"source_id": 5, "coords_start": Vector2i(10, 17), "coords_end": Vector2i(10, 18)},
	
	# 大白桦树
	{"source_id": 5, "coords_start": Vector2i(11, 17), "coords_end": Vector2i(12, 18)},
	
	# 大园树
	{"source_id": 5, "coords_start": Vector2i(12, 15), "coords_end": Vector2i(13, 16)},
	
	# 大松树
	{"source_id": 5, "coords_start": Vector2i(13, 17), "coords_end": Vector2i(14, 18)},
	
	# 大白桦树 深色
	{"source_id": 5, "coords_start": Vector2i(15, 17), "coords_end": Vector2i(16, 18)},
	
	# 大石头 水平2格
	{"source_id": 5, "coords_start": Vector2i(8, 21), "coords_end": Vector2i(9, 21)},
	
	# 石头4
	{"source_id": 5, "coords_start": Vector2i(9, 20), "coords_end": Vector2i(9, 20)},
	
	# 蘑菇3
	{"source_id": 5, "coords_start": Vector2i(8, 19), "coords_end": Vector2i(8, 19)},
	
	# 蘑菇8
	{"source_id": 5, "coords_start": Vector2i(13, 19), "coords_end": Vector2i(13, 19)},
	
	# 蘑菇6
	{"source_id": 5, "coords_start": Vector2i(11, 19), "coords_end": Vector2i(11, 19)},
	
	# 石头6
	{"source_id": 5, "coords_start": Vector2i(7, 21), "coords_end": Vector2i(7, 21)},
	
	# 石头9
	{"source_id": 5, "coords_start": Vector2i(11, 21), "coords_end": Vector2i(11, 21)},
	
	# 小树3（竖直两格，大型建筑物）
	{"source_id": 5, "coords_start": Vector2i(3, 24), "coords_end": Vector2i(6, 26)}
]

var last_target_position: Vector2 = Vector2.ZERO  # 上次更新时的目标位置
var position_threshold: float = 3.0  # 目标移动超过这个距离才更新
@export var dynamic_performance: bool = true  # 是否动态调整性能参数
var visible_bounds: Rect2  # 存储当前可见区域

# 保存原始field_bounds，用于恢复
var _original_field_bounds: Rect2

# 新增跟踪变量
var _last_process_position: Vector2 = Vector2.ZERO
var _time_since_last_update: float = 0.0
var _force_next_update: bool = false

func _ready():
	# 保存原始的field_bounds
	_original_field_bounds = Rect2(field_bounds.position, field_bounds.size)
	
	# 确保field_bounds是通过值初始化的
	field_bounds = Rect2(_original_field_bounds.position, _original_field_bounds.size)
	
	# 输出field_bounds信息，用于调试
	print("调试_ready: field_bounds设置为 = ", field_bounds)
	print("调试_ready: 流场更新间隔设置为 = ", update_interval, " 秒")
	
	# 计算网格尺寸
	grid_size = Vector2i(
		int(field_bounds.size.x / cell_size),
		int(field_bounds.size.y / cell_size)
	)
	
	print("调试_ready: 计算的网格尺寸 = ", grid_size)
	
	# 获取TileMap引用
	if not tilemap_path.is_empty():
		tilemap = get_node(tilemap_path)
	
	# 初始化各个场
	_initialize_fields()
	
	# 创建更新计时器 - 作为备用机制保留
	timer = Timer.new()
	timer.name = "FlowFieldUpdateTimer"
	timer.wait_time = update_interval * 2  # 设置更长的时间作为备用
	timer.autostart = true
	timer.one_shot = false
	timer.timeout.connect(_on_update_timer)
	add_child(timer)
	print("创建流场备用更新计时器，间隔: ", timer.wait_time, " 秒")
	
	# 自动查找并设置玩家作为目标节点
	if target_node == null:
		target_node = get_tree().get_first_node_in_group("player")
		if target_node:
			print("自动找到玩家节点:", target_node.name)
			_last_process_position = target_node.global_position  # 初始化位置跟踪
	
	# 初始化可见区域
	_update_visible_bounds()
	
	# 预缓存障碍物信息用于线程安全访问
	if use_threading and tilemap != null:
		_cache_obstacles()
	
	# 如果使用线程，则初始化线程相关组件
	if use_threading:
		_mutex = Mutex.new()
		_thread = Thread.new()
		_thread_exit = false
		_thread.start(_thread_function)
	
	# 强制第一次更新
	_force_next_update = true
	
	is_ready = true

# 缓存障碍物信息，以便线程可以安全访问
func _cache_obstacles():
	_cached_obstacles.clear()
	
	if tilemap == null:
		return
	
	# 获取当前可见区域，用于优化障碍物检测
	var visible_area = visible_bounds
	var expand_distance = cell_size * 5  # 稍微扩大检测范围
	var expanded_visible_area = Rect2(
		visible_area.position - Vector2(expand_distance, expand_distance),
		visible_area.size + Vector2(expand_distance * 2, expand_distance * 2)
	)
		
	# 遍历所有图层
	var layers_count = tilemap.get_layers_count()
	for layer in range(layers_count):
		# 获取该图层中的所有使用中的单元格
		var used_cells = tilemap.get_used_cells(layer)
		
		for cell_pos in used_cells:
			var world_pos = tilemap.map_to_local(cell_pos)
			world_pos = tilemap.to_global(world_pos)
			
			# 只处理可见区域附近的瓦片，以提高性能
			if !expanded_visible_area.has_point(world_pos) and only_calculate_visible_area:
				continue
			
			var source_id = tilemap.get_cell_source_id(layer, cell_pos)
			var atlas_coords = tilemap.get_cell_atlas_coords(layer, cell_pos)
			
			# 检查是否是障碍物瓦片
			var is_obstacle = false
			for obstacle in obstacle_tiles:
				if source_id == obstacle.source_id:
					if (atlas_coords.x >= obstacle.coords_start.x and 
						atlas_coords.y >= obstacle.coords_start.y and
						atlas_coords.x <= obstacle.coords_end.x and
						atlas_coords.y <= obstacle.coords_end.y):
						is_obstacle = true
						break
			
			# 检查瓦片是否有碰撞
			var tile_data = tilemap.get_cell_tile_data(layer, cell_pos)
			if tile_data != null and tile_data.get_collision_polygons_count(0) > 0:
				is_obstacle = true
				
			if is_obstacle:
				# 存储障碍物的世界坐标
				_cached_obstacles.append({
					"world_pos": world_pos,
					"source_id": source_id,
					"atlas_coords": atlas_coords,
					"cell_pos": cell_pos  # 保存原始单元格位置
				})
	
	# 调试信息
	if Engine.get_process_frames() % 120 == 0:
		print("障碍物缓存更新完成，共 ", _cached_obstacles.size(), " 个障碍物")

func _exit_tree():
	if use_threading and _thread != null:
		_mutex.lock()
		_thread_exit = true
		_mutex.unlock()
		_thread.wait_to_finish()

# 线程函数，在后台运行
func _thread_function():
	while true:
		# 检查是否退出线程
		_mutex.lock()
		var should_exit = _thread_exit
		_mutex.unlock()
		
		if should_exit:
			break
		
		# 检查是否需要更新
		_mutex.lock()
		var needs_update = _needs_update
		var target_pos = _thread_target_pos
		_mutex.unlock()
		
		if needs_update:
			# 执行计算，在线程中完成所有繁重工作
			var result = _calculate_flow_field_threaded(target_pos)
			
			# 将计算结果传回主线程
			_mutex.lock()
			_thread_data = result
			_needs_update = false
			_update_completed = true
			_mutex.unlock()
		
		# 短暂休眠，避免线程占用太多CPU
		OS.delay_msec(5)

# 从主线程调用，处理线程计算完成后的结果
func _process_thread_result():
	if not _update_completed:
		return
	
	_mutex.lock()
	var result = _thread_data
	_update_completed = false
	_mutex.unlock()
	
	# 应用计算结果
	cost_field = result.cost_field
	integration_field = result.integration_field
	flow_field = result.flow_field
	
	# 调试绘制
	if debug_draw:
		queue_redraw()

# 线程版本的障碍物成本计算
func _update_cost_field_threaded(t_cost_field, vis_bounds):
	# 重置成本场，确保先清除旧的障碍物标记
	for x in range(grid_size.x):
		for y in range(grid_size.y):
			t_cost_field[x][y] = 1  # 重置为默认成本
	
	# 获取可见区域在网格中的范围
	var visible_min = world_to_grid(vis_bounds.position)
	var visible_max = world_to_grid(vis_bounds.position + vis_bounds.size)
	
	# 使用缓存的障碍物信息
	_mutex.lock()
	var obstacles_copy = _cached_obstacles.duplicate()
	_mutex.unlock()
	
	# 处理缓存的障碍物
	for obstacle in obstacles_copy:
		var world_pos = obstacle.world_pos
		
		if not vis_bounds.has_point(world_pos) and only_calculate_visible_area:
			continue
		
		var grid_pos = world_to_grid(world_pos)
		var source_id = obstacle.source_id
		var atlas_coords = obstacle.atlas_coords
		
		# 添加影响区域
		var influence_radius = 1
		
		# 对于大型障碍物，增加影响范围
		if (source_id == 5 and atlas_coords.x >= 11 and atlas_coords.x <= 16 and 
			atlas_coords.y >= 17 and atlas_coords.y <= 18):
			# 大型树木
			influence_radius = 2
		elif (source_id == 5 and atlas_coords.x >= 3 and atlas_coords.x <= 6 and 
			atlas_coords.y >= 24 and atlas_coords.y <= 26):
			# 大型建筑物
			influence_radius = 3
		
		# 确保影响范围不会超出网格
		for dx in range(-influence_radius, influence_radius + 1):
			for dy in range(-influence_radius, influence_radius + 1):
				var obstacle_cell = Vector2i(grid_pos.x + dx, grid_pos.y + dy)
				if obstacle_cell.x >= 0 and obstacle_cell.x < grid_size.x and obstacle_cell.y >= 0 and obstacle_cell.y < grid_size.y:
					# 距离越远，成本越低
					var distance = Vector2(dx, dy).length()
					var cost_factor = 1.0 - (distance / (influence_radius + 1.0))
					cost_factor = max(0.2, cost_factor)
					
					# 对于直接位于障碍物中心的单元格，成本设为更高
					if dx == 0 and dy == 0:
						t_cost_field[obstacle_cell.x][obstacle_cell.y] = obstacle_cost * 1.5  # 中心点成本更高
					else:
						t_cost_field[obstacle_cell.x][obstacle_cell.y] = obstacle_cost * cost_factor

# 线程版本的集成场计算
func _calculate_integration_field_threaded(t_cost_field, t_integration_field, target_cell, vis_bounds):
	# 获取可见区域在网格中的范围
	var visible_min = world_to_grid(vis_bounds.position)
	var visible_max = world_to_grid(vis_bounds.position + vis_bounds.size)
	
	# 确保目标单元格在有效范围内
	if target_cell.x >= 0 and target_cell.x < grid_size.x and target_cell.y >= 0 and target_cell.y < grid_size.y:
		# 使用广度优先搜索填充集成场
		var open_list = []
		t_integration_field[target_cell.x][target_cell.y] = 0
		open_list.append(target_cell)
		
		while not open_list.is_empty():
			var current = open_list.pop_front()
			var current_cost = t_integration_field[current.x][current.y]
			
			# 检查相邻单元格（8个方向）
			var neighbors = [
				Vector2i(current.x + 1, current.y),
				Vector2i(current.x - 1, current.y),
				Vector2i(current.x, current.y + 1),
				Vector2i(current.x, current.y - 1),
				Vector2i(current.x + 1, current.y + 1),
				Vector2i(current.x - 1, current.y - 1),
				Vector2i(current.x + 1, current.y - 1),
				Vector2i(current.x - 1, current.y + 1)
			]
			
			for neighbor in neighbors:
				if neighbor.x >= 0 and neighbor.x < grid_size.x and neighbor.y >= 0 and neighbor.y < grid_size.y:
					# 只处理可见区域内的单元格
					if not only_calculate_visible_area or (
						neighbor.x >= visible_min.x and neighbor.x <= visible_max.x and
						neighbor.y >= visible_min.y and neighbor.y <= visible_max.y
					):
						var neighbor_cost = t_cost_field[neighbor.x][neighbor.y]
						
						# 跳过不可通行的单元格
						if neighbor_cost >= 50:
							continue
							
						var cost_to_neighbor = current_cost + neighbor_cost
						
						# 对角线移动成本应更高
						if neighbor.x != current.x and neighbor.y != current.y:
							cost_to_neighbor *= 1.4
							
						if cost_to_neighbor < t_integration_field[neighbor.x][neighbor.y]:
							t_integration_field[neighbor.x][neighbor.y] = cost_to_neighbor
							open_list.append(neighbor)

func _on_update_timer():
	# 输出调试信息
	if debug_draw:
		print("备用定时器触发流场更新")
	
	# 设置强制更新标志，确保下一帧一定更新
	_force_next_update = true

func _process(delta):
	if dynamic_performance:
		_adjust_performance_parameters()
		
	# 处理线程计算完成的结果
	if use_threading and _update_completed:
		_process_thread_result()
	
	# 可见区域每帧更新，确保它跟随玩家移动
	if is_ready and get_viewport().get_camera_2d() != null:
		_update_visible_bounds()
	
	# 基于玩家位置变化的主动更新机制
	if is_ready and target_node != null:
		# 累积自上次更新以来的时间
		_time_since_last_update += delta
		
		# 获取当前玩家位置
		var current_position = target_node.global_position
		
		# 计算自上次处理以来玩家移动的距离
		var distance_moved = _last_process_position.distance_to(current_position)
		
		# 更新上次处理位置
		_last_process_position = current_position
		
		# 检查是否应该更新流场:
		# 1. 如果强制更新标志为真
		# 2. 时间间隔已过
		# 3. 玩家移动足够距离
		var should_update = _force_next_update or _time_since_last_update >= update_interval or distance_moved >= position_threshold
		
		if should_update:
			# 非线程模式，直接调用更新
			if not use_threading:
				update_flow_field()
				if debug_draw:
					print("实时位置更新触发流场更新，移动: ", distance_moved, "，间隔: ", _time_since_last_update)
			# 线程模式，发送更新请求
			elif not _needs_update:  # 避免重复请求
				_mutex.lock()
				_needs_update = true
				_thread_target_pos = current_position
				_mutex.unlock()
				if debug_draw:
					print("实时位置更新触发线程流场更新，移动: ", distance_moved, "，间隔: ", _time_since_last_update)
				
			# 重置计时器和强制更新标志
			_time_since_last_update = 0.0
			_force_next_update = false
	
	# 确保调试绘制正常工作
	if debug_draw and is_ready:
		queue_redraw()
	
	# 周期性检查并打印边界信息（每100帧一次）
	if Engine.get_process_frames() % 100 == 0:
		# 检查field_bounds的完整性
		var is_field_bounds_intact = (field_bounds.position == _original_field_bounds.position and 
									field_bounds.size == _original_field_bounds.size)
		
		if not is_field_bounds_intact:
			print("========== 边界完整性警告 ==========")
			print("红色边界(field_bounds)已被修改!")
			print("当前值: 位置 = ", field_bounds.position, " 大小 = ", field_bounds.size)
			print("原始值: 位置 = ", _original_field_bounds.position, " 大小 = ", _original_field_bounds.size)
			print("====================================")
			
			# 修复field_bounds
			_ensure_field_bounds_integrity()

func _draw():
	if not debug_draw or not is_ready:
		return
	
	# 减少调试输出频率，每60帧输出一次
	if Engine.get_process_frames() % 60 == 0:
		print("========== 调试边界信息 ==========")
		print("红色边界(field_bounds): 位置 = ", field_bounds.position, " 大小 = ", field_bounds.size)
		print("绿色边界(visible_bounds): 位置 = ", visible_bounds.position, " 大小 = ", visible_bounds.size)
		print("==================================")
	
	# 首先绘制总场地边界，确保它在下层
	draw_rect(field_bounds, Color(1, 0, 0, 0.3), false, 5.0)
	
	# 直接绘制可见区域边界，不进行网格转换
	draw_rect(visible_bounds, Color(0, 1, 0, 0.4), false, 3.0)
	
	# 获取可见区域在网格中的范围，仅用于绘制障碍物和流场箭头
	var visible_min = world_to_grid(visible_bounds.position)
	var visible_max = world_to_grid(visible_bounds.position + visible_bounds.size)
	
	# 直接从TileMap获取障碍物信息，确保准确性
	if tilemap != null and debug_draw:
		_draw_tilemap_obstacles()
	
	# 绘制障碍物作为红色方块 - 从成本场获取
	for x in range(visible_min.x, visible_max.x, 1):
		for y in range(visible_min.y, visible_max.y, 1):
			if x < 0 or x >= grid_size.x or y < 0 or y >= grid_size.y:
				continue
				
			var pos = grid_to_world(Vector2i(x, y))
			
			# 如果是障碍物单元格，绘制红色方块
			if cost_field[x][y] >= obstacle_cost * 0.9:
				var rect_size = Vector2(cell_size * 0.3, cell_size * 0.3)
				draw_rect(Rect2(pos - rect_size/2, rect_size), Color.RED, true)
	
	# 绘制流场箭头
	for x in range(visible_min.x, visible_max.x, 2):
		for y in range(visible_min.y, visible_max.y, 2):
			if x < 0 or x >= grid_size.x or y < 0 or y >= grid_size.y:
				continue
				
			var pos = grid_to_world(Vector2i(x, y))
			var dir = flow_field[x][y]
			
			if dir != Vector2.ZERO:
				var end = pos + dir * cell_size * 0.5
				var arrow_size = cell_size * 0.2
				
				# 计算箭头的两个尖角
				var angle = dir.angle()
				var angle1 = angle + 2.5
				var angle2 = angle - 2.5
				var point1 = end + Vector2(cos(angle1), sin(angle1)) * arrow_size
				var point2 = end + Vector2(cos(angle2), sin(angle2)) * arrow_size
				
				# 绘制线段和箭头
				draw_line(pos, end, Color.BLUE, 1.0)
				draw_line(end, point1, Color.BLUE, 1.0)
				draw_line(end, point2, Color.BLUE, 1.0)

# 新函数：直接从TileMap绘制障碍物，确保准确性
func _draw_tilemap_obstacles():
	if tilemap == null:
		return
		
	var layers_count = tilemap.get_layers_count()
	
	# 遍历所有图层查找障碍物
	for layer in range(layers_count):
		var used_cells = tilemap.get_used_cells(layer)
		
		for cell_pos in used_cells:
			var source_id = tilemap.get_cell_source_id(layer, cell_pos)
			var atlas_coords = tilemap.get_cell_atlas_coords(layer, cell_pos)
			
			# 检查是否是障碍物瓦片
			var is_obstacle = false
			for obstacle in obstacle_tiles:
				if source_id == obstacle.source_id:
					if (atlas_coords.x >= obstacle.coords_start.x and 
						atlas_coords.y >= obstacle.coords_start.y and
						atlas_coords.x <= obstacle.coords_end.x and
						atlas_coords.y <= obstacle.coords_end.y):
						is_obstacle = true
						break
			
			# 检查瓦片是否有碰撞
			var tile_data = tilemap.get_cell_tile_data(layer, cell_pos)
			if tile_data != null and tile_data.get_collision_polygons_count(0) > 0:
				is_obstacle = true
				
			if is_obstacle:
				# 获取世界坐标
				var world_pos = tilemap.map_to_local(cell_pos)
				world_pos = tilemap.to_global(world_pos)
				
				# 只绘制在可见区域内的障碍物
				if visible_bounds.has_point(world_pos):
					# 绘制一个小红点标记实际障碍物位置
					var mark_size = cell_size * 0.15
					draw_circle(world_pos, mark_size, Color(1, 0, 0, 0.7))

# 线程版流场计算，完全在线程中执行
func _calculate_flow_field_threaded(player_pos):
	# 确保field_bounds的完整性
	_ensure_field_bounds_integrity()
	
	# 创建线程独立的数据结构
	var t_cost_field = []
	var t_integration_field = []
	var t_flow_field = []
	
	# 初始化成本场
	for x in range(grid_size.x):
		t_cost_field.append([])
		t_integration_field.append([])
		t_flow_field.append([])
		for y in range(grid_size.y):
			t_cost_field[x].append(1)
			t_integration_field[x].append(INF)
			t_flow_field[x].append(Vector2.ZERO)
	
	# 在线程中计算可见区域 - 使用相同的逻辑保持一致性
	var half_width = visible_area_width / 2
	var half_height = visible_area_height / 2
	var top_left = Vector2(player_pos.x - half_width, player_pos.y - half_height)
	var rect_size = Vector2(visible_area_width, visible_area_height)
	
	# 创建玩家周围的可见区域
	var visible_area = Rect2(top_left, rect_size)
	
	# 创建field_bounds的安全副本，避免修改原始值
	var safe_field_bounds = Rect2(_original_field_bounds.position, _original_field_bounds.size)
	
	# 计算交集，确保可见区域不超出场地边界
	var vis_bounds = visible_area.intersection(safe_field_bounds)
	
	# 目标单元格
	var t_target_cell = world_to_grid(player_pos)
	
	# 更新障碍物成本
	_update_cost_field_threaded(t_cost_field, vis_bounds)
	
	# 计算集成场
	_calculate_integration_field_threaded(t_cost_field, t_integration_field, t_target_cell, vis_bounds)
	
	# 计算流场
	_calculate_flow_direction_threaded(t_integration_field, t_flow_field, vis_bounds)
	
	# 计算完成后，确保field_bounds没有被修改
	_ensure_field_bounds_integrity()
	
	# 返回计算结果
	return {
		"cost_field": t_cost_field,
		"integration_field": t_integration_field,
		"flow_field": t_flow_field
	}

func _initialize_fields():
	# 初始化成本场
	cost_field = []
	for x in range(grid_size.x):
		cost_field.append([])
		for y in range(grid_size.y):
			cost_field[x].append(1)  # 默认成本为1
	
	# 初始化集成场和流场
	integration_field = []
	flow_field = []
	for x in range(grid_size.x):
		integration_field.append([])
		flow_field.append([])
		for y in range(grid_size.y):
			integration_field[x].append(INF)  # 初始距离为无穷大
			flow_field[x].append(Vector2.ZERO)  # 初始流向为零向量

func set_target(target: Node2D):
	target_node = target

func add_obstacle(obstacle: Node2D, cost: float = 10.0):
	obstacles.append({"node": obstacle, "cost": cost})
	
func world_to_grid(world_pos: Vector2) -> Vector2i:
	var relative_pos = world_pos - field_bounds.position
	var grid_x = int(relative_pos.x / cell_size)
	var grid_y = int(relative_pos.y / cell_size)
	
	# 确保坐标在有效范围内
	grid_x = clamp(grid_x, 0, grid_size.x - 1)
	grid_y = clamp(grid_y, 0, grid_size.y - 1)
	
	return Vector2i(grid_x, grid_y)

func grid_to_world(grid_pos: Vector2i) -> Vector2:
	return Vector2(
		grid_pos.x * cell_size + field_bounds.position.x + cell_size/2,
		grid_pos.y * cell_size + field_bounds.position.y + cell_size/2
	)

func is_valid_cell(cell: Vector2i) -> bool:
	return (cell.x >= 0 and cell.x < grid_size.x and 
			cell.y >= 0 and cell.y < grid_size.y)

func _adjust_performance_parameters():
	# 获取当前敌人数量
	var enemies = get_tree().get_nodes_in_group("enemy")
	var enemy_count = enemies.size()
	
	# 之前的更新间隔
	var previous_interval = update_interval
	
	# 根据敌人数量动态调整参数
	if enemy_count > 50:
		# 大量敌人：低精度，慢更新
		update_interval = 0.3
		position_threshold = 4.0
	elif enemy_count > 25:
		# 中等敌人：中等精度
		update_interval = 0.5
		position_threshold = 3.0
	else:
		# 少量敌人：高精度，快更新
		update_interval = 0.3
		position_threshold = 3.0
	
	# 如果更新间隔改变了，更新定时器
	if previous_interval != update_interval and timer != null:
		timer.wait_time = update_interval
		
		# 输出调试信息
		if debug_draw and Engine.get_process_frames() % 60 == 0:
			print("动态调整流场更新间隔: ", previous_interval, " -> ", update_interval, " 秒 (敌人数量: ", enemy_count, ")")

func update_flow_field():
	if target_node == null:
		# 尝试找到玩家节点
		target_node = get_tree().get_first_node_in_group("player")
		if target_node == null:
			return
	
	# 确保field_bounds的完整性
	_ensure_field_bounds_integrity()
	
	# 更新可见区域
	_update_visible_bounds()
	
	# 获取当前时间，用于调试输出
	var current_time = Time.get_ticks_msec() / 1000.0
	
	# 获取目标位置
	var target_position = target_node.global_position
	last_target_position = target_position
	
	# 定期更新障碍物缓存
	_cache_obstacles()
	
	# 计算目标单元格
	var new_target_cell = world_to_grid(target_position)
	
	# 输出调试信息
	if debug_draw and target_cell != new_target_cell:
		if target_cell != Vector2i(-1, -1):
			print("目标单元格改变: ", target_cell, " -> ", new_target_cell)
		else:
			print("首次设置目标单元格: ", new_target_cell)
	
	# 更新目标单元格
	target_cell = new_target_cell
	
	# 确保目标单元格在有效范围内
	if not is_valid_cell(target_cell):
		target_cell.x = clamp(target_cell.x, 0, grid_size.x - 1)
		target_cell.y = clamp(target_cell.y, 0, grid_size.y - 1)
	
	# 重置成本场
	for x in range(grid_size.x):
		for y in range(grid_size.y):
			cost_field[x][y] = 1
	
	# 更新障碍物成本
	_update_cost_field()
	
	# 计算集成场
	_calculate_integration_field()
	
	# 计算流场
	_calculate_flow_field()
	
	# 调试绘制
	if debug_draw:
		queue_redraw()
		print("流场更新完成，耗时: ", (Time.get_ticks_msec() / 1000.0) - current_time, " 秒")
	
	# 更新后再次检查field_bounds的完整性
	_ensure_field_bounds_integrity()

func _update_cost_field():
	# 重置成本场
	for x in range(grid_size.x):
		for y in range(grid_size.y):
			cost_field[x][y] = 1
	
	# 检查TileMap障碍物
	if tilemap != null:
		# 方法1: 使用ObstacleData节点中的标记（这是最高效的方法）
		var obstacle_data = tilemap.get_node_or_null("ObstacleData")
		if obstacle_data != null:
			print("找到ObstacleData节点，障碍物标记数量: ", obstacle_data.get_child_count())
			for marker in obstacle_data.get_children():
				if marker.has_meta("is_obstacle") and marker.get_meta("is_obstacle"):
					# 将标记位置转换为流场网格坐标
					var world_pos = tilemap.to_global(marker.position)
					var grid_pos = world_to_grid(world_pos)
					
					# 确定影响半径
					var influence_radius = 1
					
					# 水域的影响半径更小
					if marker.has_meta("is_water") and marker.get_meta("is_water"):
						influence_radius = 0
					else:
						# 树木和其他障碍物的影响半径更大
						influence_radius = 1
					
					# 添加影响区域
					for dx in range(-influence_radius, influence_radius + 1):
						for dy in range(-influence_radius, influence_radius + 1):
							var obstacle_cell = Vector2i(grid_pos.x + dx, grid_pos.y + dy)
							if is_valid_cell(obstacle_cell):
								# 确保障碍物代价足够高，以便敌人绕行
								cost_field[obstacle_cell.x][obstacle_cell.y] = obstacle_cost
			
			if debug_draw:
				print("障碍物标记已应用到流场中，网格大小: ", grid_size, "，单元格大小: ", cell_size)
			return  # 如果使用了ObstacleData，就不需要再使用其他检测方法
		else:
			print("未找到ObstacleData节点，尝试其他障碍物检测方法")
		
		# 方法2: 使用预定义的障碍物瓦片检测（如果ObstacleData不存在）
		_add_tilemap_obstacles()
	
	# 方法3: 检测StaticBody2D（可选，但更消耗性能）
	if _should_check_static_bodies:
		_add_static_body_obstacles()

# 将物理检测分离为单独的函数
func _add_static_body_obstacles():
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.collision_mask = 1  # 障碍物碰撞层
	
	# 优化：不检查每个单元格，而是间隔检查
	var check_interval = 2  # 每隔多少个单元格检查一次
	
	for x in range(0, grid_size.x, check_interval):
		for y in range(0, grid_size.y, check_interval):
			var world_pos = grid_to_world(Vector2i(x, y))
			query.position = world_pos
			
			var result = space_state.intersect_point(query)
			if result.size() > 0:
				for collision in result:
					# 检查碰撞对象是否是静态障碍物
					if collision.collider is StaticBody2D:
						# 将检测到的障碍应用到周围单元格
						for dx in range(check_interval):
							for dy in range(check_interval):
								var cell_x = x + dx
								var cell_y = y + dy
								if is_valid_cell(Vector2i(cell_x, cell_y)):
									cost_field[cell_x][cell_y] = obstacle_cost

# 添加一个控制是否使用物理检测的变量
@export var _should_check_static_bodies: bool = false

func _calculate_integration_field():
	# 初始化所有单元格为无穷大
	for x in range(grid_size.x):
		for y in range(grid_size.y):
			integration_field[x][y] = INF
	
	# 使用广度优先搜索填充集成场
	var open_list = []
	integration_field[target_cell.x][target_cell.y] = 0
	open_list.append(target_cell)
	
	# 如果只计算可见区域，则获取可见区域范围
	var visible_min = Vector2i(0, 0)
	var visible_max = Vector2i(grid_size.x - 1, grid_size.y - 1)
	
	if only_calculate_visible_area:
		visible_min = world_to_grid(visible_bounds.position)
		visible_max = world_to_grid(visible_bounds.position + visible_bounds.size)
		
		# 确保范围在有效的网格大小内
		visible_min.x = clamp(visible_min.x, 0, grid_size.x - 1)
		visible_min.y = clamp(visible_min.y, 0, grid_size.y - 1)
		visible_max.x = clamp(visible_max.x, 0, grid_size.x - 1)
		visible_max.y = clamp(visible_max.y, 0, grid_size.y - 1)
	
	while not open_list.is_empty():
		var current = open_list.pop_front()
		var current_cost = integration_field[current.x][current.y]
		
		# 检查相邻单元格（8个方向）
		var neighbors = [
			Vector2i(current.x + 1, current.y),      # 右
			Vector2i(current.x - 1, current.y),      # 左
			Vector2i(current.x, current.y + 1),      # 下
			Vector2i(current.x, current.y - 1),      # 上
			Vector2i(current.x + 1, current.y + 1),  # 右下
			Vector2i(current.x - 1, current.y - 1),  # 左上
			Vector2i(current.x + 1, current.y - 1),  # 右上
			Vector2i(current.x - 1, current.y + 1)   # 左下
		]
		
		for neighbor in neighbors:
			if is_valid_cell(neighbor):
				# 如果只计算可见区域，需要检查该单元格是否在可见范围内
				if only_calculate_visible_area and (
					neighbor.x < visible_min.x or neighbor.x > visible_max.x or
					neighbor.y < visible_min.y or neighbor.y > visible_max.y
				):
					continue
					
				var neighbor_cost = cost_field[neighbor.x][neighbor.y]
				
				# 跳过不可通行的单元格
				if neighbor_cost >= 50:
					continue
					
				var cost_to_neighbor = current_cost + neighbor_cost
				
				# 对角线移动成本应更高
				if neighbor.x != current.x and neighbor.y != current.y:
					cost_to_neighbor *= 1.4
					
				if cost_to_neighbor < integration_field[neighbor.x][neighbor.y]:
					integration_field[neighbor.x][neighbor.y] = cost_to_neighbor
					open_list.append(neighbor)

func _calculate_flow_field():
	# 计算流场（每个单元格指向集成场中值最低的相邻单元格）
	for x in range(grid_size.x):
		for y in range(grid_size.y):
			# 如果只计算可见区域，跳过不在可见区域内的单元格
			if only_calculate_visible_area:
				var visible_min = world_to_grid(visible_bounds.position)
				var visible_max = world_to_grid(visible_bounds.position + visible_bounds.size)
				
				# 确保范围在有效的网格大小内
				visible_min.x = clamp(visible_min.x, 0, grid_size.x - 1)
				visible_min.y = clamp(visible_min.y, 0, grid_size.y - 1)
				visible_max.x = clamp(visible_max.x, 0, grid_size.x - 1)
				visible_max.y = clamp(visible_max.y, 0, grid_size.y - 1)
				
				if x < visible_min.x or x > visible_max.x or y < visible_min.y or y > visible_max.y:
					continue
			
			# 跳过不可通行的单元格
			if cost_field[x][y] >= 50:
				flow_field[x][y] = Vector2.ZERO
				continue
				
			# 目标单元格无需流向任何地方
			if x == target_cell.x and y == target_cell.y:
				flow_field[x][y] = Vector2.ZERO
				continue
				
			var current_cell = Vector2i(x, y)
			var neighbors = [
				Vector2i(x + 1, y),      # 右
				Vector2i(x - 1, y),      # 左
				Vector2i(x, y + 1),      # 下
				Vector2i(x, y - 1),      # 上
				Vector2i(x + 1, y + 1),  # 右下
				Vector2i(x - 1, y - 1),  # 左上
				Vector2i(x + 1, y - 1),  # 右上
				Vector2i(x - 1, y + 1)   # 左下
			]
			
			var lowest_cost = INF
			var best_direction = Vector2.ZERO
			
			for neighbor in neighbors:
				if is_valid_cell(neighbor):
					# 如果邻居是不可通行的，跳过
					if cost_field[neighbor.x][neighbor.y] >= 50:
						continue
					
					var neighbor_cost = integration_field[neighbor.x][neighbor.y]
					if neighbor_cost < lowest_cost:
						lowest_cost = neighbor_cost
						best_direction = grid_to_world(neighbor) - grid_to_world(current_cell)
						best_direction = best_direction.normalized()
						
			flow_field[x][y] = best_direction

func get_flow_direction(world_position: Vector2) -> Vector2:
	if not is_ready:
		return Vector2.ZERO
	
	# 原来的问题：这里先检查是否在可见区域，如果不在，就直接返回朝向玩家的向量
	# 但这会导致只有可见区域内的敌人才会使用流场，可见区域外的敌人直接朝向玩家
	# 修改：即使在可见区域外，也应该使用流场，只要在field_bounds内
	
	var cell = world_to_grid(world_position)
	if not is_valid_cell(cell):
		return Vector2.ZERO  # 超出field_bounds边界
	
	# 检查是否在当前计算的流场区域内
	if only_calculate_visible_area:
		# 1. 如果在当前计算的流场范围内，使用流场方向
		if visible_bounds.has_point(world_position):
			if use_threading:
				_mutex.lock()
				var direction = flow_field[cell.x][cell.y] if cell.x < flow_field.size() and cell.y < flow_field[cell.x].size() else Vector2.ZERO
				_mutex.unlock()
				return direction
			else:
				return flow_field[cell.x][cell.y]
		else:
			# 2. 如果不在当前流场范围内，但在field_bounds内，则向最近的计算区域移动
			# 计算从当前位置到可见区域边缘的最短方向
			var closest_point = _get_closest_point_on_rect(world_position, visible_bounds)
			return (closest_point - world_position).normalized()
	else:
		# 没有启用只计算可见区域，直接返回流场方向
		if use_threading:
			_mutex.lock()
			var direction = flow_field[cell.x][cell.y] if cell.x < flow_field.size() and cell.y < flow_field[cell.x].size() else Vector2.ZERO
			_mutex.unlock()
			return direction
		else:
			return flow_field[cell.x][cell.y]

# 计算点到矩形的最近点
func _get_closest_point_on_rect(point: Vector2, rect: Rect2) -> Vector2:
	var closest = point
	
	# 水平方向的最近点
	if point.x < rect.position.x:
		closest.x = rect.position.x
	elif point.x > rect.position.x + rect.size.x:
		closest.x = rect.position.x + rect.size.x
	
	# 垂直方向的最近点
	if point.y < rect.position.y:
		closest.y = rect.position.y
	elif point.y > rect.position.y + rect.size.y:
		closest.y = rect.position.y + rect.size.y
	
	return closest

# 更新可见区域边界
func _update_visible_bounds():
	# 确保field_bounds的完整性
	_ensure_field_bounds_integrity()
	
	# 记录更新前的可见区域
	var old_visible_bounds = Rect2(visible_bounds.position, visible_bounds.size) if is_ready else Rect2()
	
	# 获取玩家位置（相机位置）
	var player_pos = Vector2.ZERO
	var camera = get_viewport().get_camera_2d()
	if camera != null:
		player_pos = camera.global_position
	else:
		# 如果没有相机，尝试找到玩家节点
		var player = get_tree().get_first_node_in_group("player")
		if player != null:
			player_pos = player.global_position
	
	# 简单直接地计算可见区域 - 以玩家为中心
	var half_width = visible_area_width / 2
	var half_height = visible_area_height / 2
	
	# 左上角坐标 = 玩家位置 - 半宽/半高
	var top_left = Vector2(player_pos.x - half_width, player_pos.y - half_height)
	# 矩形大小 = 宽度×高度
	var rect_size = Vector2(visible_area_width, visible_area_height)
	
	# 创建可见区域矩形 - 这是玩家周围的区域
	visible_bounds = Rect2(top_left, rect_size)
	
	# 确保可见区域不超出field_bounds
	# 创建field_bounds的安全副本，确保不修改原始值
	var safe_field_bounds = Rect2(_original_field_bounds.position, _original_field_bounds.size)
	
	# 计算交集，确保可见区域在field_bounds内
	visible_bounds = visible_bounds.intersection(safe_field_bounds)
	
	# 当可见区域更新时，同时更新障碍物信息
	if use_threading or (old_visible_bounds.position - visible_bounds.position).length() > cell_size:
		_cache_obstacles()
	
	# 只在每30帧或明显变化时打印调试信息
	if Engine.get_process_frames() % 30 == 0 or (old_visible_bounds.position - visible_bounds.position).length() > cell_size:
		print("========== 可见区域更新 ==========")
		print("玩家位置: ", player_pos)
		print("可见区域设置: ", visible_area_width, " x ", visible_area_height)
		print("更新前绿色边界: 位置 = ", old_visible_bounds.position, " 大小 = ", old_visible_bounds.size)
		print("更新后绿色边界: 位置 = ", visible_bounds.position, " 大小 = ", visible_bounds.size)
		print("红色边界(field_bounds): 位置 = ", field_bounds.position, " 大小 = ", field_bounds.size)
		print("==================================")
	
	# 更新完成后，确保field_bounds没有被修改
	_ensure_field_bounds_integrity()

# 检查一个世界坐标是否在当前可见区域内
func is_in_visible_area(world_pos: Vector2) -> bool:
	if not only_calculate_visible_area:
		return true
	return visible_bounds.has_point(world_pos)

# 线程版本的流场方向计算
func _calculate_flow_direction_threaded(t_integration_field, t_flow_field, vis_bounds):
	# 获取可见区域在网格中的范围
	var visible_min = world_to_grid(vis_bounds.position)
	var visible_max = world_to_grid(vis_bounds.position + vis_bounds.size)
	
	# 只在可见区域内计算流场
	for x in range(visible_min.x, visible_max.x + 1):
		for y in range(visible_min.y, visible_max.y + 1):
			if x < 0 or x >= grid_size.x or y < 0 or y >= grid_size.y:
				continue
				
			var current_value = t_integration_field[x][y]
			
			# 如果当前单元格不可达，设为零向量
			if current_value == INF:
				t_flow_field[x][y] = Vector2.ZERO
				continue
			
			# 寻找集成场值最低的相邻单元格
			var neighbors = [
				Vector2i(x + 1, y),
				Vector2i(x - 1, y),
				Vector2i(x, y + 1),
				Vector2i(x, y - 1),
				Vector2i(x + 1, y + 1),
				Vector2i(x - 1, y - 1),
				Vector2i(x + 1, y - 1),
				Vector2i(x - 1, y + 1)
			]
			
			var lowest_value = current_value
			var best_direction = Vector2.ZERO
			
			for neighbor in neighbors:
				if neighbor.x >= 0 and neighbor.x < grid_size.x and neighbor.y >= 0 and neighbor.y < grid_size.y:
					var neighbor_value = t_integration_field[neighbor.x][neighbor.y]
					if neighbor_value < lowest_value:
						lowest_value = neighbor_value
						best_direction = Vector2(neighbor.x - x, neighbor.y - y).normalized()
			
			t_flow_field[x][y] = best_direction

func _add_tilemap_obstacles():
	# 获取TileMap的所有图层
	var layers_count = tilemap.get_layers_count()
	
	# 创建一个集合来存储已知的障碍物位置，避免重复检测
	var known_obstacles = {}
	
	# 获取当前可见区域，用于优化障碍物检测
	var visible_area = visible_bounds
	var expand_distance = cell_size * 5  # 稍微扩大检测范围
	var expanded_visible_area = Rect2(
		visible_area.position - Vector2(expand_distance, expand_distance),
		visible_area.size + Vector2(expand_distance * 2, expand_distance * 2)
	)
	
	# 方法1: 检测预定义的障碍物瓦片（高效）
	for layer in range(layers_count):
		# 获取该图层中的所有使用中的单元格
		var used_cells = tilemap.get_used_cells(layer)
		
		for cell_pos in used_cells:
			# 获取世界坐标
			var world_pos = tilemap.map_to_local(cell_pos)
			world_pos = tilemap.to_global(world_pos)
			
			# 只处理可见区域附近的瓦片，以提高性能
			if !expanded_visible_area.has_point(world_pos) and only_calculate_visible_area:
				continue
			
			var source_id = tilemap.get_cell_source_id(layer, cell_pos)
			var atlas_coords = tilemap.get_cell_atlas_coords(layer, cell_pos)
			
			# 转换为字符串键，用于快速查找
			var key = str(cell_pos.x) + "," + str(cell_pos.y)
			
			# 如果这个位置已经标记为障碍物，跳过
			if known_obstacles.has(key):
				continue
			
			# 检查是否是预定义的障碍物瓦片
			var is_obstacle = false
			for obstacle in obstacle_tiles:
				if source_id == obstacle.source_id:
					# 检查坐标范围
					if (atlas_coords.x >= obstacle.coords_start.x and 
						atlas_coords.y >= obstacle.coords_start.y and
						atlas_coords.x <= obstacle.coords_end.x and
						atlas_coords.y <= obstacle.coords_end.y):
						is_obstacle = true
						break
			
			# 检查瓦片是否有碰撞
			var tile_data = tilemap.get_cell_tile_data(layer, cell_pos)
			if tile_data != null and tile_data.get_collision_polygons_count(0) > 0:
				is_obstacle = true
				
			if is_obstacle:
				# 将瓦片的世界坐标转换为流场网格坐标
				var grid_pos = world_to_grid(world_pos)
				
				# 记录这个障碍物位置
				known_obstacles[key] = true
				
				# 给障碍物和周围区域添加高成本
				# 根据障碍物类型调整影响范围
				var influence_radius = 1
				
				# 对于大型障碍物，增加影响范围
				if (source_id == 5 and atlas_coords.x >= 11 and atlas_coords.x <= 16 and 
					atlas_coords.y >= 17 and atlas_coords.y <= 18):
					# 大型树木
					influence_radius = 2
				elif (source_id == 5 and atlas_coords.x >= 3 and atlas_coords.x <= 6 and 
					atlas_coords.y >= 24 and atlas_coords.y <= 26):
					# 大型建筑物
					influence_radius = 3
				
				for dx in range(-influence_radius, influence_radius + 1):
					for dy in range(-influence_radius, influence_radius + 1):
						var obstacle_cell = Vector2i(grid_pos.x + dx, grid_pos.y + dy)
						if is_valid_cell(obstacle_cell):
							# 距离越远，成本越低，实现平滑过渡
							var distance = Vector2(dx, dy).length()
							var cost_factor = 1.0 - (distance / (influence_radius + 1.0))
							cost_factor = max(0.2, cost_factor)  # 至少20%的成本
							
							# 对于直接位于障碍物中心的单元格，成本设为更高
							if dx == 0 and dy == 0:
								cost_field[obstacle_cell.x][obstacle_cell.y] = obstacle_cost * 1.5  # 中心点成本更高
							else:
								cost_field[obstacle_cell.x][obstacle_cell.y] = obstacle_cost * cost_factor

# 确保field_bounds不被修改的方法
func _ensure_field_bounds_integrity():
	# 检查position和size是否完全相同
	if field_bounds.position != _original_field_bounds.position or field_bounds.size != _original_field_bounds.size:
		print("警告：field_bounds被修改，正在恢复...")
		print("当前值:", field_bounds)
		print("正确值:", _original_field_bounds)
		
		# 创建一个全新的Rect2实例，确保完全断开任何可能的引用
		field_bounds = Rect2(_original_field_bounds.position.x, _original_field_bounds.position.y, 
							_original_field_bounds.size.x, _original_field_bounds.size.y)
