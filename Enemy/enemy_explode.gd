extends CharacterBody2D

@export var movement_speed = 30.0
@export var hp = 10
@export var knockback_recovery = 3.5
@export var experience = 1
@export var enemy_damage = 1
@export var explosion_damage = 5
@export var explosion_radius = 50

var knockback = Vector2.ZERO

@onready var player = get_tree().get_first_node_in_group("player")
@onready var loot_base = get_tree().get_first_node_in_group("loot")
@onready var sprite = $Sprite2D
@onready var anim = $AnimationPlayer
@onready var snd_hit = $snd_hit
@onready var hitBox = $HitBox
@onready var damage_number_scene = preload("res://Utility/damage_number.tscn")

var death_anim = preload("res://Enemy/explosion.tscn")
var exp_gem = preload("res://Objects/experience_gem.tscn")

signal remove_from_array(object)

var is_dead = false

func _ready():
	anim.play("walk")
	hitBox.damage = enemy_damage

func _physics_process(_delta):
	# 如果已死亡，不执行移动
	if is_dead:
		return
		
	# 原有的击退逻辑
	knockback = knockback.move_toward(Vector2.ZERO, knockback_recovery)
	var direction = global_position.direction_to(player.global_position)
	velocity = direction*movement_speed
	velocity += knockback
	move_and_slide()
	
	# 方向处理
	if direction.x > 0.1:
		sprite.flip_h = true
	elif direction.x < -0.1:
		sprite.flip_h = false
		
	# 当击退接近结束且当前在受伤动画中，恢复行走动画
	if knockback.length() < 5 and anim.current_animation == "hurt":
		anim.play("walk")

func death():
	is_dead = true
	emit_signal("remove_from_array", self)

	# 禁用物理处理和碰撞，避免继续移动或造成伤害
	$HitBox.monitoring = false
	
		# 先播放受伤动画
	if anim.has_animation("attack"):
		anim.play("attack")
		
		# 简单闪烁效果
		var flash_count = 4  # 闪烁5次
		for i in range(flash_count):
			sprite.modulate = Color(1, 0.3, 0.3, 1)  # 变红
			await get_tree().create_timer(0.1).timeout
			sprite.modulate = Color(1, 1, 1, 1)      # 恢复正常
			await get_tree().create_timer(0.1).timeout
		
		# 等待受伤动画完成(如果还在播放)
		if anim.is_playing():
			await anim.animation_finished
		
	damage_nearby_enemies()
	
	# 确保播放死亡动画
	if anim.has_animation("dead"):
		anim.play("dead")
		# 动画完成后调用
		if not anim.is_connected("animation_finished", _on_death_animation_finished):
			anim.connect("animation_finished", _on_death_animation_finished)
	else:
		# 如果没有死亡动画，直接调用
		_on_death_animation_finished("dead")

# 当死亡动画完成时调用
func _on_death_animation_finished(anim_name):
	if anim_name == "dead":
		#print("============= 番茄死亡，准备爆炸 =============")
		#print("当前位置:", global_position)
		

		
		# 生成经验宝石
		var new_gem = exp_gem.instantiate()
		new_gem.global_position = global_position
		new_gem.experience = experience
		loot_base.call_deferred("add_child", new_gem)
		
		# 添加爆炸视觉效果
	#	var enemy_death = death_anim.instantiate()
	#	enemy_death.scale = sprite.scale
	#	enemy_death.global_position = global_position
	#	get_parent().call_deferred("add_child", enemy_death)
		
		# 延长等待时间确保爆炸有足够时间处理
	#	await get_tree().create_timer(0.6).timeout
		print("番茄被移除")
		queue_free()

# 使用现有HitBox系统的爆炸伤害函数
# 使用现有HitBox系统的爆炸伤害函数
func damage_nearby_enemies():
	 # 删除之前的ColorRect相关代码
	
	# 使用新的绘制圆形类
	var explosion_circle = load("res://Enemy/DrawCircle.gd").new(explosion_radius)
	explosion_circle.global_position = global_position
	get_parent().add_child(explosion_circle)
	
	# 设置自动销毁
	var t = Timer.new()
	t.wait_time = 0.3
	t.one_shot = true
	t.autostart = true
	explosion_circle.add_child(t)
	t.timeout.connect(func(): explosion_circle.queue_free())
	
	# 原有爆炸代码保持不变
	#print("============= 开始爆炸伤害调试 =============")
	

	print("============= 开始爆炸伤害调试 =============")
	print("当前番茄位置:", global_position)
	
	# 扫描场景中的其他敌人并直接伤害
	var all_enemies = []
	_find_all_enemies(get_tree().root, all_enemies)
	print("找到", all_enemies.size(), "个敌人节点")
	
	# 直接对范围内的敌人造成伤害
	var damaged_count = 0
	for enemy in all_enemies:
		if enemy == self:
			continue
			
		var distance = global_position.distance_to(enemy.global_position)
		var in_range = distance <= explosion_radius
		
		print("检查敌人:", enemy.name)
		print("  距离:", distance, " (在范围内: ", in_range, ")")
		
		if in_range:
			# 创建伤害方向（用于击退）
			var direction = (enemy.global_position - global_position).normalized()
			
			# 直接调用敌人的伤害函数
			if enemy.has_method("_on_hurt_box_hurt"):
				enemy._on_hurt_box_hurt(explosion_damage, direction, 100)
				print("  直接对敌人造成伤害:", explosion_damage)
				damaged_count += 1
	
	print("成功直接伤害了", damaged_count, "个敌人")
	
	# 同时创建爆炸HitBox用于伤害玩家
	print("创建爆炸HitBox...")
	var hitbox_scene = load("res://Utility/hit_box.tscn")
	var explosion_hitbox = hitbox_scene.instantiate()
	
	# 配置爆炸伤害
	explosion_hitbox.damage = explosion_damage
	
	# 设置碰撞层
	explosion_hitbox.collision_layer = 2
	explosion_hitbox.collision_mask = 4
	
	# 确保添加到attack组
	explosion_hitbox.add_to_group("attack")
	
	# 将爆炸放在死亡番茄的位置
	explosion_hitbox.global_position = global_position
	
	# 添加到场景中
	get_parent().add_child(explosion_hitbox)
	
	# 修改碰撞形状为圆形
	var collision = explosion_hitbox.get_node("CollisionShape2D")
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = explosion_radius
	collision.shape = circle_shape
	
	# 创建定时器
	var timer = Timer.new()
	timer.wait_time = 0.1 # 刚开始是0.1秒 有时候爆炸炸不到玩家
	timer.one_shot = true
	timer.autostart = true
	explosion_hitbox.add_child(timer)
	timer.timeout.connect(func(): explosion_hitbox.queue_free())
	
	print("============= 爆炸伤害调试结束 =============")

# 辅助函数：递归查找所有敌人(CharacterBody2D)
func _find_all_enemies(node, result):
	if node is CharacterBody2D and node != player and node != self:
		result.append(node)
		
	for child in node.get_children():
		_find_all_enemies(child, result)

# 重写hurt回调函数，添加特殊行为
func _on_hurt_box_hurt(damage_amount: float, direction: Vector2, knockback_amount: float) -> void:
	# 调用基类的伤害处理
	handle_hurt(damage_amount, direction, knockback_amount)
	
	# 添加额外的爆炸特效等特殊行为
	if hp <= 0 and not is_dead:
		# 爆炸相关的特殊代码
		pass

func handle_hurt(damage_amount: float, direction: Vector2, knockback_amount: float) -> void:
	# 生成伤害数字
	spawn_damage_number(damage_amount)
	
	# 处理伤害
	hp -= damage_amount
	knockback = direction * knockback_amount
	
	# 处理受伤效果
	if sprite:
		sprite.modulate = Color(1, 0.3, 0.3, 1)  # 变红
		await get_tree().create_timer(0.2).timeout
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

func spawn_damage_number(damage_amount: float, enable_crit: bool = true) -> void:
	var damage_number = damage_number_scene.instantiate()
	
	# 添加随机偏移
	var random_x = 0
	var random_y = 0
	damage_number.position = Vector2(random_x, random_y)
	
	# 处理暴击
	var is_crit = enable_crit and randf() < 0.2
	var final_damage = damage_amount * (2.0 if is_crit else 1.0)
	
	damage_number.setup(int(damage_amount))
	add_child(damage_number)
