extends "res://Utility/flow_field.gd"

# 这个脚本扩展了流场类，使得场边界动态跟随玩家移动
# 通过覆盖原始脚本的关键函数实现功能

# 每次更新时中心点应该移动的距离阈值
@export var center_move_threshold: float = 150.0

# 上次更新field_bounds的中心位置
var _last_bounds_center: Vector2 = Vector2.ZERO
# 记录场边界中心和玩家位置之间的偏移
var _player_bounds_offset: Vector2 = Vector2.ZERO

func _ready():
	# 调用父类的_ready方法
	super._ready()
	
	# 设置初始场边界中心位置
	_last_bounds_center = Vector2(
		field_bounds.position.x + field_bounds.size.x / 2,
		field_bounds.position.y + field_bounds.size.y / 2
	)
	
	# 启用调试绘制以便查看场地边界
	debug_draw = true

# 覆盖_update_visible_bounds方法，在更新可见区域的同时更新field_bounds
func _update_visible_bounds():
	# 获取玩家位置
	var player_pos = Vector2.ZERO
	var camera = get_viewport().get_camera_2d()
	if camera != null:
		player_pos = camera.global_position
	else:
		# 如果没有相机，尝试找到玩家节点
		var player = get_tree().get_first_node_in_group("player")
		if player != null:
			player_pos = player.global_position
	
	# 计算当前场边界的中心
	var current_bounds_center = Vector2(
		_original_field_bounds.position.x + _original_field_bounds.size.x / 2,
		_original_field_bounds.position.y + _original_field_bounds.size.y / 2
	)
	
	# 检查玩家是否移动了足够远的距离
	var distance_moved = _last_bounds_center.distance_to(player_pos)
	if distance_moved > center_move_threshold:
		# 更新field_bounds位置，使其中心与玩家位置对齐
		var new_bounds_position = Vector2(
			player_pos.x - _original_field_bounds.size.x / 2,
			player_pos.y - _original_field_bounds.size.y / 2
		)
		
		# 更新field_bounds
		field_bounds = Rect2(new_bounds_position, _original_field_bounds.size)
		
		# 更新_original_field_bounds，这样_ensure_field_bounds_integrity不会重置位置
		_original_field_bounds = Rect2(new_bounds_position, _original_field_bounds.size)
		
		# 更新上次场边界中心位置
		_last_bounds_center = player_pos
		
		# 由于场边界已更改，需要重新计算网格尺寸和初始化场
		grid_size = Vector2i(
			int(field_bounds.size.x / cell_size),
			int(field_bounds.size.y / cell_size)
		)
		
		# 重新初始化场，适应新的边界
		_initialize_fields()
		
		# 强制下一帧更新流场
		_force_next_update = true
		
		print("已移动场边界到玩家位置: ", player_pos)
	
	# 调用父类的实现来更新可见区域
	super._update_visible_bounds()

# 覆盖_ensure_field_bounds_integrity方法，允许field_bounds被修改
func _ensure_field_bounds_integrity():
	# 我们允许field_bounds被修改，所以这里不需要做任何事情
	pass 
