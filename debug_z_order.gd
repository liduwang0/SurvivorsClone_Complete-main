extends Node

func _ready():
	# 延迟一帧以确保所有节点都已准备好
	call_deferred("debug_scene_hierarchy")

func debug_scene_hierarchy():
	var root = get_tree().get_root()
	print("\n=== 场景节点层次和排序配置 ===\n")
	print_node_info(root, 0)
	
	# 特别输出TileMap的层信息
	print("\n=== TileMap层配置 ===\n")
	var tilemaps = get_tree().get_nodes_in_group("tilemap") if get_tree().has_group("tilemap") else []
	if tilemaps.size() == 0:
		tilemaps = find_all_tilemaps(root)
	
	for tilemap in tilemaps:
		print("TileMap: " + tilemap.name)
		print("  - y_sort_enabled: " + str(tilemap.y_sort_enabled))
		print("  - z_index: " + str(tilemap.z_index))
		print("  - z_as_relative: " + str(tilemap.z_as_relative))
		print("  - 层数量: " + str(tilemap.get_layers_count()))
		
		for i in range(tilemap.get_layers_count()):
			print("  - 层 " + str(i) + ":")
			print("    - y_sort_enabled: " + str(tilemap.get_layer_y_sort_enabled(i)))
			print("    - z_index: " + str(tilemap.get_layer_z_index(i)))
	
	# 输出玩家信息
	print("\n=== 玩家节点配置 ===\n")
	var players = get_tree().get_nodes_in_group("player")
	for player in players:
		print("玩家: " + player.name)
		print("  - global_position: " + str(player.global_position))
		print("  - y_sort_enabled: " + str(player.y_sort_enabled if has_property(player, "y_sort_enabled") else "N/A"))
		print("  - z_index: " + str(player.z_index))
		print("  - z_as_relative: " + str(player.z_as_relative))
	
	# 输出敌人信息
	print("\n=== 敌人节点配置 ===\n")
	var enemies = get_tree().get_nodes_in_group("enemy") if get_tree().has_group("enemy") else []
	for enemy in enemies:
		print("敌人: " + enemy.name)
		print("  - global_position: " + str(enemy.global_position))
		print("  - y_sort_enabled: " + str(enemy.y_sort_enabled if has_property(enemy, "y_sort_enabled") else "N/A"))
		print("  - z_index: " + str(enemy.z_index))
		print("  - z_as_relative: " + str(enemy.z_as_relative))

# 辅助函数，打印节点信息
func print_node_info(node, indent_level):
	var indent = ""
	for i in range(indent_level):
		indent += "  "
	
	print(indent + node.name + " (" + node.get_class() + ")")
	print(indent + "  - y_sort_enabled: " + str(node.y_sort_enabled if has_property(node, "y_sort_enabled") else "N/A"))
	print(indent + "  - z_index: " + str(node.z_index))
	print(indent + "  - z_as_relative: " + str(node.z_as_relative))
	
	for child in node.get_children():
		print_node_info(child, indent_level + 1)

# 查找所有TileMap节点
func find_all_tilemaps(node):
	var tilemaps = []
	if node is TileMap:
		tilemaps.append(node)
	
	for child in node.get_children():
		tilemaps.append_array(find_all_tilemaps(child))
	
	return tilemaps

# 检查节点是否有指定属性
func has_property(node, property):
	return property in node 