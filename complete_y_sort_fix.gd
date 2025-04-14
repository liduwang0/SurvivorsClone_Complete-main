extends Node

# 这是一个一站式解决方案，修复TileMap和Player之间的排序问题

func _ready():
	# 延迟一帧执行，确保场景已完全加载
	call_deferred("fix_all_sorting_issues")

func _input(event):
	if event.is_action_pressed("ui_accept"):  # 按空格键重新应用修复
		fix_all_sorting_issues()
		print("重新应用排序修复")

func fix_all_sorting_issues():
	print("\n============================")
	print("= 全面排序问题修复工具启动 =")
	print("============================\n")
	
	# 查找所有需要处理的节点
	var tilemaps = find_all_tilemaps(get_tree().root)
	var players = get_tree().get_nodes_in_group("player")
	var enemies = get_tree().get_nodes_in_group("enemy") if get_tree().has_group("enemy") else []
	
	if tilemaps.size() == 0:
		print("错误: 未找到TileMap节点")
		return
	
	if players.size() == 0:
		print("警告: 未找到Player节点")
	
	# 1. 修复TileMap层级z_index
	fix_tilemap_layers(tilemaps)
	
	# 2. 修复角色z_index
	fix_character_z_index(players, enemies)
	
	# 3. 确保节点层次结构正确
	fix_node_hierarchy(tilemaps, players, enemies)
	
	# 4. 确保所有相关节点都已启用Y排序
	ensure_y_sort_enabled(tilemaps, players, enemies)
	
	print("\n所有排序问题修复完成！请测试效果\n")

func fix_tilemap_layers(tilemaps):
	print("\n--- 修复TileMap层级Z索引 ---\n")
	
	for tilemap in tilemaps:
		print("处理TileMap: " + tilemap.name)
		
		# 输出当前设置
		print("  调整前:")
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
		print("  调整后:")
		for i in range(tilemap.get_layers_count()):
			print("  - 层 " + str(i) + ": z_index = " + str(tilemap.get_layer_z_index(i)) + 
				", y_sort = " + str(tilemap.get_layer_y_sort_enabled(i)))
		
		# 确保TileMap本身的Y排序已启用
		tilemap.y_sort_enabled = true

func fix_character_z_index(players, enemies):
	print("\n--- 修复角色Z索引 ---\n")
	
	# 设置玩家的Z索引
	for player in players:
		print("处理玩家: " + player.name)
		print("  原z_index: " + str(player.z_index))
		
		# 将玩家的Z索引设置为比树木层高
		player.z_index = 10
		player.z_as_relative = true
		
		print("  新z_index: " + str(player.z_index))
	
	# 设置敌人的Z索引
	for enemy in enemies:
		print("处理敌人: " + enemy.name)
		print("  原z_index: " + str(enemy.z_index))
		
		# 将敌人的Z索引设置为比树木层高
		enemy.z_index = 10
		enemy.z_as_relative = true
		
		print("  新z_index: " + str(enemy.z_index))

func fix_node_hierarchy(tilemaps, players, enemies):
	print("\n--- 修复节点层次结构 ---\n")
	
	# 取第一个TileMap作为参考
	var tilemap = tilemaps[0]
	var tilemap_parent = tilemap.get_parent()
	
	# 检查TileMap的父节点是否支持Y排序
	if not "y_sort_enabled" in tilemap_parent or not tilemap_parent.y_sort_enabled:
		print("TileMap的父节点不支持Y排序，创建Y排序容器")
		
		# 创建Y排序容器
		var y_sort_node = Node2D.new()
		y_sort_node.name = "YSortContainer"
		y_sort_node.y_sort_enabled = true
		
		# 获取当前位置
		var tilemap_pos = tilemap.global_position
		
		# 添加容器到场景
		tilemap_parent.add_child(y_sort_node)
		
		# 移动TileMap到容器
		tilemap.get_parent().remove_child(tilemap)
		y_sort_node.add_child(tilemap)
		tilemap.global_position = tilemap_pos
		
		# 更新tilemap_parent引用
		tilemap_parent = y_sort_node
		
		print("已创建Y排序容器并移动TileMap")
	
	# 检查并修复玩家节点的层次结构
	for player in players:
		if is_node_child_of(player, tilemap):
			print("发现问题: 玩家是TileMap的子节点")
			
			# 获取当前位置
			var player_pos = player.global_position
			
			# 移动玩家到正确的父节点
			player.get_parent().remove_child(player)
			tilemap_parent.add_child(player)
			player.global_position = player_pos
			
			print("已将玩家移动到正确的层次")
	
	# 检查并修复敌人节点的层次结构
	for enemy in enemies:
		if is_node_child_of(enemy, tilemap):
			print("发现问题: 敌人是TileMap的子节点")
			
			# 获取当前位置
			var enemy_pos = enemy.global_position
			
			# 移动敌人到正确的父节点
			enemy.get_parent().remove_child(enemy)
			tilemap_parent.add_child(enemy)
			enemy.global_position = enemy_pos
			
			print("已将敌人移动到正确的层次")

func ensure_y_sort_enabled(tilemaps, players, enemies):
	print("\n--- 确保Y排序已启用 ---\n")
	
	# 确保TileMap启用Y排序
	for tilemap in tilemaps:
		print("确保TileMap启用Y排序: " + tilemap.name)
		
		tilemap.y_sort_enabled = true
		
		# 确保TileMap的父节点启用Y排序
		var parent = tilemap.get_parent()
		if "y_sort_enabled" in parent:
			parent.y_sort_enabled = true
			print("  TileMap父节点(" + parent.name + ")已启用Y排序")
	
	# 确保玩家启用Y排序
	for player in players:
		print("确保玩家启用Y排序: " + player.name)
		
		if "y_sort_enabled" in player:
			player.y_sort_enabled = true
			print("  玩家已启用Y排序")
		
		# 确保玩家的父节点启用Y排序
		var parent = player.get_parent()
		if "y_sort_enabled" in parent:
			parent.y_sort_enabled = true
			print("  玩家父节点(" + parent.name + ")已启用Y排序")
	
	# 确保敌人启用Y排序
	for enemy in enemies:
		print("确保敌人启用Y排序: " + enemy.name)
		
		if "y_sort_enabled" in enemy:
			enemy.y_sort_enabled = true
			print("  敌人已启用Y排序")
		
		# 确保敌人的父节点启用Y排序
		var parent = enemy.get_parent()
		if "y_sort_enabled" in parent:
			parent.y_sort_enabled = true
			print("  敌人父节点(" + parent.name + ")已启用Y排序")

func find_all_tilemaps(node):
	var tilemaps = []
	if node is TileMap:
		tilemaps.append(node)
	
	for child in node.get_children():
		tilemaps.append_array(find_all_tilemaps(child))
	
	return tilemaps

func is_node_child_of(node, potential_parent):
	var parent = node.get_parent()
	while parent:
		if parent == potential_parent:
			return true
		parent = parent.get_parent()
	return false 