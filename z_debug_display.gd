extends Node2D

var labels = []
var display_enabled = true
var update_interval = 0.5
var time_since_last_update = 0

func _ready():
	# 创建调试标签
	create_debug_labels()
	
	# 设置快捷键切换显示
	set_process_input(true)

func _input(event):
	if event.is_action_pressed("ui_cancel"):  # ESC键
		display_enabled = !display_enabled
		for label in labels:
			label.visible = display_enabled

func _process(delta):
	time_since_last_update += delta
	if time_since_last_update >= update_interval:
		time_since_last_update = 0
		update_debug_info()

func create_debug_labels():
	# 清除现有标签
	for label in labels:
		label.queue_free()
	labels.clear()
	
	# 创建新标签
	var parent = get_parent()
	
	# 玩家信息标签
	var player_label = create_label(Vector2(0, -80), Color(1, 1, 0))
	labels.append(player_label)
	
	# 父节点信息标签
	var parent_label = create_label(Vector2(0, -100), Color(0, 1, 1))
	labels.append(parent_label)
	
	# TileMap信息标签
	var tilemap_label = create_label(Vector2(0, -120), Color(1, 0.5, 0))
	labels.append(tilemap_label)
	
	update_debug_info()

func create_label(position, color):
	var label = Label.new()
	label.position = position
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	label.add_theme_constant_override("outline_size", 2)
	add_child(label)
	return label

func update_debug_info():
	if not display_enabled:
		return
	
	var parent = get_parent()
	
	# 更新玩家信息
	labels[0].text = "Player: z_index=" + str(parent.z_index) + \
		", y_sort=" + str(parent.y_sort_enabled if "y_sort_enabled" in parent else "N/A") + \
		", pos=" + str(int(parent.global_position.x)) + "," + str(int(parent.global_position.y))
	
	# 更新父节点信息
	var parent_of_parent = parent.get_parent()
	labels[1].text = "Parent: " + parent_of_parent.name + \
		", z_index=" + str(parent_of_parent.z_index) + \
		", y_sort=" + str(parent_of_parent.y_sort_enabled if "y_sort_enabled" in parent_of_parent else "N/A")
	
	# 查找场景中的TileMap
	var tilemaps = []
	find_tilemaps(get_tree().root, tilemaps)
	
	if tilemaps.size() > 0:
		var tilemap = tilemaps[0]  # 获取第一个TileMap
		labels[2].text = "TileMap: " + tilemap.name + \
			", z_index=" + str(tilemap.z_index) + \
			", y_sort=" + str(tilemap.y_sort_enabled)
	else:
		labels[2].text = "No TileMap found"

func find_tilemaps(node, result):
	if node is TileMap:
		result.append(node)
	
	for child in node.get_children():
		find_tilemaps(child, result) 