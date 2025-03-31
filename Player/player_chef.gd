extends CharacterBody2D

var movement_speed = 100.0
var hp = 80
var maxhp = 80
var last_movement = Vector2.UP
var time = 0

var experience = 0
var experience_level = 1
var collected_experience = 0

# 攻击
var chef_big_knife = preload("res://Player/Attack/chef_big_knife.tscn")

# 旋转菜刀属性
var knife_count = 5  # 菜刀数量
var knife_distance = 70  # 菜刀距离角色的距离
var rotation_speed = 6.0  # 旋转速度 (弧度/秒)
var knife_damage = 0.1  # 菜刀伤害
var knife_scale = Vector2(1, 1)  # 菜刀大小
var base_rotation = 0.0  # 基础旋转角度
var knives = []  # 存储所有菜刀实例

# 敌人相关
var enemy_close = []

@onready var sprite = $Sprite2D
@onready var walkTimer = get_node("%walkTimer")

# GUI
@onready var expBar = get_node("%ExperienceBar")
@onready var lblLevel = get_node("%lbl_level")
@onready var levelPanel = get_node("%LevelUp")
@onready var upgradeOptions = get_node("%UpgradeOptions")
@onready var healthBar = get_node("%HealthBar")
@onready var lblTimer = get_node("%lblTimer")
@onready var collectedWeapons = get_node("%CollectedWeapons")
@onready var collectedUpgrades = get_node("%CollectedUpgrades")

@onready var deathPanel = get_node("%DeathPanel")
@onready var lblResult = get_node("%lbl_Result")

# 信号
signal playerdeath

func _ready():
	# 添加到player组
	add_to_group("player")
	
	# 初始化旋转菜刀
	spawn_knives()
	
	# 设置血条
	healthBar.max_value = maxhp
	healthBar.value = hp
	
	# 设置经验条
	expBar.max_value = experience_level * 5

func _physics_process(delta):
	# 移动逻辑
	var direction = Input.get_vector("left", "right", "up", "down")
	if direction.length() > 0:
		velocity = direction.normalized() * movement_speed
		last_movement = direction.normalized()
	else:
		velocity = Vector2.ZERO
	
	move_and_slide()
	
	# 更新游戏时间
	time += delta
	
	# 更新旋转菜刀
	base_rotation += rotation_speed * delta
	
	update_knife_positions()
	
	# 更新UI
	update_ui()

# 生成菜刀
func spawn_knives():
	# 清除现有菜刀
	for knife in knives:
		if is_instance_valid(knife):
			knife.queue_free()
	knives.clear()
	
	# 生成新菜刀
	for i in range(knife_count):
		var knife = chef_big_knife.instantiate()
		knife.damage = knife_damage
		knife.knockback_amount = 100  # 恢复到中等值
		knife.scale = knife_scale
		# 直接添加到场景中
		add_child(knife)
		knives.append(knife)
	
	# 更新菜刀位置
	update_knife_positions()

# 更新菜刀位置 - 完全重写
func update_knife_positions():
	for i in range(knives.size()):
		if is_instance_valid(knives[i]):
			# 计算菜刀位置 - 直接使用全局坐标
			var angle = base_rotation + (2 * PI * i / knife_count)
			var offset = Vector2(cos(angle), sin(angle)) * knife_distance
			
			# 直接设置全局位置，确保跟随玩家
			knives[i].global_position = global_position + offset
			
			# 设置菜刀旋转
			knives[i].rotation = angle + PI/2  # 调整菜刀朝向
			
			# 更新菜刀的角度属性
			knives[i].update_angle(global_position)

# 更新UI
func update_ui():
	# 经验条
	expBar.value = experience
	lblLevel.text = "Level: " + str(experience_level)
	
	# 血条
	healthBar.value = hp
	
	# 游戏时间
	var minutes = floor(time / 60)
	var seconds = int(time) % 60
	lblTimer.text = "%02d:%02d" % [minutes, seconds]

# 当受到伤害时调用
func _on_hurt_box_hurt(damage, _angle, _knockback_amount):
	hp -= damage
	if hp <= 0:
		death()

# 死亡处理
func death():
	emit_signal("playerdeath")
	deathPanel.visible = true
	lblResult.text = "You Died"

# 敌人检测区域
func _on_enemy_detection_area_body_entered(body):
	if not enemy_close.has(body):
		enemy_close.append(body)

func _on_enemy_detection_area_body_exited(body):
	if enemy_close.has(body):
		enemy_close.erase(body)

# 升级菜刀
func upgrade_knife():
	knife_count += 1
	spawn_knives()

# 拾取经验
func _on_grab_area_area_entered(area):
	if area.is_in_group("loot"):
		area.target = self

# 收集经验
func _on_collect_area_area_entered(area):
	if area.is_in_group("loot"):
		var gem_experience = area.collect()
		collected_experience += gem_experience
		experience += gem_experience
		
		# 检查是否升级
		var level_up_experience = experience_level * 5
		if experience >= level_up_experience:
			experience -= level_up_experience
			experience_level += 1
			expBar.max_value = experience_level * 5
			
			# 处理升级
			levelPanel.visible = true
			get_tree().paused = true

# 菜单按钮
func _on_btn_menu_click_end():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://title_screen.tscn")

# 调试函数
func _on_knife_body_entered(body):
	print("菜刀击中物体:", body.name, " 组:", body.get_groups())

func _on_knife_area_entered(area):
	print("菜刀进入区域:", area.name, " 组:", area.get_groups())
