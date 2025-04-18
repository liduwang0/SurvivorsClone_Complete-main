extends CharacterBody2D


@export var movement_speed = 20.0
@export var hp = 10
@export var knockback_recovery = 3.5
@export var experience = 1
@export var enemy_damage = 1
var knockback = Vector2.ZERO
var is_dead = false
@onready var player = get_tree().get_first_node_in_group("player")
@onready var loot_base = get_tree().get_first_node_in_group("loot")
@onready var sprite = $Sprite2D
@onready var anim = $AnimationPlayer
@onready var snd_hit = $snd_hit
@onready var hitBox = $HitBox
@onready var damage_number_scene = preload("res://Utility/damage_number.tscn")

# 添加闪烁相关变量
var original_modulate = Color(1, 1, 1, 1)
var hit_flash_timer = null

var death_anim = preload("res://Enemy/explosion.tscn")
var exp_gem = preload("res://Objects/experience_gem.tscn")

signal remove_from_array(object)

# 在现有变量声明部分添加这些变量
var can_attack = true
var attack_cooldown = 0.5  # 攻击冷却时间为0.5秒
var attack_timer = 0.0
var attack_range = 15.0  # 攻击范围，可以根据需要调整

func _ready():
	if anim.has_animation("walk"):
		anim.play("walk")
	else:
		print("Warning: 'walk' animation not found in AnimationPlayer")
	hitBox.damage = enemy_damage
	
	# 保存原始颜色
	original_modulate = sprite.modulate
	
	# 创建闪烁计时器
	hit_flash_timer = Timer.new()
	hit_flash_timer.one_shot = true
	add_child(hit_flash_timer)
	hit_flash_timer.timeout.connect(reset_modulate)
	
	# 连接动画完成信号
	if !anim.animation_finished.is_connected(_on_animation_finished):
		anim.animation_finished.connect(_on_animation_finished)

func _physics_process(_delta):
	if is_dead:
		return
	
	# 处理攻击冷却
	if !can_attack:
		attack_timer += _delta
		if attack_timer >= attack_cooldown:
			can_attack = true
			attack_timer = 0.0
		
	# 原有的击退逻辑
	knockback = knockback.move_toward(Vector2.ZERO, knockback_recovery)
	
	# 计算方向并确保归一化
	var direction = global_position.direction_to(player.global_position).normalized()
	
	# 计算与玩家的距离
	var distance_to_player = global_position.distance_to(player.global_position)
	
	# 如果足够近且可以攻击，开始攻击
	if distance_to_player < attack_range and can_attack and anim.current_animation != "attack" and anim.has_animation("attack"):
		anim.play("attack")
		can_attack = false
		attack_timer = 0.0
	elif anim.current_animation != "attack" and anim.current_animation != "hurt" and knockback.length() < 5:
		# 如果不在攻击或受伤动画中，播放行走动画
		if anim.has_animation("walk"):
			anim.play("walk")
		else:
			print("Warning: 'walk' animation not found in AnimationPlayer")
	
	# 设置速度
	velocity = direction * movement_speed
	velocity += knockback
	
	# 移动
	move_and_slide()
	
	# 方向处理
	if direction.x > 0.1:
		sprite.flip_h = true
	elif direction.x < -0.1:
		sprite.flip_h = false

# 添加重置颜色函数
func reset_modulate():
	sprite.modulate = original_modulate

func death():
	is_dead = true
	emit_signal("remove_from_array", self)
	
	# 禁用物理处理和碰撞，避免继续移动或造成伤害
	set_physics_process(false)
	if has_node("HitBox"):
		$HitBox.monitoring = false
	
	# 连接动画完成信号
	if !anim.animation_finished.is_connected(_on_death_animation_finished):
		anim.animation_finished.connect(_on_death_animation_finished)
	
	# 播放死亡动画
	anim.play("dead")

# 当死亡动画完成时调用
func _on_death_animation_finished(anim_name):
	if anim_name == "dead":
		# 生成经验宝石
		var new_gem = exp_gem.instantiate()
		new_gem.global_position = global_position
		new_gem.experience = experience
		loot_base.call_deferred("add_child", new_gem)
		
		# 添加爆炸视觉效果
		#var enemy_death = death_anim.instantiate()
		#enemy_death.global_position = global_position
		#get_parent().call_deferred("add_child", enemy_death)
		
		# 移除敌人
		queue_free()

# 封装伤害处理函数
func handle_hurt(damage_amount: float, direction: Vector2, knockback_amount: float) -> void:
	# 生成伤害数字
	spawn_damage_number(damage_amount)
	
	# 处理伤害
	hp -= damage_amount
	knockback = direction * knockback_amount
	
	# 处理受伤效果
	if sprite:
		sprite.modulate = Color(10.5, 10.5, 10.5, 1)  # 明亮的白色闪烁
		await get_tree().create_timer(0.1).timeout
		sprite.modulate = Color(1, 1, 1, 1)  # 恢复正常
	
	# 处理死亡或受伤动画
	if hp <= 0:
		if not is_dead:
			death()
	else:
		if snd_hit:
			snd_hit.play()
		
		if anim and anim.has_animation("hurt") and anim.current_animation != "hurt":
			anim.play("hurt")

# 封装伤害数字生成函数
func spawn_damage_number(damage_amount: float) -> void:
	var damage_number = damage_number_scene.instantiate()
	
	# 减小偏移范围和高度
	var random_x = 0
	var random_y = 0
	damage_number.position = Vector2(random_x, -15 + random_y)  # 降低到-15像素
	
	# 使用 setup 而不是 set_damage
	damage_number.setup(int(damage_amount))
	add_child(damage_number)

# 修改原有的hurt回调函数
func _on_hurt_box_hurt(damage_amount: float, direction: Vector2, knockback_amount: float) -> void:
	handle_hurt(damage_amount, direction, knockback_amount)

# 添加动画完成回调
func _on_animation_finished(anim_name):
	if anim_name == "attack":
		# 攻击动画完成后恢复行走
		anim.play("walk")
