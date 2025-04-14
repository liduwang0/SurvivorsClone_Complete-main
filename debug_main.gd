extends Node

# 这个脚本可以附加到你的主场景或者作为自动加载脚本

var debug_mode = true
var fix_enabled = true

func _ready():
	print("\n========================")
	print("= 场景调试与修复工具启动 =")
	print("========================\n")
	
	# 延迟一帧以确保场景完全加载
	await get_tree().process_frame
	
	if debug_mode:
		debug_scene_structure()
	
	if fix_enabled:
		fix_scene_issues()
	
	print("调试与修复工具完成初始化")
	print("按F1开关调试信息，按F2应用修复")

func _input(event):
	if event.is_action_pressed("ui_focus_next"):  # F1键
		debug_mode = !debug_mode
		if debug_mode:
			debug_scene_structure()
		print("调试模式: " + ("开启" if debug_mode else "关闭"))
	
	if event.is_action_pressed("ui_home"):  # F2键
		fix_scene_issues()
		print("已应用场景修复")

func debug_scene_structure():
	print("\n=== 调试场景结构 ===\n")
	
	# 找到所有TileMap
	var tilemaps = find_all_nodes_of_type(get_tree().root, "TileMap")
	print("TileMap数量: " + str(tilemaps.size()))
	
	for tilemap in tilemaps:
		print("TileMap: " + tilemap.name)
		print("  - 路径: " + get_node_path(tilemap))
		print("  - y_sort_enabled: " + str(tilemap.y_sort_enabled))
		print("  - z_index: " + str(tilemap.z_index))
		print("  - 层数: " + str(tilemap.get_layers_count()))
		
		for i in range(tilemap.get_layers_count()):
			print("  - 层 " + str(i) + ":")
			print("    - y_sort_enabled: " + str(tilemap.get_layer_y_sort_enabled(i)))
			print("    - z_index: " + str(tilemap.get_layer_z_index(i)))
	
	# 找到所有player
	var players = get_tree().get_nodes_in_group("player")
	print("\n玩家数量: " + str(players.size()))
	
	for player in players:
		print("玩家: " + player.name)
		print("  - 路径: " + get_node_path(player))
		print("  - y_sort_enabled: " + str(player.y_sort_enabled if "y_sort_enabled" in player else "N/A"))
		print("  - z_index: " + str(player.z_index))
		
		# 检查玩家是否是TileMap的子节点
		for tilemap in tilemaps:
			if is_node_child_of(player, tilemap):
				print("  - 警告: 玩家是TileMap " + tilemap.name + " 的子节点，这会导致Y排序问题")
	
	# 找到所有敌人
	var enemies = get_tree().get_nodes_in_group("enemy") if get_tree().has_group("enemy") else []
	print("\n敌人数量: " + str(enemies.size()))
	
	for enemy in enemies:
		print("敌人: " + enemy.name)
		print("  - 路径: " + get_node_path(enemy))
		print("  - y_sort_enabled: " + str(enemy.y_sort_enabled if "y_sort_enabled" in enemy else "N/A"))
		print("  - z_index: " + str(enemy.z_index))
		
		# 检查敌人是否是TileMap的子节点
		for tilemap in tilemaps:
			if is_node_child_of(enemy, tilemap):
				print("  - 警告: 敌人是TileMap " + tilemap.name + " 的子节点，这会导致Y排序问题")

func fix_scene_issues():
	print("\n=== 修复场景问题 ===\n")
	
	# 创建并运行修复工具
	var fix_tool = load("res://fix_y_sort.gd").new()
	fix_tool.fix_y_sort_issues()
	fix_tool.queue_free()

func find_all_nodes_of_type(node, type_name):
	var result = []
	
	if node.get_class() == type_name:
		result.append(node)
	
	for child in node.get_children():
		result.append_array(find_all_nodes_of_type(child, type_name))
	
	return result

func get_node_path(node):
	var path = node.name
	var parent = node.get_parent()
	
	while parent and parent != get_tree().root:
		path = parent.name + "/" + path
		parent = parent.get_parent()
	
	return "/" + path

func is_node_child_of(node, potential_parent):
	var parent = node.get_parent()
	while parent:
		if parent == potential_parent:
			return true
		parent = parent.get_parent()
	return false 