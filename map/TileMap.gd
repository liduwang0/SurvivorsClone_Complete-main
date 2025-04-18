extends TileMap

var myNoise = FastNoiseLite.new()
var myNoise2 = FastNoiseLite.new()
var myNoise3 = FastNoiseLite.new()
var treeNoise = FastNoiseLite.new()

# 固定地图大小
var map_width = 40
var map_height = 40

# 地形生成阈值控制
var water_threshold = -0.7  # 值越低，水越少
var path_threshold = 0.3    # 值越低，路越多
var tree_density = 0.06     # 树木密度控制（0-1之间，值越低树越少）

# 定义不同的地形类型
enum TerrainType {
	PATH = 0,  # 土路
	GRASS = 1, # 草地
	WATER = 2  # 水域
}

# 定义层
const TERRAIN_LAYER = 0  # 地形层
const TREE_LAYER = 1     # 树木层

# 定义树木组合（每个组合是一棵完整的树）
var tree_sets = [
	
		# 树6 小松树
	{
		"pieces": [
			{"offset": Vector2i(0, 0), "source_id": 5, "coords": Vector2i(16, 15)},  # 上部
			{"offset": Vector2i(0, 1), "source_id": 5, "coords": Vector2i(16, 16)}   # 下部
		]
	},
			# 树7 恐怖树
	{
		"pieces": [
			{"offset": Vector2i(0, 0), "source_id": 5, "coords": Vector2i(9, 17)},  # 上部
			{"offset": Vector2i(0, 1), "source_id": 5, "coords": Vector2i(9, 18)}   # 下部
		]
	},
		# 树8 枯树
	{
		"pieces": [
			{"offset": Vector2i(0, 0), "source_id": 5, "coords": Vector2i(10, 17)},  # 上部
			{"offset": Vector2i(0, 1), "source_id": 5, "coords": Vector2i(10, 18)}   # 下部
		]
	},
	
		# 树9 大白桦树
	{
		"pieces": [
			{"offset": Vector2i(0, 0), "source_id": 5, "coords": Vector2i(11, 17)},  # 上部
			{"offset": Vector2i(1, 0), "source_id": 5, "coords": Vector2i(12, 17)},   # 下部
			{"offset": Vector2i(0, 1), "source_id": 5, "coords": Vector2i(11, 18)},  # 上部
			{"offset": Vector2i(1, 1), "source_id": 5, "coords": Vector2i(12, 18)}   # 下部
		]
	},
		# 树4 大园树
	{
		"pieces": [
			{"offset": Vector2i(0, 0), "source_id": 5, "coords": Vector2i(12, 15)},  # 上部
			{"offset": Vector2i(1, 0), "source_id": 5, "coords": Vector2i(13, 15)},   # 下部
			{"offset": Vector2i(0, 1), "source_id": 5, "coords": Vector2i(12, 16)},  # 上部
			{"offset": Vector2i(1, 1), "source_id": 5, "coords": Vector2i(13, 16)}   # 下部
		]
	},	
		# 树10 大松树
	{
		"pieces": [
			{"offset": Vector2i(0, 0), "source_id": 5, "coords": Vector2i(13, 17)},  # 上部
			{"offset": Vector2i(1, 0), "source_id": 5, "coords": Vector2i(14, 17)},   # 下部
			{"offset": Vector2i(0, 1), "source_id": 5, "coords": Vector2i(13, 18)},  # 上部
			{"offset": Vector2i(1, 1), "source_id": 5, "coords": Vector2i(14, 18)}   # 下部
		]
	},
			# 树11 大白桦树 深色
	{
		"pieces": [
			{"offset": Vector2i(0, 0), "source_id": 5, "coords": Vector2i(15, 17)},  # 上部
			{"offset": Vector2i(1, 0), "source_id": 5, "coords": Vector2i(16, 17)},   # 下部
			{"offset": Vector2i(0, 1), "source_id": 5, "coords": Vector2i(15, 18)},  # 上部
			{"offset": Vector2i(1, 1), "source_id": 5, "coords": Vector2i(16, 18)}   # 下部
		]
	},
	# 大石头 水平2格
	{
		"pieces": [
			{"offset": Vector2i(0, 0), "source_id": 5, "coords": Vector2i(8, 21)},  # 上部
			{"offset": Vector2i(1, 0), "source_id": 5, "coords": Vector2i(9, 21)}   # 下部
		]
	},
	## 石头5
	#{
		#"pieces": [
			#{"offset": Vector2i(0, 0), "source_id": 5, "coords": Vector2i(6, 21)}
		#]
	#},
	{
		#石头4
		"pieces": [
			{"offset": Vector2i(0, 0), "source_id": 5, "coords": Vector2i(9, 20)}  # 上左部
			
		]
	},
	{
		#蘑菇3
		"pieces": [
			{"offset": Vector2i(0, 0), "source_id": 5, "coords": Vector2i(8, 19)}  # 上左部
			
		]
	},
	{
		#蘑菇8
		"pieces": [
			{"offset": Vector2i(0, 0), "source_id": 5, "coords": Vector2i(13, 19)}  # 上左部
			
		]
	},
	{
		#蘑菇6
		"pieces": [
			{"offset": Vector2i(0, 0), "source_id": 5, "coords": Vector2i(11, 19)}  # 上左部
			
		]
	},
			
	{
		#石头6
		"pieces": [
			{"offset": Vector2i(0, 0), "source_id": 5, "coords": Vector2i(7, 21)}  # 上左部
			
		]
	},

	{
		#石头9
		"pieces": [
			{"offset": Vector2i(0, 0), "source_id": 5, "coords": Vector2i(11, 21)}  # 上左部
			
		]
	},
	# 小树3（竖直两格）
	{
		"pieces": [
			{"offset": Vector2i(0, 0), "source_id": 5, "coords": Vector2i(3, 24)},  # 上部
			{"offset": Vector2i(1, 0), "source_id": 5, "coords": Vector2i(4, 24)},  # 上部
			{"offset": Vector2i(2, 0), "source_id": 5, "coords": Vector2i(5, 24)},  # 上部
			{"offset": Vector2i(3, 0), "source_id": 5, "coords": Vector2i(6, 24)},  # 上部
			{"offset": Vector2i(0, 1), "source_id": 5, "coords": Vector2i(3, 25)},  # 上部
			{"offset": Vector2i(3, 1), "source_id": 5, "coords": Vector2i(6, 25)},  # 上部
			{"offset": Vector2i(0, 2), "source_id": 5, "coords": Vector2i(3, 26)},  # 上部
			{"offset": Vector2i(1, 2), "source_id": 5, "coords": Vector2i(4, 26)},  # 上部
			{"offset": Vector2i(2, 2), "source_id": 5, "coords": Vector2i(5, 26)},  # 上部
			{"offset": Vector2i(3, 2), "source_id": 5, "coords": Vector2i(6, 26)}   # 下部
		]
	}
	# 可以添加更多树木组合
]

@export var debug_draw_obstacles: bool = false  # 是否绘制障碍物调试标记
@export var debug_marker_size: float = 16.0  # 调试标记的大小

func _ready():
	# 设置噪声参数
	myNoise.seed = randi()
	myNoise2.seed = randi() + 100
	myNoise3.seed = randi() + 200
	treeNoise.seed = randi() + 300
	
	# 设置更平滑的噪声参数
	myNoise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	myNoise.frequency = 0.05
	myNoise.fractal_type = FastNoiseLite.FRACTAL_FBM
	myNoise.fractal_octaves = 10
	myNoise.fractal_lacunarity = 2.0
	myNoise.fractal_gain = 0.2
	
	# 设置树木噪声参数
	treeNoise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	treeNoise.frequency = 0.1
	treeNoise.fractal_type = FastNoiseLite.FRACTAL_FBM
	treeNoise.fractal_octaves = 4
	treeNoise.fractal_lacunarity = 2.0
	treeNoise.fractal_gain = 0.5
	
	# 启用YSort以确保树木正确显示在地形之上
	y_sort_enabled = true
	
	# 设置层级的Z索引
	set_layer_z_index(TERRAIN_LAYER, -10)  # 地形层Z索引设为-10
	set_layer_y_sort_enabled(TERRAIN_LAYER, true)  # 地形层启用Y排序
	
	set_layer_z_index(TREE_LAYER, 0)  # 树木层Z索引设为0
	set_layer_y_sort_enabled(TREE_LAYER, true)  # 树木层启用Y排序
	
	# 生成地图
	generate_map()

# 生成地图
func generate_map():
	# 清除所有瓦片
	clear()
	
	# 地图中心点
	var center_x = -map_width / 2
	var center_y = -map_height / 2
	
	# 收集不同地形的单元格
	var water_cells = []
	var grass_cells = []
	var path_cells = []
	
	# 基于噪声为每个位置分配地形
	for x in range(center_x, center_x + map_width):
		for y in range(center_y, center_y + map_height):
			var pos = Vector2i(x, y)
			var noise_val = myNoise.get_noise_2d(float(x), float(y))
			
			# 使用阈值变量来控制地形生成比例
			if noise_val < water_threshold:
				water_cells.append(pos)
			elif noise_val > path_threshold:
				path_cells.append(pos)
			else:
				grass_cells.append(pos)
	
	# 放置地形
	if water_cells.size() > 0:
		set_cells_terrain_connect(TERRAIN_LAYER, water_cells, 0, TerrainType.WATER)
	if path_cells.size() > 0:
		set_cells_terrain_connect(TERRAIN_LAYER, path_cells, 0, TerrainType.PATH)
	if grass_cells.size() > 0:
		set_cells_terrain_connect(TERRAIN_LAYER, grass_cells, 0, TerrainType.GRASS)
	
	print("准备放置树木，共有草地格子: ", grass_cells.size())
	
	# 在草地上生成树木
	place_tree_sets(grass_cells)
	
	# 检查并填充黑块
	fill_black_cells()
	
	# 为水域添加碰撞
	add_water_collision()
	
	# 创建一个节点来存储障碍物信息
	if has_node("ObstacleData"):
		remove_child(get_node("ObstacleData"))
		
	var obstacle_data = Node2D.new()
	obstacle_data.name = "ObstacleData"
	add_child(obstacle_data)
	
	# 为每棵树创建一个标记
	for x in range(center_x, center_x + map_width):
		for y in range(center_y, center_y + map_height):
			var pos = Vector2i(x, y)
			
			# 检查TREE_LAYER是否有瓦片
			var source_id = get_cell_source_id(TREE_LAYER, pos)
			if source_id >= 0:
				var atlas_coords = get_cell_atlas_coords(TREE_LAYER, pos)
				
				# 检查是否是树木或障碍物
				var is_obstacle = false
				
				# 1. 检查瓦片坐标是否匹配已知的树木类型
				for tree_set in tree_sets:
					for piece in tree_set.pieces:
						if source_id == piece.source_id and atlas_coords == piece.coords:
							is_obstacle = true
							break
					if is_obstacle:
						break
				
				# 2. 或者检查瓦片是否有碰撞数据
				var tile_data = get_cell_tile_data(TREE_LAYER, pos)
				if tile_data != null and tile_data.get_collision_polygons_count(0) > 0:
					is_obstacle = true
				
				if is_obstacle:
					# 创建一个标记
					var marker = Node2D.new()
					marker.position = map_to_local(pos)
					marker.name = "Obstacle_" + str(pos.x) + "_" + str(pos.y)
					
					# 添加自定义属性
					marker.set_meta("is_obstacle", true)
					marker.set_meta("tile_pos", pos)
					
					obstacle_data.add_child(marker)
	
	# 将水域也标记为障碍
	for water_cell in water_cells:
		# 创建一个标记
		var marker = Node2D.new()
		marker.position = map_to_local(water_cell)
		marker.name = "Water_" + str(water_cell.x) + "_" + str(water_cell.y)
		
		# 添加自定义属性
		marker.set_meta("is_obstacle", true)
		marker.set_meta("tile_pos", water_cell)
		marker.set_meta("is_water", true)
		
		obstacle_data.add_child(marker)
	
	# 如果开启了调试绘制，为每个障碍物标记添加可视指示器
	if debug_draw_obstacles:
		add_debug_visuals_to_obstacles(obstacle_data)
	
	print("完成障碍物标记，共创建了 ", obstacle_data.get_child_count(), " 个标记")

# 放置树木组合
func place_tree_sets(grass_cells):
	var available_cells = grass_cells.duplicate()
	var trees_placed = 0
	
	for pos in grass_cells:
		if randf() > (1.0 - tree_density) and pos in available_cells:  # 使用tree_density控制概率
			# 随机选择一种树木组合
			var tree_set = tree_sets[randi() % tree_sets.size()]
			
			# 检查是否有足够的空间放置整个树
			var can_place = true
			for piece in tree_set.pieces:
				var check_pos = pos + piece.offset
				if not check_pos in available_cells:
					can_place = false
					break
			
			if can_place:
				# 放置整棵树的所有部分
				for piece in tree_set.pieces:
					var place_pos = pos + piece.offset
					set_cell(TREE_LAYER, place_pos, piece.source_id, piece.coords)
					available_cells.erase(place_pos)
				
				trees_placed += 1
	
	print("共放置了 ", trees_placed, " 棵树")

# 填充黑块位置为草地瓦片
func fill_black_cells():
	var black_cells = []
	var center_x = -map_width / 2
	var center_y = -map_height / 2
	
	# 查找所有黑块位置
	for x in range(center_x, center_x + map_width):
		for y in range(center_y, center_y + map_height):
			var pos = Vector2i(x, y)
			if get_cell_source_id(0, pos) == -1:  # -1表示没有瓦片
				black_cells.append(pos)
	
	# 如果有黑块，用草地瓦片填充
	if black_cells.size() > 0:
		# 获取第一个源（通常是我们的瓦片集）
		var source_id = tile_set.get_source_id(0)
		
		# 使用草地的中心瓦片（通常是完整的草地瓦片）
		var grass_coords = Vector2i(3, 1)  # 假设这是草地瓦片的坐标
		
		# 直接设置瓦片
		for pos in black_cells:
			set_cell(0, pos, source_id, grass_coords)
	else:
		print("没有发现黑块")

# 为水域添加碰撞
func add_water_collision():
	var water_body = StaticBody2D.new()
	water_body.name = "WaterCollision"
	add_child(water_body)
	
	for pos in get_used_cells(0):
		var tile_data = get_cell_tile_data(0, pos)
		if tile_data != null and tile_data.get_terrain_set() == 0 and tile_data.get_terrain() == TerrainType.WATER:
			var collision = CollisionShape2D.new()
			var shape = RectangleShape2D.new()
			shape.size = tile_set.tile_size
			collision.shape = shape
			collision.position = map_to_local(pos)
			water_body.add_child(collision)

# 重新生成地图
func regenerate_map():
	myNoise.seed = randi()
	myNoise2.seed = randi() + 100
	myNoise3.seed = randi() + 200
	generate_map()

# 添加障碍物的可视化调试标记
func add_debug_visuals_to_obstacles(obstacle_data):
	for marker in obstacle_data.get_children():
		if marker.has_meta("is_obstacle"):
			var visual = Sprite2D.new()
			
			# 根据障碍物类型选择不同的颜色
			if marker.has_meta("is_water") and marker.get_meta("is_water"):
				# 水域显示为蓝色半透明矩形
				var rect = ColorRect.new()
				rect.color = Color(0, 0, 1, 0.3)  # 蓝色半透明
				rect.size = Vector2(debug_marker_size, debug_marker_size)
				rect.position = Vector2(-debug_marker_size/2, -debug_marker_size/2)
				marker.add_child(rect)
			else:
				# 树木和其他障碍物显示为红色圆形
				var circle = Node2D.new()
				circle.z_index = 100  # 确保绘制在最上层
				marker.add_child(circle)
				
				# 添加自定义绘制函数
				circle.set_script(GDScript.new())
				circle.script.source_code = """
extends Node2D

func _draw():
	draw_circle(Vector2.ZERO, %s, Color(1, 0, 0, 0.5))
	draw_arc(Vector2.ZERO, %s, 0, TAU, 32, Color(1, 0, 0, 0.8), 2)
""" % [debug_marker_size * 0.4, debug_marker_size * 0.4]
				circle.script.reload()  # 重新加载脚本

# 重写_draw函数以在编辑器中显示障碍物
func _draw():
	if debug_draw_obstacles and has_node("ObstacleData"):
		for marker in get_node("ObstacleData").get_children():
			if marker.has_meta("is_obstacle"):
				var pos = marker.position
				
				# 根据障碍物类型绘制不同形状
				if marker.has_meta("is_water") and marker.get_meta("is_water"):
					# 水域为蓝色方形
					var rect_size = Vector2(debug_marker_size, debug_marker_size)
					draw_rect(Rect2(pos - rect_size/2, rect_size), Color(0, 0, 1, 0.3), true)
				else:
					# 其他障碍物为红色圆形
					draw_circle(pos, debug_marker_size * 0.4, Color(1, 0, 0, 0.5))
					draw_arc(pos, debug_marker_size * 0.4, 0, TAU, 32, Color(1, 0, 0, 0.8), 2)

# 确保在编辑器中也能看到绘制
func _process(delta):
	if debug_draw_obstacles:
		queue_redraw()  # 持续触发重绘
