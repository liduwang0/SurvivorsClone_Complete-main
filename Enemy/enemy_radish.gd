extends "res://Enemy/enemy.gd"

enum RadishState {
	WALK,       # 行走状态，追逐玩家
	PREP_ROLL,  # 准备滚动状态，播放attack_begin动画
	ROLLING,    # 滚动攻击状态，播放attack动画
	END_ROLL,   # 结束滚动状态，播放attack_end动画
	IDLE,       # 待机状态，播放idle动画
	HURT,       # 受伤状态，新增
	DEAD        # 死亡状态，新增
}

# 萝卜敌人的攻击相关属性
@export var roll_attack_range = 220.0  # 开始滚动攻击的范围
@export var roll_attack_damage = 15    # 滚动攻击的伤害
@export var roll_attack_speed = 80.0   # 滚动攻击的速度
@export var roll_duration = 3.0        # 滚动持续时间
@export var idle_duration = 1.0        # 待机时间

# 状态相关变量
var current_state = RadishState.WALK
var roll_timer = 0.0
var idle_timer = 0.0
var roll_direction = Vector2.ZERO
var can_roll_attack = true
var roll_cooldown = 5.0
var roll_cooldown_timer = 0.0
var original_movement_speed = 0.0  # 添加这个变量来保存原始移动速度
var previous_state = RadishState.WALK  # 保存受伤前的状态

func _ready():
	# 保存原始移动速度
	original_movement_speed = movement_speed
	
	# 连接动画播放结束的信号
	if anim and !anim.animation_finished.is_connected(_on_animation_finished):
		anim.animation_finished.connect(_on_animation_finished)

func _physics_process(delta):
	# 处理滚动攻击冷却
	if !can_roll_attack:
		roll_cooldown_timer += delta
		if roll_cooldown_timer >= roll_cooldown:
			can_roll_attack = true
			roll_cooldown_timer = 0.0
	
	match current_state:
		RadishState.WALK:
			# 走路状态 - 使用父类的行为追逐玩家
			super._physics_process(delta)
			
			# 检查是否在攻击范围内且可以进行滚动攻击
			if player and can_roll_attack:
				var distance_to_player = global_position.distance_to(player.global_position)
				if distance_to_player < roll_attack_range:
					# 开始准备滚动攻击
					change_state(RadishState.PREP_ROLL)
		
		RadishState.PREP_ROLL:
			# 准备滚动状态 - 播放准备动画，动画结束后会触发_on_animation_finished
			# 在此状态中停止移动，但仍然面向玩家
			face_player()
			
			# 计算滚动方向 - 朝向玩家
			if player:
				roll_direction = global_position.direction_to(player.global_position).normalized()
			
			# 应用击退力
			handle_knockback(delta)
		
		RadishState.ROLLING:
			# 滚动攻击状态 - 以较快速度朝固定方向滚动
			roll_timer += delta
			
			# 以滚动速度向前移动
			velocity = roll_direction * roll_attack_speed
			
			# 应用击退力，但减弱其影响，让滚动更稳定
			velocity += knockback * 0.3  # 减弱击退对滚动的影响
			knockback = knockback.move_toward(Vector2.ZERO, knockback_recovery * 2)  # 更快地消除击退
			
			# 移动
			move_and_slide()
			
			# 确保动画保持为滚动动画，无论发生什么都要保持滚动动画
			if anim.current_animation != "attack":
				anim.play("attack")
			
			# 检查滚动时间是否结束
			if roll_timer >= roll_duration:
				change_state(RadishState.END_ROLL)
				
			# 更新HitBox伤害值
			if hitBox:
				hitBox.damage = roll_attack_damage
		
		RadishState.END_ROLL:
			# 结束滚动状态 - 播放结束动画，动画结束后会触发_on_animation_finished
			# 在此状态中停止移动
			velocity = knockback
			knockback = knockback.move_toward(Vector2.ZERO, knockback_recovery)
			move_and_slide()
			
			# 恢复HitBox伤害值为默认值
			if hitBox:
				hitBox.damage = enemy_damage
		
		RadishState.IDLE:
			# 待机状态 - 播放idle动画，倒计时后回到走路状态
			idle_timer += delta
			
			# 仅应用击退力
			velocity = knockback
			knockback = knockback.move_toward(Vector2.ZERO, knockback_recovery)
			move_and_slide()
			
			# 检查待机时间是否结束
			if idle_timer >= idle_duration:
				change_state(RadishState.WALK)
		
		RadishState.HURT:
			# 受伤状态 - 等待受伤动画播放完毕
			# 只处理击退
			velocity = knockback
			knockback = knockback.move_toward(Vector2.ZERO, knockback_recovery)
			move_and_slide()

# 状态改变函数
func change_state(new_state):
	# 退出当前状态
	match current_state:
		RadishState.ROLLING:
			# 结束滚动时重置计时器
			roll_timer = 0.0
		RadishState.IDLE:
			# 结束待机时重置计时器
			idle_timer = 0.0
	
	# 设置新状态
	current_state = new_state
	
	# 进入新状态
	match new_state:
		RadishState.WALK:
			if anim.has_animation("walk"):
				anim.play("walk")
				
		RadishState.PREP_ROLL:
			if anim.has_animation("attack_begin"):
				anim.play("attack_begin")
				
		RadishState.ROLLING:
			if anim.has_animation("attack"):
				anim.play("attack")
				
		RadishState.END_ROLL:
			if anim.has_animation("attack_end"):
				anim.play("attack_end")
				
		RadishState.IDLE:
			if anim.has_animation("idle"):
				anim.play("idle")
		
		RadishState.HURT:
			# 受伤状态不需要手动播放动画，因为父类的处理已经播放了hurt动画
			pass

# 处理击退效果
func handle_knockback(delta):
	knockback = knockback.move_toward(Vector2.ZERO, knockback_recovery)
	velocity = knockback
	move_and_slide()

# 让敌人面向玩家
func face_player():
	if player:
		var direction = global_position.direction_to(player.global_position)
		if direction.x > 0.1:
			sprite.flip_h = true
		elif direction.x < -0.1:
			sprite.flip_h = false

# 覆盖动画完成回调
func _on_animation_finished(anim_name):
	match anim_name:
		"attack_begin":
			# 准备动画结束后，开始滚动攻击
			change_state(RadishState.ROLLING)
			
		"attack":
			# 滚动动画循环播放，不需要处理
			pass
			
		"attack_end":
			# 结束动画播放完后，进入待机状态
			change_state(RadishState.IDLE)
			
		"idle":
			# 待机动画循环播放，通过计时器控制状态切换
			pass
			
		"hurt":
			# 受伤动画结束后，根据之前的状态决定下一步
			if current_state == RadishState.HURT:
				if previous_state == RadishState.ROLLING:
					# 如果之前在滚动，可以选择继续滚动或结束滚动
					# 这里选择结束滚动，进入结束滚动状态
					change_state(RadishState.END_ROLL)
				else:
					# 恢复到走路状态
					change_state(RadishState.WALK)
			
		"dead":
			# 死亡动画处理，调用父类方法
			super._on_animation_finished(anim_name)
			
		_:
			# 其他动画，调用父类方法
			if has_method("super._on_animation_finished"):
				super._on_animation_finished(anim_name)

# 覆盖处理受伤的函数，添加状态控制
func handle_hurt(damage_amount: float, direction: Vector2, knockback_amount: float) -> void:
	# 保存当前状态
	if current_state != RadishState.HURT and current_state != RadishState.DEAD:
		previous_state = current_state
	
	# 如果在滚动状态，不切换状态，只应用伤害和击退效果
	if current_state == RadishState.ROLLING:
		# 只应用伤害，不播放受伤动画
		hp -= clamp(damage_amount, 1.0, 999.0)
		
		# 应用减弱的击退效果
		knockback += direction * (knockback_amount * 0.3)
		
		# 闪烁效果（白色，更明显）
		if sprite:
			sprite.modulate = Color(10.5, 10.5, 10.5, 1)  # 明亮的白色
			get_tree().create_timer(0.1).timeout.connect(func(): sprite.modulate = Color(1, 1, 1, 1))
		
		# 检查是否死亡
		if hp <= 0:
			death()
	else:
		# 对于其他状态，使用正常的受伤处理
		if current_state == RadishState.PREP_ROLL or current_state == RadishState.END_ROLL:
			change_state(RadishState.HURT)
		
		# 调用父类的伤害处理
		super.handle_hurt(damage_amount, direction, knockback_amount)

# 覆盖受伤函数，重定向到自定义的处理函数
func _on_hurt_box_hurt(damage_amount: float, direction: Vector2, knockback_amount: float) -> void:
	handle_hurt(damage_amount, direction, knockback_amount) 
