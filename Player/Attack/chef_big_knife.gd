extends Area2D

var damage = 5
var knockback_amount = 100  # 恢复到中等值
var angle = Vector2.RIGHT  # 添加角度属性，默认向右
var hit_timer = 0
var hit_cooldown = 1.0  # 1秒冷却时间

signal remove_from_array(object)  # 添加信号

func _ready():
	
	# 将自己添加到"attack"组，这样敌人的HurtBox可以识别
	add_to_group("attack")

# 修复函数 - 这是关键!
func update_angle(player_position):
	# 计算从玩家到菜刀的方向向量
	var new_angle = (global_position - player_position).normalized()
	# 确保这个向量不是零向量
	if new_angle.length() < 0.1:
		new_angle = Vector2.RIGHT  # 防止零向量
	
	# 强制调试打印
	print(">>>>>> 更新菜刀角度 <<<<<< ID:", get_instance_id())
	print("原始角度:", angle)
	print("新角度:", new_angle)
	print("菜刀位置:", global_position)
	print("玩家位置:", player_position)
	
	# 设置新的角度
	angle = new_angle

# 保持原来的 enemy_hit 函数简单实现
func enemy_hit(_charge = 1):
	emit_signal("remove_from_array", self)

func _process(delta):
	# 计时器
	hit_timer += delta
	if hit_timer >= hit_cooldown:
		hit_timer = 0
		# 发出信号，使自己从hit_once_array中移除
		emit_signal("remove_from_array", self)
