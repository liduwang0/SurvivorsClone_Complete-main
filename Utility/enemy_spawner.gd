extends Node2D

@export var spawns: Array[Spawn_info] = []

# 性能优化设置
@export var enable_optimization: bool = true  # 是否启用优化
@export var max_enemies: int = 300  # 最大敌人数量限制
@export var max_enemies_per_spawn: int = 30  # 每次生成的最大敌人数量
@export var culling_distance: float = 2000.0  # 超过此距离的敌人会被清除
@export var check_culling_interval: int = 5  # 每隔多少秒检查一次清理

@onready var player = get_tree().get_first_node_in_group("player")
@onready var flow_field = get_node_or_null("../FlowField")
@onready var tilemap = get_node_or_null("../TileMap")

@export var time = 0

var enemy_count = 0  # 当前敌人数量
var culling_timer = 0  # 清理计时器
var max_position_attempts = 10  # 最大尝试次数，防止无限循环

signal changetime(time)

func _ready():
	connect("changetime",Callable(player,"change_time"))
	
	# 设置流场的目标（玩家）
	if flow_field:
		flow_field.set_target(player)

func _process(delta):
	# 定期检查是否需要清理远处的敌人
	if enable_optimization:
		culling_timer += delta
		if culling_timer >= check_culling_interval:
			culling_timer = 0
			cull_distant_enemies()

func _on_timer_timeout():
	time += 1
	var enemy_spawns = spawns
	
	# 统计当前敌人数量
	if enable_optimization:
		enemy_count = get_tree().get_nodes_in_group("enemy").size()
		
		# 如果敌人数量已达到上限，则不再生成
		if enemy_count >= max_enemies:
			emit_signal("changetime", time)
			return
	
	for i in enemy_spawns:
		if time >= i.time_start and time <= i.time_end:
			if i.spawn_delay_counter < i.enemy_spawn_delay:
				i.spawn_delay_counter += 1
			else:
				i.spawn_delay_counter = 0
				var new_enemy = i.enemy
				var counter = 0
				
				# 计算本次实际要生成的敌人数量
				var spawn_count = i.enemy_num
				if enable_optimization:
					# 确保不超过每次生成上限
					spawn_count = min(spawn_count, max_enemies_per_spawn)
					# 确保不超过总体上限
					spawn_count = min(spawn_count, max_enemies - enemy_count)
					# 如果没有空间生成敌人，直接跳过
					if spawn_count <= 0:
						continue
				
				while counter < spawn_count:
					# 获取一个随机位置
					var spawn_position = get_random_position()
					
					# 如果返回的是null，表示无法找到有效的非水域位置，跳过此次生成
					if spawn_position == null:
						continue
						
					var enemy_spawn = new_enemy.instantiate()
					enemy_spawn.global_position = spawn_position
					
					# 如果敌人支持流场寻路，并且Spawn_info配置了使用流场
					if i.use_flow_field and "use_flow_field" in enemy_spawn:
						enemy_spawn.use_flow_field = true
					
					# 如果启用了优化，配置敌人的优化设置
					if enable_optimization and "enable_optimization" in enemy_spawn:
						enemy_spawn.enable_optimization = true
						
						# 根据当前敌人总数调整优化参数
						if enemy_count > 150:
							# 非常多敌人时使用更激进的优化
							enemy_spawn.medium_distance = 600.0
							enemy_spawn.far_distance = 1000.0
							enemy_spawn.medium_update_frames = 4
							enemy_spawn.far_update_frames = 8
						elif enemy_count > 80:
							# 较多敌人时的中等优化
							enemy_spawn.medium_distance = 700.0
							enemy_spawn.far_distance = 1200.0
							enemy_spawn.medium_update_frames = 3
							enemy_spawn.far_update_frames = 6
					
					# 将敌人添加到"enemy"组以便于管理
					if !enemy_spawn.is_in_group("enemy"):
						enemy_spawn.add_to_group("enemy")
					
					add_child(enemy_spawn)
					counter += 1
					enemy_count += 1
					
	emit_signal("changetime", time)

# 清理远离玩家的敌人
func cull_distant_enemies():
	if player == null:
		return
		
	var enemies = get_tree().get_nodes_in_group("enemy")
	for enemy in enemies:
		if enemy.global_position.distance_to(player.global_position) > culling_distance:
			# 如果敌人有自定义移除信号，触发它
			if enemy.has_signal("remove_from_array"):
				enemy.emit_signal("remove_from_array", enemy)
			# 移除敌人
			enemy.queue_free()
			enemy_count -= 1

func get_random_position():
	var vpr = get_viewport_rect().size * randf_range(1.1,1.4)
	var top_left = Vector2(player.global_position.x - vpr.x/2, player.global_position.y - vpr.y/2)
	var top_right = Vector2(player.global_position.x + vpr.x/2, player.global_position.y - vpr.y/2)
	var bottom_left = Vector2(player.global_position.x - vpr.x/2, player.global_position.y + vpr.y/2)
	var bottom_right = Vector2(player.global_position.x + vpr.x/2, player.global_position.y + vpr.y/2)
	var pos_side = ["up","down","right","left"].pick_random()
	var spawn_pos1 = Vector2.ZERO
	var spawn_pos2 = Vector2.ZERO
	
	match pos_side:
		"up":
			spawn_pos1 = top_left
			spawn_pos2 = top_right
		"down":
			spawn_pos1 = bottom_left
			spawn_pos2 = bottom_right
		"right":
			spawn_pos1 = top_right
			spawn_pos2 = bottom_right
		"left":
			spawn_pos1 = top_left
			spawn_pos2 = bottom_left
	
	# 尝试最多max_position_attempts次找到一个不在水里的位置
	var attempts = 0
	var position = Vector2.ZERO
	var is_valid_position = false
	
	while attempts < max_position_attempts and not is_valid_position:
		var x_spawn = randf_range(spawn_pos1.x, spawn_pos2.x)
		var y_spawn = randf_range(spawn_pos1.y, spawn_pos2.y)
		position = Vector2(x_spawn, y_spawn)
		
		# 检查位置是否不在水中
		is_valid_position = not is_position_in_water(position)
		attempts += 1
	
	# 如果找不到非水域位置，返回null表示不应生成敌人
	if not is_valid_position:
		return null
		
	# 返回有效的非水域位置
	return position

# 新增函数：检查位置是否在水中
func is_position_in_water(position: Vector2) -> bool:
	# 方法1：检查ObstacleData节点中的水域标记 - 优先使用这种方法，因为它最准确
	var obstacle_data = null
	
	# 尝试获取不同路径下的ObstacleData节点
	if tilemap != null:
		obstacle_data = tilemap.get_node_or_null("ObstacleData")
	else:
		# 如果没有直接引用到TileMap，尝试在不同路径找到它
		var world_tilemap = get_node_or_null("../TileMap")
		if world_tilemap != null:
			obstacle_data = world_tilemap.get_node_or_null("ObstacleData")
		else:
			# 查找第一个TileMap节点
			var tilemaps = get_tree().get_nodes_in_group("tilemap")
			if tilemaps.size() > 0:
				obstacle_data = tilemaps[0].get_node_or_null("ObstacleData")
	
	if obstacle_data != null:
		var cell_size = 32  # 假设的默认单元格大小
		
		# 优化：设定检查范围，避免检查所有水域标记
		for marker in obstacle_data.get_children():
			if marker.has_meta("is_water") and marker.get_meta("is_water"):
				# 先做一个粗略的距离检查，减少精确计算次数
				if abs(marker.global_position.x - position.x) < cell_size and abs(marker.global_position.y - position.y) < cell_size:
					# 如果水域标记靠近要生成的位置
					if marker.global_position.distance_to(position) < cell_size:
						return true
	
	# 方法2：通过TileMap直接检查地形类型
	if tilemap != null:
		# 将世界坐标转换为TileMap坐标
		var map_pos = tilemap.local_to_map(tilemap.to_local(position))
		
		# 检查TileMap的单元格属性
		var tile_data = tilemap.get_cell_tile_data(0, map_pos)
		if tile_data != null:
			# 检查是否是水域地形（TerrainType.WATER = 2）
			if tile_data.get_terrain_set() == 0 and tile_data.get_terrain() == 2:
				return true
				
			# 尝试另一种方式检查水域
			# 有些TileMap可能使用自定义属性标记水域
			if tile_data.has_custom_data("is_water") and tile_data.get_custom_data("is_water"):
				return true
				
		# 另外，检查是否有水域碰撞体
		var water_body = tilemap.get_node_or_null("WaterCollision")
		if water_body != null:
			for collision in water_body.get_children():
				if collision is CollisionShape2D:
					var shape = collision.shape
					if shape is RectangleShape2D:
						var rect = Rect2(collision.global_position - shape.size/2, shape.size)
						if rect.has_point(position):
							return true
	
	# 方法3：使用FlowField中的障碍物信息 - 这是备用方法
	if flow_field != null:
		var grid_pos = flow_field.world_to_grid(position)
		if flow_field.is_valid_cell(grid_pos):
			# 检查该单元格的成本是否很高（障碍物成本）
			if flow_field.cost_field[grid_pos.x][grid_pos.y] >= flow_field.obstacle_cost * 0.9:
				# 注意：这种方法可能会将所有障碍物都视为水，不太准确，但作为备用方法可以接受
				return true
	
	# 默认情况：假设不在水中
	return false
