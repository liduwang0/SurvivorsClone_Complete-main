extends Node2D

# 武器属性
var knife_count = 5  # 菜刀数量
var knife_distance = 70  # 菜刀距离角色的距离
var rotation_speed = 2.0  # 旋转速度 (弧度/秒)
var damage = 5  # 菜刀伤害
var knife_scale = Vector2(1, 1)  # 菜刀大小

# 内部变量
var knife_scene = preload("res://Player/Attack/chef_big_knife.tscn")
var knives = []  # 存储所有菜刀实例
var base_rotation = 0.0  # 基础旋转角度

func _ready():
	print("旋转菜刀系统已初始化")
	# 初始化武器
	spawn_knives()

func _process(delta):
	# 旋转菜刀
	base_rotation += rotation_speed * delta
	update_knife_positions()

# 生成菜刀
func spawn_knives():
	# 清除现有菜刀
	for knife in knives:
		if is_instance_valid(knife):
			knife.queue_free()
	knives.clear()
	
	# 生成新菜刀
	for i in range(knife_count):
		var knife = knife_scene.instantiate()
		knife.damage = damage
		knife.scale = knife_scale
		add_child(knife)
		knives.append(knife)
	
	# 更新菜刀位置
	update_knife_positions()

# 更新菜刀位置
func update_knife_positions():
	for i in range(knives.size()):
		if is_instance_valid(knives[i]):
			# 计算菜刀位置
			var angle = base_rotation + (2 * PI * i / knife_count)
			var offset = Vector2(cos(angle), sin(angle)) * knife_distance
			knives[i].position = offset
			
			# 设置菜刀旋转
			knives[i].rotation = angle + PI/2  # 调整菜刀朝向
			
			# 确认是否调用了 update_angle
			if knives[i].has_method("update_angle"):
				# 使用全局位置而不是局部位置
				var player_pos = get_parent().global_position
				knives[i].update_angle(player_pos)
