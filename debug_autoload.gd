extends Node

func _ready():
	# 等待一帧，确保场景加载完毕
	await get_tree().process_frame
	
	print("\n=====================")
	print("= 启动Z顺序调试工具 =")
	print("=====================\n")
	
	# 搜索并打印TileMap信息
	var tilemaps = find_all_tilemaps(get_tree().root)
	print("\n=== TileMap节点信息 ===\n")
	for tilemap in tilemaps:
		print("TileMap: " + tilemap.name)
		print("  - Path: " + str(get_node_path(tilemap)))
		print("  - y_sort_enabled: " + str(tilemap.y_sort_enabled))
		print("  - z_index: " + str(tilemap.z_index))
		print("  - z_as_relative: " + str(tilemap.z_as_relative))
		print("  - 层数量: " + str(tilemap.get_layers_count()))
		
		for i in range(tilemap.get_layers_count()):
			print("  - 层 " + str(i) + ":")
			print("    - y_sort_enabled: " + str(tilemap.get_layer_y_sort_enabled(i)))
			print("    - z_index: " + str(tilemap.get_layer_z_index(i)))
	
	# 打印玩家信息
	var players = get_tree().get_nodes_in_group("player")
	print("\n=== 玩家节点信息 ===\n")
	for player in players:
		print("玩家: " + player.name)
		print("  - Path: " + str(get_node_path(player)))
		print("  - y_sort_enabled: " + str(player.y_sort_enabled if "y_sort_enabled" in player else "N/A"))
		print("  - z_index: " + str(player.z_index))
		print("  - z_as_relative: " + str(player.z_as_relative))
		
		# 获取玩家的父节点，检查它是否启用了y_sort
		var parent = player.get_parent()
		if parent:
			print("  - 父节点: " + parent.name)
			print("    - y_sort_enabled: " + str(parent.y_sort_enabled if "y_sort_enabled" in parent else "N/A"))
			print("    - z_index: " + str(parent.z_index))
	
	# 打印敌人信息
	var enemies = get_tree().get_nodes_in_group("enemy") if get_tree().has_group("enemy") else []
	if enemies.size() > 0:
		print("\n=== 敌人节点信息 ===\n")
		for enemy in enemies:
			print("敌人: " + enemy.name)
			print("  - Path: " + str(get_node_path(enemy)))
			print("  - y_sort_enabled: " + str(enemy.y_sort_enabled if "y_sort_enabled" in enemy else "N/A"))
			print("  - z_index: " + str(enemy.z_index))
			print("  - z_as_relative: " + str(enemy.z_as_relative))
	
	# 打印所有树对象的信息
	print_tree_objects_info(tilemaps)

# 查找所有TileMap节点
func find_all_tilemaps(node):
	var tilemaps = []
	if node is TileMap:
		tilemaps.append(node)
	
	for child in node.get_children():
		tilemaps.append_array(find_all_tilemaps(child))
	
	return tilemaps

# 获取节点的完整路径
func get_node_path(node):
	var path = node.name
	var parent = node.get_parent()
	
	while parent and parent != get_tree().root:
		path = parent.name + "/" + path
		parent = parent.get_parent()
	
	return "/" + path

# 打印树对象信息
func print_tree_objects_info(tilemaps):
	print("\n=== 树对象信息 ===\n")
	
	for tilemap in tilemaps:
		if tilemap.get_layers_count() > 1: # 至少有两层，假设第二层是树层
			print("TileMap: " + tilemap.name)
			print("  - 树所在层 (通常是Layer 1):")
			print("    - y_sort_enabled: " + str(tilemap.get_layer_y_sort_enabled(1)))
			print("    - z_index: " + str(tilemap.get_layer_z_index(1)))
			
			# 尝试获取树对象的信息
			var used_cells = tilemap.get_used_cells(1) # 获取第二层的所有使用的单元格
			if used_cells.size() > 0:
				print("  - 树对象数量: " + str(used_cells.size()))
				print("  - 示例树对象坐标: " + str(used_cells[0]))
				
				var cell_position = used_cells[0]
				var atlas_coords = tilemap.get_cell_atlas_coords(1, cell_position)
				print("    - Atlas坐标: " + str(atlas_coords))
			else:
				print("  - 未找到树对象") 