extends "res://Enemy/enemy.gd"

# 预加载子弹场景
var bullet_scene = preload("res://Enemy/enemy_eggplant_bullet.tscn")
var bullet_shoot_effect = preload("res://Enemy/enemy_eggplant_shoot_effect.tscn")
# 发射相关属性
@export var shoot_cooldown = 5.0  # 发射冷却时间（秒）
@export var shooting_range = 200.0  # 射击范围
var can_shoot = true
var shoot_timer = 0.0
var is_shooting = false  # 新增：标记是否正在射击
var original_movement_speed = 0.0  # 保存原始移动速度

func _ready():
	# 保存原始移动速度
	original_movement_speed = movement_speed
	
	# 连接动画播放结束的信号
	if anim and !anim.animation_finished.is_connected(_on_animation_finished):
		anim.animation_finished.connect(_on_animation_finished)

# 重写父类的物理处理函数，在子类中处理自定义行为
func _physics_process(delta):
	# 在攻击时不调用父类的_physics_process，而是自行处理
	if is_shooting:
		# 攻击时的处理逻辑 - 主要是停止移动，但保留其他功能
		if is_dead:
			return
		
		# 原有的击退逻辑
		knockback = knockback.move_toward(Vector2.ZERO, knockback_recovery)
		
		# 只应用击退力，不添加移动速度
		velocity = knockback
		
		# 移动（仅应用击退，没有主动移动）
		move_and_slide()
		
		# 但仍面向玩家
		if player:
			var direction = global_position.direction_to(player.global_position)
			if direction.x > 0.1:
				sprite.flip_h = true
			elif direction.x < -0.1:
				sprite.flip_h = false
	else:
		# 非攻击状态，调用父类的物理处理
		super._physics_process(delta)
	
	# 处理射击冷却
	if !can_shoot:
		shoot_timer += delta
		if shoot_timer >= shoot_cooldown:
			can_shoot = true
			shoot_timer = 0.0
	
	# 检查是否在射击范围内且可以射击，且不在射击状态
	if player and can_shoot and !is_shooting:
		var distance_to_player = global_position.distance_to(player.global_position)
		if distance_to_player < shooting_range:
			start_shoot_animation()
			can_shoot = false
			shoot_timer = 0.0

# 开始播放攻击动画
func start_shoot_animation():
	is_shooting = true  # 标记正在射击
	# 播放攻击动画
	if anim.has_animation("attack"):
		anim.play("attack")
	else:
		# 如果没有攻击动画，直接生成子弹
		generate_bullet()
		is_shooting = false

# 在动画结束时调用
func _on_animation_finished(anim_name):
	if anim_name == "attack":
		generate_bullet()
		is_shooting = false  # 射击结束
		# 恢复行走动画
		if anim.has_animation("walk"):
			anim.play("walk")
	elif anim_name == "dead":
		# 如果有其他需要在死亡动画结束时处理的逻辑，保留父类的处理
		super._on_animation_finished(anim_name)
	else:
		# 其他动画，调用父类的处理
		if has_method("super._on_animation_finished"):
			super._on_animation_finished(anim_name)

# 生成子弹的函数，从原来的shoot函数拆分出来
func generate_bullet():
	# 创建子弹实例
	var bullet = bullet_scene.instantiate()
	bullet.global_position = global_position
	
	# 确保玩家还存在
	if player and is_instance_valid(player):
		bullet.target = player.global_position
	else:
		# 如果玩家不存在了，向前发射
		bullet.target = global_position + Vector2(1, 0)
	
	# 添加子弹到场景
	get_parent().add_child(bullet)
	
	# 播放发射声音（可选）
	if has_node("ShootSound"):
		$ShootSound.play()

# 保留原来的shoot函数以备需要直接调用
func shoot():
	start_shoot_animation()
