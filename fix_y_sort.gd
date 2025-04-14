extends Node

# 此脚本用于修复TileMap和Player之间的Y排序问题
# 可以附加到Main节点上，或者从其他脚本调用

func fix_y_sort_issues():
	print("\n====================")
	print("= 修复Y排序问题工具 =")
	print("====================\n")
	
	# 1. 找到所有TileMap
	var tilemaps = find_all_tilemaps(get_tree().root)
	
	# 2. 找到所有Player
	var players = get_tree().get_nodes_in_group("player")
	
	if tilemaps.size() == 0:
		print("未找到TileMap节点")
		return
	
	if players.size() == 0:
		print("未找到Player节点")
		return
	
	# 3. 修复排序问题
	print("开始修复Y排序问题...")
	
	# 检查玩家和TileMap的关系
	var player = players[0]
	var tilemap = tilemaps[0]
	
	# 检查玩家是否是TileMap的子节点，如果是，则需要调整结构
	if is_player_child_of_tilemap(player, tilemap):
		print("发现问题: 玩家是TileMap的子节点，这会导致Y排序问题")
		fix_node_hierarchy(player, tilemap)
	
	# 确保所有相关的节点启用了Y-Sort
	ensure_y_sort_enabled(player, tilemap)
	
	# 将玩家的Z-Index设置为比TileMap的树层高
	fix_z_index(player, tilemap)
	
	print("Y排序问题修复完成")

func is_player_child_of_tilemap(player, tilemap):
	var parent = player.get_parent()
	while parent:
		if parent == tilemap:
			return true
		parent = parent.get_parent()
	return false

func fix_node_hierarchy(player, tilemap):
	print("修复节点层次结构...")
	
	# 获取TileMap的父节点
	var tilemap_parent = tilemap.get_parent()
	
	# 如果TileMap的父节点不支持Y排序，则添加一个Y排序节点
	if not "y_sort_enabled" in tilemap_parent or not tilemap_parent.y_sort_enabled:
		print("TileMap的父节点不支持Y排序，需要创建新的Y排序节点")
		
		# 创建新的Y排序节点
		var y_sort_node = Node2D.new()
		y_sort_node.name = "YSortContainer"
		y_sort_node.y_sort_enabled = true
		
		# 获取TileMap和player的当前位置
		var tilemap_pos = tilemap.global_position
		var player_pos = player.global_position
		
		# 添加新节点到场景
		tilemap_parent.add_child(y_sort_node)
		
		# 移除并重新添加TileMap和Player
		tilemap.get_parent().remove_child(tilemap)
		player.get_parent().remove_child(player)
		
		y_sort_node.add_child(tilemap)
		y_sort_node.add_child(player)
		
		# 恢复位置
		tilemap.global_position = tilemap_pos
		player.global_position = player_pos
		
		print("已创建Y排序节点并重新组织节点层次")
	else:
		# 如果TileMap的父节点支持Y排序，直接移动Player
		print("TileMap的父节点支持Y排序，直接移动Player")
		
		var player_pos = player.global_position
		player.get_parent().remove_child(player)
		tilemap_parent.add_child(player)
		player.global_position = player_pos
		
		print("已将Player移到正确的层次")

func ensure_y_sort_enabled(player, tilemap):
	print("确保Y排序已启用...")
	
	# 确保TileMap启用Y排序
	tilemap.y_sort_enabled = true
	
	# 确保TileMap的所有层启用Y排序
	for i in range(tilemap.get_layers_count()):
		tilemap.set_layer_y_sort_enabled(i, true)
	
	# 确保Player的父节点启用Y排序
	var player_parent = player.get_parent()
	if "y_sort_enabled" in player_parent:
		player_parent.y_sort_enabled = true
	
	# 如果Player支持Y排序，也启用它
	if "y_sort_enabled" in player:
		player.y_sort_enabled = true
	
	print("已确保所有节点启用Y排序")

func fix_z_index(player, tilemap):
	print("修复Z索引...")
	
	# 确保地形层Z索引较低
	tilemap.set_layer_z_index(0, -10)
	
	# 确保树木层Z索引适中
	if tilemap.get_layers_count() > 1:
		tilemap.set_layer_z_index(1, 0)
	
	# 设置Player的Z索引比树木层高，但使用相对模式
	player.z_index = 10
	player.z_as_relative = true
	
	print("已调整Z索引")

func find_all_tilemaps(node):
	var tilemaps = []
	if node is TileMap:
		tilemaps.append(node)
	
	for child in node.get_children():
		tilemaps.append_array(find_all_tilemaps(child))
	
	return tilemaps 