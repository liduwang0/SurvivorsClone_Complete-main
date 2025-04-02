extends CharacterBody2D


var movement_speed = 100.0
var hp = 800
var maxhp = 800
var last_movement = Vector2.UP
var time = 0

var experience = 0
var experience_level = 1
var collected_experience = 0

#Attacks
var chef_small_knife = preload("res://Player/Attack/chef_small_knife.tscn")
var chef_rolling_pin = preload("res://Player/Attack/chef_rolling_pin.tscn")
var chef_scissor = preload("res://Player/Attack/chef_scissor.tscn")
var chef_big_knife = preload("res://Player/Attack/chef_big_knife.tscn")
var chef_pan = preload("res://Player/Attack/chef_pan.tscn")

#AttackNodes
@onready var chef_small_knife_timer = get_node("%chef_small_knifeTimer")
@onready var chef_small_knife_attack_timer = get_node("%chef_small_knifeAttackTimer")
@onready var chef_rolling_pin_timer = get_node("%chef_rolling_pinTimer")
@onready var chef_rolling_pin_attack_timer = get_node("%chef_rolling_pinAttackTimer")
@onready var chef_scissor_base = get_node("%chef_scissorBase")

#UPGRADES
var collected_upgrades = []
var upgrade_options = []
var armor = 0
var speed = 0
var spell_cooldown = 0
var spell_size = 0
var additional_attacks = 0

#chef_small_knife
var chef_small_knife_level = 0
var chef_small_knife_baseammo = 1
var chef_small_knife_ammo = 0
var chef_small_knife_attackspeed = 1.5

#chef_pan
var chef_pan_level = 0  # 修改初始值为0
var chef_pan_baseammo = 1
var chef_pan_ammo = 0
var chef_pan_attackspeed = 4
var chef_pan_timer = 0.0
@onready var chef_pan_base = get_node("%chef_panBase")  # 如果使用场景中的节点
#var chef_panBase: Node2D  # 如果要动态创建

#chef_rolling_pin
var chef_rolling_pin_level = 0
var chef_rolling_pin_baseammo = 1
var chef_rolling_pin_ammo = 0
var chef_rolling_pin_attackspeed = 3

#chef_scissor
var chef_scissor_level = 0
var chef_scissor_baseammo = 1
var chef_scissor_ammo = 0
var chef_scissor_attackspeed = 2

# 旋转菜刀相关属性
var knife_count = 0
var knife_distance = 70
var rotation_speed = -2.0
var knife_damage = 1
var knife_scale = Vector2(1, 1)
var base_rotation = 0.0
var knives = []
var chef_big_knife_level = 0


#Enemy Related
var enemy_close = []


@onready var sprite = $Sprite2D
@onready var walkTimer = get_node("%walkTimer")

#GUI
@onready var expBar = get_node("%ExperienceBar")
@onready var lblLevel = get_node("%lbl_level")
@onready var levelPanel = get_node("%LevelUp")
@onready var upgradeOptions = get_node("%UpgradeOptions")
@onready var itemOptions = preload("res://Utility/item_option.tscn")
@onready var sndLevelUp = get_node("%snd_levelup")
@onready var healthBar = get_node("%HealthBar")
@onready var lblTimer = get_node("%lblTimer")
@onready var collectedWeapons = get_node("%CollectedWeapons")
@onready var collectedUpgrades = get_node("%CollectedUpgrades")
@onready var itemContainer = preload("res://Player/GUI/item_container.tscn")

@onready var deathPanel = get_node("%DeathPanel")
@onready var lblResult = get_node("%lbl_Result")
@onready var sndVictory = get_node("%snd_victory")
@onready var sndLose = get_node("%snd_lose")

#Signal
signal playerdeath

func spawn_chef_pan():
	# 获取当前平底锅数量
	var current_pans = chef_pan_base.get_child_count()
	
	# 计算需要生成的平底锅数量（加上戒指效果）
	var pans_to_spawn = (chef_pan_ammo + additional_attacks) - current_pans
	
	# 同时生成多个平底锅
	while pans_to_spawn > 0:
		var chef_pan_spawn = chef_pan.instantiate()
		chef_pan_spawn.global_position = global_position
		chef_pan_base.add_child(chef_pan_spawn)
		pans_to_spawn -= 1

func _ready():
	#upgrade_character("chef_small_knife1")
	# 添加这一行来测试擀面杖
	upgrade_character("chef_rolling_pin1")
	#upgrade_character("chef_pan1")
	attack()
	set_expbar(experience, calculate_experiencecap())
	_on_hurt_box_hurt(0,0,0)
	if chef_big_knife_level > 0:
		initialize_rotating_knives()
	
	
	# 确保擀面杖初始弹药为0
	chef_rolling_pin_ammo = 0

func _physics_process(delta):
	movement()
	if chef_big_knife_level > 0:
		update_rotating_knives()
	
	# Pan weapon update
	if chef_pan_level > 0:
		chef_pan_timer += delta
		if chef_pan_timer >= chef_pan_attackspeed * (1-spell_cooldown):
			chef_pan_timer = 0
			if chef_pan_ammo > 0:
				spawn_chef_pan()
	
	# 添加擀面杖处理逻辑
	if chef_rolling_pin_level > 0:
		# 确保计时器已启动
		if chef_rolling_pin_timer and chef_rolling_pin_timer.is_stopped():
			chef_rolling_pin_timer.start()

func _process(delta):
	# 如果有旋转刀，更新它们的位置
	if knife_count + additional_attacks > 0:
		update_rotating_knives()

func movement():
	var x_mov = Input.get_action_strength("right") - Input.get_action_strength("left")
	var y_mov = Input.get_action_strength("down") - Input.get_action_strength("up")
	var mov = Vector2(x_mov,y_mov)
	if mov.x > 0:
		sprite.flip_h = true
	elif mov.x < 0:
		sprite.flip_h = false

	if mov != Vector2.ZERO:
		last_movement = mov
		if walkTimer.is_stopped():
			if sprite.frame >= sprite.hframes - 1:
				sprite.frame = 0
			else:
				sprite.frame += 1
			walkTimer.start()
	
	velocity = mov.normalized()*movement_speed
	move_and_slide()

func attack():
	# 小刀攻击
	if chef_small_knife_level > 0 and chef_small_knife_timer:
		chef_small_knife_timer.wait_time = chef_small_knife_attackspeed * (1-spell_cooldown)
		if chef_small_knife_timer.is_stopped():
			chef_small_knife_timer.start()
	
	# 擀面杖攻击
	if chef_rolling_pin_level > 0 and chef_rolling_pin_timer:
		chef_rolling_pin_timer.wait_time = chef_rolling_pin_attackspeed * (1-spell_cooldown)
		if chef_rolling_pin_timer.is_stopped():
			chef_rolling_pin_timer.start()
	
	# 剪刀攻击 - 添加计时器逻辑
	if chef_scissor_level > 0:
		# 这里可以考虑添加计时器，或保持直接生成
		spawn_chef_scissor()
	
	# 平底锅攻击 - 添加计时器逻辑
	if chef_pan_level > 0:
		spawn_chef_pan()
	
	# 大刀攻击 - 在这里处理
	if chef_big_knife_level > 0:
		update_rotating_knives()

func _on_hurt_box_hurt(damage, _angle, _knockback):
	hp -= clamp(damage-armor, 1.0, 999.0)
	healthBar.max_value = maxhp
	healthBar.value = hp
	if hp <= 0:
		death()

func _on_chef_small_knife_timer_timeout():
	chef_small_knife_ammo += chef_small_knife_baseammo + additional_attacks
	chef_small_knife_attack_timer.start()

func _on_chef_small_knife_attack_timer_timeout():
	if chef_small_knife_ammo > 0:
		var chef_small_knife_attack = chef_small_knife.instantiate()
		chef_small_knife_attack.position = position
		chef_small_knife_attack.target = get_random_target()
		chef_small_knife_attack.level = chef_small_knife_level
		add_child(chef_small_knife_attack)
		chef_small_knife_ammo -= 1
		if chef_small_knife_ammo > 0:
			chef_small_knife_attack_timer.start()
		else:
			chef_small_knife_attack_timer.stop()

func _on_chef_rolling_pin_timer_timeout():
	# 基础弹药 + 额外攻击
	chef_rolling_pin_ammo += chef_rolling_pin_baseammo + additional_attacks
	chef_rolling_pin_attack_timer.start()
	
	# 打印当前弹药数量，用于调试
	print("擀面杖计时器触发，当前弹药:", chef_rolling_pin_ammo)

func _on_chef_rolling_pin_attack_timer_timeout():
	if chef_rolling_pin_ammo > 0:
		# 打印当前弹药数量，用于调试
		print("擀面杖攻击计时器触发，当前弹药:", chef_rolling_pin_ammo)
		
		# 确保last_movement不为零向量
		var attack_direction = last_movement
		if attack_direction == Vector2.ZERO:
			attack_direction = Vector2.RIGHT
		
		# 生成擀面杖
		var chef_rolling_pin_attack = chef_rolling_pin.instantiate()
		chef_rolling_pin_attack.position = position
		chef_rolling_pin_attack.angle = attack_direction
		add_child(chef_rolling_pin_attack)
		
		# 减少弹药
		chef_rolling_pin_ammo -= 1
		
		# 如果还有弹药，继续计时器
		if chef_rolling_pin_ammo > 0:
			chef_rolling_pin_attack_timer.start()
		else:
			chef_rolling_pin_attack_timer.stop()

func spawn_chef_scissor():
	# 获取现有剪刀数量
	var get_scissor_total = chef_scissor_base.get_child_count()
	print("现有剪刀数量:", get_scissor_total)
	
	# 计算需要添加的剪刀数量
	var calc_spawns = (chef_scissor_ammo + additional_attacks) - get_scissor_total
	print("需要添加的剪刀数量:", calc_spawns)
	
	# 只添加新的剪刀，不清除现有的
	while calc_spawns > 0:
		var chef_scissor_spawn = chef_scissor.instantiate()
		chef_scissor_spawn.global_position = global_position
		chef_scissor_base.add_child(chef_scissor_spawn)
		calc_spawns -= 1
	
	# 更新所有剪刀
	var get_scissors = chef_scissor_base.get_children()
	for i in get_scissors:
		# 直接设置剪刀的等级
		i.level = chef_scissor_level
		
		# 根据等级设置路径数量
		match chef_scissor_level:
			1:
				i.paths = 1
			2:
				i.paths = 2
			3:
				i.paths = 3
			4:
				i.paths = 3
		
		# 如果有update_chef_scissor方法，也调用它
		if i.has_method("update_chef_scissor"):
			i.update_chef_scissor()
		
		# 打印调试信息
		print("更新剪刀 - 等级:", chef_scissor_level)
		if i.get("paths") != null:
			print("剪刀路径数:", i.paths)

func get_random_target():
	if enemy_close.size() > 0:
		return enemy_close.pick_random().global_position
	else:
		return Vector2.UP


func _on_enemy_detection_area_body_entered(body):
	if not enemy_close.has(body):
		enemy_close.append(body)

func _on_enemy_detection_area_body_exited(body):
	if enemy_close.has(body):
		enemy_close.erase(body)


func _on_grab_area_area_entered(area):
	if area.is_in_group("loot"):
		area.target = self

func _on_collect_area_area_entered(area):
	if area.is_in_group("loot"):
		var gem_exp = area.collect()
		calculate_experience(gem_exp)

func calculate_experience(gem_exp):
	var exp_required = calculate_experiencecap()
	collected_experience += gem_exp
	if experience + collected_experience >= exp_required: #level up
		collected_experience -= exp_required-experience
		experience_level += 1
		experience = 0
		exp_required = calculate_experiencecap()
		levelup()
	else:
		experience += collected_experience
		collected_experience = 0
	
	set_expbar(experience, exp_required)

func calculate_experiencecap():
	var exp_cap = experience_level
	if experience_level < 20:
		exp_cap = experience_level*5
	elif experience_level < 40:
		exp_cap + 95 * (experience_level-19)*8
	else:
		exp_cap = 255 + (experience_level-39)*12
		
	return exp_cap
		
func set_expbar(set_value = 1, set_max_value = 100):
	expBar.value = set_value
	expBar.max_value = set_max_value

func levelup():
	sndLevelUp.play()
	lblLevel.text = str("Level: ",experience_level)
	var tween = levelPanel.create_tween()
	tween.tween_property(levelPanel,"position",Vector2(220,50),0.2).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN)
	tween.play()
	levelPanel.visible = true
	var options = 0
	var optionsmax = 3
	while options < optionsmax:
		var option_choice = itemOptions.instantiate()
		option_choice.item = get_random_item()
		upgradeOptions.add_child(option_choice)
		options += 1
	get_tree().paused = true

func upgrade_character(upgrade):
	match upgrade:
		
		"chef_pan1":
			upgrade_chef_pan(1)
		"chef_pan2":
			upgrade_chef_pan(2)
		"chef_pan3":
			upgrade_chef_pan(3)
		"chef_pan4":
			upgrade_chef_pan(4)
		"chef_small_knife1":
			upgrade_chef_small_knife(1)
		"chef_small_knife2":
			upgrade_chef_small_knife(2)
		"chef_small_knife3":
			upgrade_chef_small_knife(3)
		"chef_small_knife4":
			upgrade_chef_small_knife(4)
		"chef_rolling_pin1":
			upgrade_chef_rolling_pin(1)
		"chef_rolling_pin2":
			upgrade_chef_rolling_pin(2)
		"chef_rolling_pin3":
			upgrade_chef_rolling_pin(3)
		"chef_rolling_pin4":
			upgrade_chef_rolling_pin(4)
		"chef_scissor1":
			upgrade_chef_scissor(1)
		"chef_scissor2":
			upgrade_chef_scissor(2)
		"chef_scissor3":
			upgrade_chef_scissor(3)
		"chef_scissor4":
			upgrade_chef_scissor(4)
		"armor1","armor2","armor3","armor4":
			armor += 1
		"speed1","speed2","speed3","speed4":
			movement_speed += 20.0
		"tome1","tome2","tome3","tome4":
			spell_size += 0.10
		"scroll1","scroll2","scroll3","scroll4":
			spell_cooldown += 0.05
		"ring1","ring2":
			additional_attacks += 1
			if chef_big_knife_level > 0:
				initialize_rotating_knives()
		"food":
			hp += 20
			hp = clamp(hp,0,maxhp)
		"chef_big_knife1":
			chef_big_knife_level = 1
			knife_count = 2
			knife_damage = 1
			knife_distance = 70
			rotation_speed = -0.6
			initialize_rotating_knives()
		"chef_big_knife2":
			chef_big_knife_level = 2
			knife_count = 3
			knife_damage = 2
			knife_distance = 80
			rotation_speed = -0.7
			initialize_rotating_knives()
		"chef_big_knife3":
			chef_big_knife_level = 3
			knife_count = 4
			knife_damage = 3
			knife_distance = 90
			rotation_speed = -0.8
			initialize_rotating_knives()
		"chef_big_knife4":
			chef_big_knife_level = 4
			knife_count = 5
			knife_damage = 4
			knife_distance = 100
			rotation_speed = -0.9
			initialize_rotating_knives()
		"chef_rolling_pin1", "chef_rolling_pin2", "chef_rolling_pin3", "chef_rolling_pin4":
			upgrade_chef_rolling_pin(chef_rolling_pin_level + 1)
	adjust_gui_collection(upgrade)
	attack()
	var option_children = upgradeOptions.get_children()
	for i in option_children:
		i.queue_free()
	upgrade_options.clear()
	collected_upgrades.append(upgrade)
	levelPanel.visible = false
	levelPanel.position = Vector2(800,50)
	get_tree().paused = false
	calculate_experience(0)
	
func get_random_item():
	var dblist = []
	for i in UpgradeDb.UPGRADES:
		if i in collected_upgrades: #Find already collected upgrades
			pass
		elif i in upgrade_options: #If the upgrade is already an option
			pass
		elif UpgradeDb.UPGRADES[i]["type"] == "item": #Don't pick food
			pass
		elif UpgradeDb.UPGRADES[i]["prerequisite"].size() > 0: #Check for PreRequisites
			var to_add = true
			for n in UpgradeDb.UPGRADES[i]["prerequisite"]:
				if not n in collected_upgrades:
					to_add = false
			if to_add:
				dblist.append(i)
		else:
			dblist.append(i)
	if dblist.size() > 0:
		var randomitem = dblist.pick_random()
		upgrade_options.append(randomitem)
		return randomitem
	else:
		return null

func change_time(argtime = 0):
	time = argtime
	var get_m = int(time/60.0)
	var get_s = time % 60
	if get_m < 10:
		get_m = str(0,get_m)
	if get_s < 10:
		get_s = str(0,get_s)
	lblTimer.text = str(get_m,":",get_s)

func adjust_gui_collection(upgrade):
	var get_upgraded_displayname = UpgradeDb.UPGRADES[upgrade]["displayname"]
	var get_type = UpgradeDb.UPGRADES[upgrade]["type"]
	if get_type != "item":
		var get_collected_displaynames = []
		for i in collected_upgrades:
			get_collected_displaynames.append(UpgradeDb.UPGRADES[i]["displayname"])
		if not get_upgraded_displayname in get_collected_displaynames:
			var new_item = itemContainer.instantiate()
			new_item.upgrade = upgrade
			match get_type:
				"weapon":
					collectedWeapons.add_child(new_item)
				"upgrade":
					collectedUpgrades.add_child(new_item)

func death():
	deathPanel.visible = true
	emit_signal("playerdeath")
	get_tree().paused = true
	var tween = deathPanel.create_tween()
	tween.tween_property(deathPanel,"position",Vector2(220,50),3.0).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	tween.play()
	if time >= 300:
		lblResult.text = "You Win"
		sndVictory.play()
	else:
		lblResult.text = "You Lose"
		sndLose.play()


func _on_btn_menu_click_end():
	get_tree().paused = false
	var _level = get_tree().change_scene_to_file("res://TitleScreen/menu.tscn")

# 旋转大刀相关函数
func initialize_rotating_knives():
	# 清除现有的刀
	for knife in knives:
		if is_instance_valid(knife):
			knife.queue_free()
	knives.clear()
	
	# 计算总刀数，包括额外攻击
	var total_knives = knife_count + additional_attacks
	
	# 创建新的旋转刀
	for i in range(total_knives):
		var knife_instance = chef_big_knife.instantiate()
		knife_instance.global_position = global_position
		knife_instance.damage = knife_damage
		knife_instance.scale = knife_scale
		
		# 修复Sprite2D帧索引问题
		if knife_instance.has_node("Sprite2D"):
			var sprite = knife_instance.get_node("Sprite2D")
			sprite.frame = 0  # 设置为第一帧
		
		add_child(knife_instance)
		knives.append(knife_instance)
	
	# 立即更新刀的位置
	update_rotating_knives()

func update_rotating_knives():
	var total_knives = knife_count + additional_attacks
	var angle_step = 2 * PI / total_knives
	base_rotation += rotation_speed * get_process_delta_time()
	
	for i in range(total_knives):
		if i < knives.size() and is_instance_valid(knives[i]):
			var knife = knives[i]
			var angle = base_rotation + i * angle_step
			var offset = Vector2(cos(angle), sin(angle)) * knife_distance
			knife.global_position = global_position + offset
			
			# 设置刀具旋转
			knife.rotation = angle + PI  # 刀柄朝向玩家
			
			# 必须调用 update_angle 更新击退方向
			if knife.has_method("update_angle"):
				knife.update_angle(global_position)
				print("在 player_test.gd 中调用 update_angle")

func upgrade_chef_small_knife(target_level):
	# 设置等级
	chef_small_knife_level = target_level
	
	# 根据等级设置属性
	match chef_small_knife_level:
		1:
			chef_small_knife_baseammo = 2  # 1 + 1
			chef_small_knife_attackspeed = 1.5
		2:
			chef_small_knife_baseammo = 3  # 2 + 1
			chef_small_knife_attackspeed = 1.4
		3:
			chef_small_knife_baseammo = 3  # 保持不变
			chef_small_knife_attackspeed = 1.3
		4:
			chef_small_knife_baseammo = 5  # 3 + 2
			chef_small_knife_attackspeed = 1.2
	
	# 更新弹药和计时器
	chef_small_knife_ammo = chef_small_knife_baseammo + additional_attacks
	if chef_small_knife_timer:
		chef_small_knife_timer.wait_time = chef_small_knife_attackspeed * (1-spell_cooldown)

func upgrade_chef_rolling_pin(target_level):
	# 设置等级
	chef_rolling_pin_level = target_level
	
	# 根据等级设置属性
	match chef_rolling_pin_level:
		1:
			chef_rolling_pin_baseammo = 1
			chef_rolling_pin_attackspeed = 3.0
		2:
			chef_rolling_pin_baseammo = 2
			chef_rolling_pin_attackspeed = 2.5
		3:
			chef_rolling_pin_baseammo = 3
			chef_rolling_pin_attackspeed = 2.0
		4:
			chef_rolling_pin_baseammo = 4
			chef_rolling_pin_attackspeed = 1.5
	
	# 应用戒指效果
	chef_rolling_pin_ammo = chef_rolling_pin_baseammo + additional_attacks
	
	# 确保计时器使用新的攻击速度
	if chef_rolling_pin_timer:
		chef_rolling_pin_timer.wait_time = chef_rolling_pin_attackspeed * (1-spell_cooldown)

func upgrade_chef_pan(target_level):
	# 设置等级
	chef_pan_level = target_level
	
	# 根据等级设置属性
	match chef_pan_level:
		1:
			chef_pan_baseammo = 1
			chef_pan_attackspeed = 4.0
		2:
			chef_pan_baseammo = 2
			chef_pan_attackspeed = 3.8
		3:
			chef_pan_baseammo = 3
			chef_pan_attackspeed = 3.2  # 4.0 * 0.8
		4:
			chef_pan_baseammo = 4
			chef_pan_attackspeed = 3.0
	
	# 应用戒指效果
	chef_pan_ammo = chef_pan_baseammo + additional_attacks

func upgrade_chef_scissor(target_level):
	# 设置等级
	chef_scissor_level = target_level
	
	# 根据等级设置属性
	match chef_scissor_level:
		1:
			chef_scissor_baseammo = 1
			chef_scissor_attackspeed = 2.0
		2:
			chef_scissor_baseammo = 1
			chef_scissor_attackspeed = 1.8
		3:
			chef_scissor_baseammo = 2
			chef_scissor_attackspeed = 1.6
		4:
			chef_scissor_baseammo = 2
			chef_scissor_attackspeed = 1.4
	
	# 应用戒指效果
	chef_scissor_ammo = chef_scissor_baseammo + additional_attacks

func upgrade_chef_big_knife(target_level):
	# 设置等级
	chef_big_knife_level = target_level
	
	# 根据等级设置属性
	match chef_big_knife_level:
		1:
			knife_count = 2
			knife_damage = 1
			knife_distance = 70
			rotation_speed = -0.6
		2:
			knife_count = 3
			knife_damage = 1.5
			knife_distance = 80
			rotation_speed = -0.7
		3:
			knife_count = 4
			knife_damage = 2
			knife_distance = 90
			rotation_speed = -0.8
		4:
			knife_count = 5
			knife_damage = 2.5
			knife_distance = 100
			rotation_speed = -0.9
	
	# 初始化旋转刀
	initialize_rotating_knives()
