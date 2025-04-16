extends Area2D

# 将节点添加到攻击组
func _init():
	add_to_group("attack")

# 子弹基本属性
var speed = 100
var damage = 5
var knockback_amount = 8
var target = Vector2.ZERO
var angle = Vector2.ZERO
var life_time = 10.0

# 头部特效场景
var head_effect_scene = preload("res://Enemy/enemy_eggplant_shoot_effect.tscn")
var head_effect = null

@onready var animation_player = $AnimationPlayer
@onready var sound_effect = $Sound_shoot

func _ready():
	# 计算方向向量
	angle = global_position.direction_to(target)
	# 设置子弹旋转，使其朝向目标
	rotation = angle.angle() + PI/2
	
	# 启动生命周期计时器
	$LifeTimer.wait_time = life_time
	$LifeTimer.start()
	
	# 播放发射声音
	if sound_effect and sound_effect.stream:
		sound_effect.play()
	
	# 播放飞行动画
	if animation_player and animation_player.has_animation("bullet_fly"):
		animation_player.play("bullet_fly")
	
	# 添加头部特效
	add_head_effect()

# 添加头部特效
func add_head_effect():
	head_effect = head_effect_scene.instantiate()
	# 不需要设置位置，因为是作为子节点添加，会使用本地坐标
	add_child(head_effect)
	# 确保特效与子弹方向一致
	# 如果需要，可以在这里调整特效的位置偏移

func _physics_process(delta):
	# 移动子弹
	position += angle * speed * delta

# 碰撞检测
func _on_body_entered(body):
	# 检查是否击中玩家
	if body.is_in_group("player"):
		# 对玩家造成伤害
		if body.has_method("_on_hurt_box_hurt"):
			var knockback_direction = (body.global_position - global_position).normalized()
			body._on_hurt_box_hurt(damage, knockback_direction, knockback_amount)
		# 播放击中效果
		play_hit_effect()

# 区域检测
func _on_area_entered(area):
	if area.is_in_group("hurtbox"):
		# 播放击中效果
		play_hit_effect()

# 播放击中效果
func play_hit_effect():
	# 停止移动
	set_physics_process(false)
	# 如果存在头部特效，移除它
	if head_effect and is_instance_valid(head_effect):
		head_effect.queue_free()
	# 直接销毁，因为没有击中动画
	queue_free()

# 生命周期结束
func _on_life_timer_timeout():
	queue_free()

# 当子弹击中敌人时调用
func enemy_hit(charge = 1):
	# 直接销毁
	queue_free()
