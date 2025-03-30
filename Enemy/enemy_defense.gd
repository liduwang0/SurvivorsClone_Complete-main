extends "res://Enemy/enemy.gd"

# 状态枚举
enum State {NORMAL, DEFENSE}
var current_state = State.NORMAL

# 时间参数
@export var min_walk_time = 1.0  # 最短行走时间
@export var max_walk_time = 4.0  # 最长行走时间
@export var min_defense_time = 2.0  # 最短防御时间
@export var max_defense_time = 5.0  # 最长防御时间

# 计时器
var state_timer = 0.0
var current_state_duration = 0.0
var is_invincible = false  # 是否处于无敌状态

# 用于闪烁效果的变量
#var original_modulate = Color(1, 1, 1, 1)
#var flash_timer = null

func _ready():
	super._ready()  # 调用父类的_ready方法
	# 设置初始状态持续时间
	current_state_duration = randf_range(min_walk_time, max_walk_time)
	
	# 保存原始颜色
	original_modulate = sprite.modulate
	
	# 创建闪烁计时器
	#flash_timer = Timer.new()
	#flash_timer.one_shot = true
	#add_child(flash_timer)
	#flash_timer.timeout.connect(reset_modulate)

func _physics_process(delta):
	if is_dead:
		return
		
	# 状态计时
	state_timer += delta
	
	match current_state:
		State.NORMAL:
			# 正常状态下使用基础敌人的移动逻辑
			super._physics_process(delta)
			
			# 检查是否应该进入防御状态
			if state_timer >= current_state_duration:
				enter_defense_state()
				
		State.DEFENSE:
			# 防御状态下停止移动
			velocity = Vector2.ZERO
			
			# 检查是否应该退出防御状态
			if state_timer >= current_state_duration:
				exit_defense_state()

# 进入防御状态
func enter_defense_state():
	current_state = State.DEFENSE
	state_timer = 0.0
	# 随机设置防御持续时间
	current_state_duration = randf_range(min_defense_time, max_defense_time)
	
	# 播放防御动画
	if anim.has_animation("defense"):
		# 直接设置循环模式
		anim.get_animation("defense").loop_mode = 1  # 1 = 循环
		anim.play("defense")
	elif anim.has_animation("new_animation"):
		anim.get_animation("new_animation").loop_mode = 1
		anim.play("new_animation")
	
	# 设置无敌状态标志，但不禁用HurtBox
	is_invincible = true
	
	print("Cabbage进入防御状态，持续", current_state_duration, "秒")

# 退出防御状态
func exit_defense_state():
	current_state = State.NORMAL
	state_timer = 0.0
	# 随机设置行走持续时间
	current_state_duration = randf_range(min_walk_time, max_walk_time)
	
	# 恢复行走动画
	if anim.has_animation("walk"):
		anim.play("walk")
	
	# 取消无敌状态
	is_invincible = false
	
	print("Cabbage退出防御状态，将行走", current_state_duration, "秒")

# 重置精灵颜色
func reset_modulate():
	sprite.modulate = original_modulate

# 重写伤害处理函数，在防御状态下不受伤害但仍然检测碰撞
func _on_hurt_box_hurt(damage, angle, knockback_amount):
	if is_invincible:
		# 播放防御音效或特效（如果有）
		print("Cabbage处于防御状态，免疫伤害!")
		
		# 停止之前的计时器
		#flash_timer.stop()
		
		# 闪烁效果
		#sprite.modulate = Color(0.5, 0.5, 1.0, 1.0)  # 蓝色闪烁表示防御
		
		# 设置计时器恢复原始颜色
		#flash_timer.wait_time = 0.1
		#flash_timer.start()
		
		return
		
	# 正常状态下调用父类的伤害处理
	super._on_hurt_box_hurt(damage, angle, knockback_amount)

# 重写死亡函数，确保在死亡时退出防御状态
func death():
	# 确保退出防御状态
	is_invincible = false
	
	# 恢复原始颜色
	reset_modulate()
	
	# 调用父类的死亡函数
	super.death()
