extends Area2D

var level = 1
var hp = 9999
var speed = 100.0  # 起始速度较慢
var max_speed = 500.0  # 最大速度
var acceleration = 150.0  # 加速度
var damage = 5
var attack_size = 1.0
var knockback_amount = 100

var last_movement = Vector2.ZERO
var angle = Vector2.ZERO
var current_speed = 0.0  # 当前速度
var lifetime = 0.0  # 已存在时间
var max_lifetime = 4.0  # 最大存在时间

signal remove_from_array(object)

@onready var player = get_tree().get_first_node_in_group("player")

func _ready():
	add_to_group("attack")
	
	match level:
		1:
			hp = 9999
			speed = 50.0
			max_speed = 200.0
			damage = 5
			knockback_amount = 100
			attack_size = 1.0 * (1 + player.spell_size)
		2:
			hp = 9999
			speed = 60.0
			max_speed = 240.0
			damage = 7
			knockback_amount = 120
			attack_size = 1.1 * (1 + player.spell_size)
		3:
			hp = 9999
			speed = 70.0
			max_speed = 280.0
			damage = 9
			knockback_amount = 140
			attack_size = 1.2 * (1 + player.spell_size)
		4:
			hp = 9999
			speed = 80.0
			max_speed = 320.0
			damage = 11
			knockback_amount = 160
			attack_size = 1.3 * (1 + player.spell_size)
		5:
			hp = 9999
			speed = 90.0
			max_speed = 350.0
			damage = 13
			knockback_amount = 180
			attack_size = 1.4 * (1 + player.spell_size)
	
	# 设置初始速度
	current_speed = speed
	
# 使用传入的angle参数，而不是last_movement
	if angle != Vector2.ZERO:
		angle = angle.normalized()
	else:
		# 如果没有提供角度，使用默认向右的方向
		angle = Vector2.RIGHT
	
	# 根据移动方向设置旋转
	rotation = angle.angle()
	
	# 设置初始缩放
	scale = Vector2(attack_size, attack_size)
	
	# 设置自毁计时器
	var timer = Timer.new()
	timer.wait_time = max_lifetime
	timer.one_shot = true
	timer.timeout.connect(Callable(self, "_on_timer_timeout"))
	add_child(timer)
	timer.start()

func _physics_process(delta):
	# 更新存在时间
	lifetime += delta
	
	# 从慢到快加速
	current_speed = min(current_speed + acceleration * delta, max_speed)
	
	# 沿着设定的方向移动
	position += angle * current_speed * delta

func _on_timer_timeout():
	emit_signal("remove_from_array", self)
	queue_free()

func enemy_hit(_charge = 1):
	# 可选：击中敌人时的特殊效果
	pass
