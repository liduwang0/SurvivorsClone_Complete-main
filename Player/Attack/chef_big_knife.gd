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

# 当菜刀击中敌人时调用
func enemy_hit(_charge = 1):
	# 每次击中敌人时，发出信号
	# 这样可以立即从hit_once_array中移除自己
	emit_signal("remove_from_array", self)
	pass

# 添加一个区域进入信号处理函数，用于调试
func _on_area_entered(area):
	print("菜刀区域进入:", area.name)

func _on_body_entered(body):
	print("菜刀碰撞到:", body.name)

# 更新角度 - 在player_chef.gd中的update_knife_positions函数中调用
func update_angle(player_position):
	# 计算从玩家到菜刀的方向向量
	angle = (global_position - player_position).normalized()
	
	# 添加调试信息
	#print("菜刀角度更新: ", angle, " 位置: ", global_position, " 玩家位置: ", player_position)

func _process(delta):
	# 计时器
	hit_timer += delta
	if hit_timer >= hit_cooldown:
		hit_timer = 0
		# 发出信号，使自己从hit_once_array中移除
		emit_signal("remove_from_array", self)
