extends CharacterBody2D

@export var movement_speed = 20.0
@export var hp = 10
@export var knockback_recovery = 3.5
@export var experience = 1
@export var enemy_damage = 1
@export var use_flow_field: bool = true

# 性能优化相关变量
@export var enable_optimization: bool = true  # 是否启用优化
@export_group("Performance Settings")
@export var close_distance: float = 400.0  # 近距离: 完整AI逻辑
@export var medium_distance: float = 800.0  # 中距离: 降低更新频率
@export var far_distance: float = 1500.0  # 远距离: 最低更新频率和简化AI
@export var close_update_frames: int = 1  # 近距离: 每帧更新
@export var medium_update_frames: int = 3  # 中距离: 每3帧更新
@export var far_update_frames: int = 5  # 远距离: 每5帧更新
@export var very_far_sleep: bool = true  # 超远距离是否休眠

var frame_counter = 0  # 帧计数器
var update_frames = 1  # 当前更新频率
var current_distance = 0.0  # 当前与玩家的距离
var is_sleeping = false  # 是否处于休眠状态
var cached_direction = Vector2.ZERO  # 缓存的移动方向
var update_decision_counter = 0  # 决策更新计数器
var decision_update_frames = 30  # 每30帧更新一次决策频率

var knockback = Vector2.ZERO
var is_dead = false
@onready var player = get_tree().get_first_node_in_group("player")
@onready var loot_base = get_tree().get_first_node_in_group("loot")
@onready var sprite = $Sprite2D
@onready var anim = $AnimationPlayer
@onready var snd_hit = $snd_hit
@onready var hitBox = $HitBox
@onready var flow_field = null  # 将在_ready中查找
@onready var damage_number_scene = preload("res://Utility/damage_number.tscn")

# 闪烁相关变量
var original_modulate = Color(1, 1, 1, 1)
var hit_flash_timer = null

var death_anim = preload("res://Enemy/explosion.tscn")
var exp_gem = preload("res://Objects/experience_gem.tscn")

signal remove_from_array(object)

# 攻击相关变量
var can_attack = true
var attack_cooldown = 0.5
var attack_timer = 0.0
var attack_range = 15.0

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
	
	# 查找流场节点
	# 先尝试找到父场景中的流场
	flow_field = get_node_or_null("../../FlowField")
	
	# 如果没找到，尝试在根场景中查找
	if flow_field == null:
		# 尝试遍历场景树找到FlowField
		var flow_fields = get_tree().get_nodes_in_group("flow_field")
		if flow_fields.size() > 0:
			flow_field = flow_fields[0]
		else:
			# 最后尝试特定路径
			flow_field = get_node_or_null("/root/FlowFieldObstacleTest/Node2D/FlowField")
			if flow_field == null:
				flow_field = get_node_or_null("/root/FlowFieldTest/Node2D/FlowField")
	
	# 如果仍然找不到，输出警告
	if flow_field == null and use_flow_field:
		print("Warning: FlowField node not found for enemy at ", global_position)
	
	# 初始化随机帧计数器，避免所有敌人同时更新
	if enable_optimization:
		frame_counter = randi() % 5
		update_decision_counter = randi() % decision_update_frames

func _physics_process(delta):
	if is_dead:
		return
	
	# 基于距离的性能优化
	if enable_optimization and player != null:
		# 增加决策计数器
		update_decision_counter += 1
		
		# 间隔一段时间更新距离和决策
		if update_decision_counter >= decision_update_frames:
			update_decision_counter = 0
			current_distance = global_position.distance_to(player.global_position)
			
			# 基于距离设置更新频率
			if current_distance < close_distance:
				update_frames = close_update_frames
				is_sleeping = false
			elif current_distance < medium_distance:
				update_frames = medium_update_frames
				is_sleeping = false
			elif current_distance < far_distance:
				update_frames = far_update_frames
				is_sleeping = false
			else:
				# 超远距离可选择完全休眠
				if very_far_sleep:
					is_sleeping = true
				else:
					update_frames = far_update_frames
					is_sleeping = false
		
		# 如果处于休眠状态，跳过处理
		if is_sleeping:
			return
		
		# 帧计数器增加
		frame_counter += 1
		
		# 只在指定帧数更新逻辑
		if frame_counter < update_frames:
			# 使用缓存的方向继续移动，但不更新方向
			velocity = cached_direction * movement_speed
			velocity += knockback
			move_and_slide()
			return
		else:
			frame_counter = 0
	
	# 处理攻击冷却
	if !can_attack:
		attack_timer += delta
		if attack_timer >= attack_cooldown:
			can_attack = true
			attack_timer = 0.0
		
	# 原有的击退逻辑
	knockback = knockback.move_toward(Vector2.ZERO, knockback_recovery)
	
	# 获取移动方向
	var direction = Vector2.ZERO
	
	# 根据距离选择不同的寻路策略
	if enable_optimization and current_distance > medium_distance:
		# 远距离直接朝向玩家，不使用流场
		direction = global_position.direction_to(player.global_position).normalized()
	else:
		# 近距离使用流场或直接寻路
		if use_flow_field and flow_field != null:
			# 使用流场获取移动方向
			direction = flow_field.get_flow_direction(global_position)
			if direction == Vector2.ZERO:
				# 如果流场没有方向，回退到直接寻路
				direction = global_position.direction_to(player.global_position).normalized()
		else:
			# 直接向玩家移动
			direction = global_position.direction_to(player.global_position).normalized()
	
	# 缓存计算出的方向，供非更新帧使用
	cached_direction = direction
	
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
		
		# 移除敌人
		queue_free()

# 封装伤害处理函数
func handle_hurt(damage_amount: float, direction: Vector2, knockback_amount: float) -> void:
	# 如果敌人被打中，唤醒它（如果处于休眠状态）
	if is_sleeping:
		is_sleeping = false
		update_frames = medium_update_frames
	
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
	# 在远距离时不生成伤害数字以提高性能
	if enable_optimization and current_distance > medium_distance:
		return
		
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

# 当敌人进入玩家视野时被唤醒
func _on_visible_on_screen_notifier_2d_screen_entered():
	if enable_optimization and is_sleeping:
		is_sleeping = false
		update_frames = medium_update_frames 
