extends Node

# 用于修复TileMap层级Z索引的问题

func _ready():
	# 延迟一帧执行，确保场景已完全加载
	call_deferred("fix_tilemap_layers")

func fix_tilemap_layers():
	print("\n=== 修复TileMap层级Z索引 ===\n")
	
	# 查找TileMap
	var tilemaps = find_all_tilemaps(get_tree().root)
	if tilemaps.size() == 0:
		print("未找到TileMap节点")
		return
	
	# 修复每个TileMap的层级索引
	for tilemap in tilemaps:
		print("修复TileMap: " + tilemap.name)
		
		# 输出当前设置
		print("调整前:")
		for i in range(tilemap.get_layers_count()):
			print("  - 层 " + str(i) + ": z_index = " + str(tilemap.get_layer_z_index(i)) + 
				", y_sort = " + str(tilemap.get_layer_y_sort_enabled(i)))
		
		# 修改层级Z索引
		# 地形层(通常是Layer 0)设置为较低的Z索引
		tilemap.set_layer_z_index(0, -10)
		
		# 确保地形层启用Y排序
		tilemap.set_layer_y_sort_enabled(0, true)
		
		# 如果有树木层(通常是Layer 1)，设置合适的Z索引
		if tilemap.get_layers_count() > 1:
			tilemap.set_layer_z_index(1, 0)
			tilemap.set_layer_y_sort_enabled(1, true)
		
		# 输出调整后的设置
		print("调整后:")
		for i in range(tilemap.get_layers_count()):
			print("  - 层 " + str(i) + ": z_index = " + str(tilemap.get_layer_z_index(i)) + 
				", y_sort = " + str(tilemap.get_layer_y_sort_enabled(i)))
		
		# 确保TileMap本身的Y排序已启用
		tilemap.y_sort_enabled = true
		
		print("TileMap层级Z索引修复完成")

func find_all_tilemaps(node):
	var tilemaps = []
	if node is TileMap:
		tilemaps.append(node)
	
	for child in node.get_children():
		tilemaps.append_array(find_all_tilemaps(child))
	
	return tilemaps 