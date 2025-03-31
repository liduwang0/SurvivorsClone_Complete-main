extends CharacterBody2D

#region 基本属性
var movement_speed = 100.0
var hp = 80
var maxhp = 80
var last_movement = Vector2.UP
var time = 0
#endregion

#region 经验和等级
var experience = 0
var experience_level = 1
var collected_experience = 0
#endregion

#region 武器预加载
var chef_big_knife = preload("res://Player/Attack/chef_big_knife.tscn")
var chef_knife_small = preload("res://Player/Attack/chef_small_knife.tscn")
var chef_scissor = preload("res://Player/Attack/chef_scissor.tscn")
#endregion

#region 旋转菜刀属性
var knife_count = 2
var knife_distance = 70
var rotation_speed = -2.0
var knife_damage = 1
var knife_scale = Vector2(1, 1)
var base_rotation = 0.0
var knives = []
#endregion

#region 小刀属性
var chef_knife_small_ammo = 0
var chef_knife_small_base_ammo = 3
var chef_knife_small_attack_speed = 1.5
var chef_knife_small_level = 0
var chef_knife_small_timer = 0
#endregion

#region 剪刀属性
var scissors_level = 0
var scissors_ammo = 0
var scissors_base_ammo = 1
var scissors_timer = null
var scissors_attack_speed = 3.0
var scissors_base = null
#endregion

#region 敌人相关
var enemy_close = []
#endregion

#region 节点引用
@onready var sprite = $Sprite2D
@onready var walkTimer = get_node("%walkTimer")

# GUI节点
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
#endregion

#region 信号
signal playerdeath
#endregion

#region 初始化
func _ready():
	# 添加到player组
	add_to_group("player")
	
	# 初始化UI
	initialize_ui()
	
	# 初始化武器
	initialize_weapons()
	
	# 连接升级按钮信号
	for button in upgradeOptions.get_children():
		if button is Button:
			button.pressed.connect(func():
				upgrade_character(button.name.to_lower())
				levelPanel.visible = false
				get_tree().paused = false
			)

func initialize_ui():
	# 设置血条
	healthBar.max_value = maxhp
	healthBar.value = hp
	
	# 设置经验条
	expBar.max_value = experience_level * 5

func initialize_weapons():
	# 初始化旋转菜刀
	spawn_knives()
	
	# 初始化小刀
	if chef_knife_small_level > 0:
		chef_knife_small_ammo = chef_knife_small_base_ammo
	
	# 初始化剪刀
	initialize_scissors()

func initialize_scissors():
	# 创建剪刀基础节点
	scissors_base = Node2D.new()
	scissors_base.name = "ScissorsBase"
	add_child(scissors_base)
	
	# 初始化剪刀计时器
	scissors_timer = Timer.new()
	scissors_timer.wait_time = scissors_attack_speed
	scissors_timer.autostart = false
	scissors_timer.one_shot = false
	add_child(scissors_timer)
	scissors_timer.timeout.connect(Callable(self, "_on_scissors_timer_timeout"))
	
	# 如果已解锁剪刀，启动计时器
	if scissors_level > 0:
		scissors_ammo = scissors_base_ammo
		scissors_timer.start()
#endregion

#region 主循环
func _physics_process(delta):
	# 处理移动
	handle_movement()
	
	# 更新游戏时间
	time += delta
	
	# 更新旋转菜刀
	update_rotating_knives(delta)
	
	# 更新UI
	update_ui()
	
	# 处理小刀攻击
	handle_small_knife_attack(delta)

func handle_movement():
	var direction = Input.get_vector("left", "right", "up", "down")
	if direction.length() > 0:
		velocity = direction.normalized() * movement_speed
		last_movement = direction.normalized()
	else:
		velocity = Vector2.ZERO
	
	move_and_slide()

func update_rotating_knives(delta):
	base_rotation += rotation_speed * delta
	update_knife_positions()

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
		knife.knockback_amount = 100
		knife.scale = knife_scale
		add_child(knife)
		knives.append(knife)
	
	# 更新菜刀位置
	update_knife_positions()

func update_knife_positions():
	for i in range(knives.size()):
		if is_instance_valid(knives[i]):
			# 计算菜刀位置
			var angle = base_rotation + (2 * PI * i / knife_count)
			var offset = Vector2(cos(angle), sin(angle)) * knife_distance
			
			# 设置位置和旋转
			knives[i].global_position = global_position + offset
			knives[i].rotation = angle + PI/2
			
			# 更新菜刀的角度属性
			knives[i].update_angle(global_position)

func upgrade_knife():
	knife_count += 1
	spawn_knives()

func handle_small_knife_attack(delta):
	if chef_knife_small_level > 0:
		chef_knife_small_timer += delta
		if chef_knife_small_timer >= chef_knife_small_attack_speed:
			chef_knife_small_timer = 0
			if chef_knife_small_ammo > 0:
				throw_chef_knife_small()

func throw_chef_knife_small():
	# 减少弹药
	chef_knife_small_ammo -= 1
	
	# 获取目标
	var target_enemy = find_closest_enemy()
	if target_enemy == null:
		# 如果没有敌人，向随机方向投掷
		var random_direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
		spawn_chef_knife_small(global_position, global_position + random_direction * 120)
	else:
		# 向最近的敌人投掷
		spawn_chef_knife_small(global_position, target_enemy.global_position)
	
	# 延迟恢复弹药
	await get_tree().create_timer(chef_knife_small_attack_speed * 2).timeout
	chef_knife_small_ammo += 1

func spawn_chef_knife_small(start_pos, target_pos):
	var knife_instance = chef_knife_small.instantiate()
	knife_instance.position = start_pos
	knife_instance.target = target_pos
	knife_instance.level = chef_knife_small_level
	
	# 连接信号
	knife_instance.connect("remove_from_array", Callable(self, "_on_chef_knife_small_removed"))
	
	# 添加到场景
	get_parent().add_child(knife_instance)

func _on_chef_knife_small_removed(knife):
	# 可以在这里添加额外逻辑
	pass

func upgrade_chef_knife_small():
	chef_knife_small_level += 1
	
	match chef_knife_small_level:
		1:
			chef_knife_small_base_ammo = 3
			chef_knife_small_attack_speed = 1.5
			chef_knife_small_ammo = chef_knife_small_base_ammo
		2:
			chef_knife_small_base_ammo = 4
			chef_knife_small_attack_speed = 1.3
		3:
			chef_knife_small_base_ammo = 5
			chef_knife_small_attack_speed = 1.1
		4:
			chef_knife_small_base_ammo = 6
			chef_knife_small_attack_speed = 0.9
	
	# 更新弹药数量
	chef_knife_small_ammo = min(chef_knife_small_ammo + 1, chef_knife_small_base_ammo)

func _on_scissors_timer_timeout():
	if scissors_level > 0 and scissors_ammo > 0:
		scissors_ammo -= 1
		spawn_scissors()
		
		# 延迟恢复弹药
		var timer = Timer.new()
		timer.wait_time = scissors_attack_speed
		timer.one_shot = true
		timer.autostart = true
		add_child(timer)
		timer.timeout.connect(func(): 
			scissors_ammo = min(scissors_ammo + 1, scissors_base_ammo)
			timer.queue_free()
		)

func spawn_scissors():
	var scissors_attack = chef_scissor.instantiate()
	scissors_attack.position = position
	scissors_attack.level = scissors_level
	scissors_attack.target_array = get_scissors_targets()
	scissors_attack.connect("remove_from_array", Callable(self, "_on_scissors_removed"))
	scissors_base.add_child(scissors_attack)

func get_scissors_targets():
	var targets = []
	
	# 获取所有敌人
	var enemies = get_tree().get_nodes_in_group("enemy")
	if enemies.size() > 0:
		# 按距离排序
		var sorted_enemies = []
		for enemy in enemies:
			if is_instance_valid(enemy):
				sorted_enemies.append({"enemy": enemy, "distance": self.position.distance_to(enemy.position)})
		
		# 排序
		sorted_enemies.sort_custom(func(a, b): return a.distance < b.distance)
		
		# 获取最近的几个敌人
		var target_count = min(scissors_level + 1, sorted_enemies.size())
		for i in range(target_count):
			if i < sorted_enemies.size():
				targets.append(sorted_enemies[i].enemy)
	
	return targets

func _on_scissors_removed(scissors):
	if scissors_ammo < scissors_base_ammo:
		# 如果弹药未满，生成新的剪刀
		var timer = Timer.new()
		timer.wait_time = 0.1
		timer.one_shot = true
		timer.autostart = true
		add_child(timer)
		timer.timeout.connect(func():
			if scissors_timer and !scissors_timer.is_stopped():
				spawn_scissors()
			timer.queue_free()
		)

func upgrade_scissors():
	scissors_level += 1
	
	match scissors_level:
		1:
			scissors_base_ammo = 1
			scissors_attack_speed = 3.0
			scissors_ammo = scissors_base_ammo
			scissors_timer.wait_time = scissors_attack_speed
			scissors_timer.start()
		2:
			scissors_base_ammo = 2
			scissors_attack_speed = 2.8
			scissors_timer.wait_time = scissors_attack_speed
		3:
			scissors_base_ammo = 2
			scissors_attack_speed = 2.6
			scissors_timer.wait_time = scissors_attack_speed
		4:
			scissors_base_ammo = 3
			scissors_attack_speed = 2.4
			scissors_timer.wait_time = scissors_attack_speed
	
	# 更新弹药数量
	scissors_ammo = min(scissors_ammo + 1, scissors_base_ammo)

func find_closest_enemy():
	# 如果已有enemy_close数组，直接使用
	if enemy_close.size() > 0:
		var closest_enemy = null
		var closest_distance = 100000
		
		for enemy in enemy_close:
			if is_instance_valid(enemy):
				var distance = global_position.distance_to(enemy.global_position)
				if distance < closest_distance:
					closest_distance = distance
					closest_enemy = enemy
		
		return closest_enemy
	
	# 如果没有enemy_close数组，获取所有敌人
	var enemies = get_tree().get_nodes_in_group("enemy")
	if enemies.size() == 0:
		return null
	
	# 查找最近的敌人
	var closest_enemy = null
	var closest_distance = 100000
	
	for enemy in enemies:
		var distance = global_position.distance_to(enemy.global_position)
		if distance < closest_distance:
			closest_distance = distance
			closest_enemy = enemy
	
	return closest_enemy

func _on_enemy_detection_area_body_entered(body):
	if not enemy_close.has(body):
		enemy_close.append(body)

func _on_enemy_detection_area_body_exited(body):
	if enemy_close.has(body):
		enemy_close.erase(body)

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

func _on_hurt_box_hurt(damage, _angle, _knockback_amount):
	hp -= damage
	if hp <= 0:
		death()

func death():
	emit_signal("playerdeath")
	deathPanel.visible = true
	lblResult.text = "You Died"

func _on_grab_area_area_entered(area):
	if area.is_in_group("loot"):
		area.target = self

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
			
			# 显示升级选项
			show_upgrade_options()

func show_upgrade_options():
	# 清除现有选项
	for child in upgradeOptions.get_children():
		if child.is_in_group("upgrade_option"):
			child.queue_free()
	
	# 获取可用升级
	var available_upgrades = get_available_upgrades()
	
	# 创建升级选项按钮
	for i in range(min(3, available_upgrades.size())):
		var upgrade = available_upgrades[i]
		
		# 创建按钮
		var button = Button.new()
		button.text = upgrade.name
		button.tooltip_text = upgrade.description
		button.add_to_group("upgrade_option")
		
		# 连接点击事件
		button.pressed.connect(func(): 
			apply_upgrade(upgrade.id)
			levelPanel.visible = false
			get_tree().paused = false
		)
		
		# 添加到选项容器
		upgradeOptions.add_child(button)
	
	# 显示升级面板
	levelPanel.visible = true
	get_tree().paused = true

func get_available_upgrades():
	var upgrades = []
	
	# 旋转菜刀升级
	if knife_count < 4:
		upgrades.append({
			"id": "knife" + str(knife_count + 1),
			"name": "旋转菜刀 " + str(knife_count + 1),
			"description": "增加一把旋转菜刀",
			"icon": preload("res://Textures/Items/Weapons/knife_small.png")
		})
	
	# 小刀升级
	if chef_knife_small_level < 4:
		upgrades.append({
			"id": "smallknife" + str(chef_knife_small_level + 1),
			"name": "投掷小刀 " + str(chef_knife_small_level + 1),
			"description": "提升投掷小刀能力",
			"icon": preload("res://Textures/Items/Weapons/knife_small.png")
		})
	
	# 剪刀升级
	if scissors_level < 4:
		upgrades.append({
			"id": "scissors" + str(scissors_level + 1),
			"name": "剪刀 " + str(scissors_level + 1),
			"description": "提升剪刀攻击能力",
			"icon": preload("res://Textures/Items/Weapons/knife_small.png")
		})
	
	# 随机选择3个升级选项
	upgrades.shuffle()
	return upgrades.slice(0, min(3, upgrades.size()))

func apply_upgrade(upgrade_id):
	match upgrade_id:
		"knife1", "knife2", "knife3", "knife4":
			upgrade_knife()
			# 添加到已收集武器
			add_collected_weapon("knife", knife_count)
		
		"smallknife1", "smallknife2", "smallknife3", "smallknife4":
			upgrade_chef_knife_small()
			# 添加到已收集武器
			add_collected_weapon("smallknife", chef_knife_small_level)
		
		"scissors1", "scissors2", "scissors3", "scissors4":
			upgrade_scissors()
			# 添加到已收集武器
			add_collected_weapon("scissors", scissors_level)
		
		_:
			print("未知升级选项:", upgrade_id)

func add_collected_weapon(weapon_type, level):
	# 创建武器图标
	var icon = TextureRect.new()
	
	# 设置图标纹理
	match weapon_type:
		"knife":
			icon.texture = preload("res://Textures/Items/Weapons/knife_small.png")
		"smallknife":
			icon.texture = preload("res://Textures/Items/Weapons/knife_small.png")
		"scissors":
			icon.texture = preload("res://Textures/Items/Weapons/knife_small.png")
	
	# 设置图标属性
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(24, 24)
	
	# 添加等级标签
	var label = Label.new()
	label.text = str(level)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon.add_child(label)
	
	# 添加到已收集武器面板
	collectedWeapons.add_child(icon)

func _on_knife_body_entered(body):
	print("菜刀击中物体:", body.name, " 组:", body.get_groups())

func _on_knife_area_entered(area):
	print("菜刀进入区域:", area.name, " 组:", area.get_groups())

func _on_btn_menu_click_end():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://title_screen.tscn")

func _on_chef_knife_small_attack_timer_timeout() -> void:
	pass

func _on_chef_knife_small_timer_timeout() -> void:
	if chef_knife_small_level > 0 and chef_knife_small_ammo > 0:
		throw_chef_knife_small()

func _input(event):
	# ... 其他输入处理代码 ...
	
	# 紧急恢复 - 按ESC键恢复游戏
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if get_tree().paused:
			print("紧急恢复游戏")
			levelPanel.visible = false
			get_tree().paused = false

# 处理升级选择
func upgrade_character(upgrade):
	print("选择升级:", upgrade)  # 调试输出
	
	match upgrade:
		# 旋转菜刀升级
		"knife1", "knife2", "knife3", "knife4":
			upgrade_knife()
			print("升级旋转菜刀到等级", knife_count)
		
		# 小刀升级
		"smallknife1", "smallknife2", "smallknife3", "smallknife4":
			upgrade_chef_knife_small()
			print("升级小刀到等级", chef_knife_small_level)
		
		# 剪刀升级
		"scissors1", "scissors2", "scissors3", "scissors4":
			upgrade_scissors()
			print("升级剪刀到等级", scissors_level)
		
		# 其他可能的升级选项
		"health1", "health2", "health3":
			upgrade_health()
		
		"speed1", "speed2", "speed3":
			upgrade_speed()
		
		"armor1", "armor2", "armor3":
			upgrade_armor()
		
		_:
			print("未知升级选项:", upgrade)
	
	# 更新UI显示
	update_weapon_display()
	
	# 关闭升级面板并恢复游戏
	levelPanel.visible = false
	get_tree().paused = false

# 更新武器显示
func update_weapon_display():
	# 清除现有显示
	for child in collectedWeapons.get_children():
		child.queue_free()
	
	# 显示旋转菜刀
	if knife_count > 0:
		add_weapon_icon("knife", knife_count)
	
	# 显示小刀
	if chef_knife_small_level > 0:
		add_weapon_icon("smallknife", chef_knife_small_level)
	
	# 显示剪刀
	if scissors_level > 0:
		add_weapon_icon("scissors", scissors_level)

# 添加武器图标
func add_weapon_icon(weapon_type, level):
	var container = HBoxContainer.new()
	
	# 创建图标
	var icon = TextureRect.new()
	
	# 根据武器类型设置图标
	match weapon_type:
		"knife":
			# 使用您的实际图标路径
			var texture = preload("res://Textures/Items/Weapons/knife_big.png") if ResourceLoader.exists("res://Textures/Items/Weapons/knife_big.png") else null
			icon.texture = texture
		"smallknife":
			var texture = preload("res://Textures/Items/Weapons/knife_big.png") if ResourceLoader.exists("res://Textures/Items/Weapons/knife_big.png") else null
			icon.texture = texture
		"scissors":
			var texture = preload("res://Textures/Items/Weapons/knife_big.png") if ResourceLoader.exists("res://Textures/Items/Weapons/knife_big.png") else null
			icon.texture = texture
	
	# 如果没有图标，使用占位符
	if icon.texture == null:
		# 创建一个彩色矩形作为占位符
		var placeholder = ColorRect.new()
		placeholder.custom_minimum_size = Vector2(24, 24)
		match weapon_type:
			"knife":
				placeholder.color = Color(1, 0, 0)  # 红色
			"smallknife":
				placeholder.color = Color(0, 1, 0)  # 绿色
			"scissors":
				placeholder.color = Color(0, 0, 1)  # 蓝色
		container.add_child(placeholder)
	else:
		# 设置图标属性
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = Vector2(24, 24)
		container.add_child(icon)
	
	# 添加等级标签
	var label = Label.new()
	label.text = str(level)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	container.add_child(label)
	
	# 添加到已收集武器面板
	collectedWeapons.add_child(container)

# 升级生命值
func upgrade_health():
	maxhp += 20
	hp = maxhp
	healthBar.max_value = maxhp
	healthBar.value = hp
	print("升级生命值到", maxhp)

# 升级移动速度
func upgrade_speed():
	movement_speed += 20.0
	print("升级移动速度到", movement_speed)

# 升级护甲（减伤）
func upgrade_armor():
	# 如果您有护甲系统，在这里实现
	print("升级护甲")
