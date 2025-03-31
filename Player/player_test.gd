extends CharacterBody2D


var movement_speed = 100.0
var hp = 800
var maxhp = 80
var last_movement = Vector2.UP
var time = 0

var experience = 0
var experience_level = 1
var collected_experience = 0

#Attacks
var chef_small_knife = preload("res://Player/Attack/chef_small_knife.tscn")
var tornado = preload("res://Player/Attack/tornado.tscn")
var chef_scissor = preload("res://Player/Attack/chef_scissor.tscn")
var chef_big_knife = preload("res://Player/Attack/chef_big_knife.tscn")

#AttackNodes
@onready var chef_small_knifeTimer = get_node("%chef_small_knifeTimer")
@onready var chef_small_knifeAttackTimer = get_node("%chef_small_knifeAttackTimer")
@onready var tornadoTimer = get_node("%TornadoTimer")
@onready var tornadoAttackTimer = get_node("%TornadoAttackTimer")
@onready var chef_scissorBase = get_node("%chef_scissorBase")

#UPGRADES
var collected_upgrades = []
var upgrade_options = []
var armor = 0
var speed = 0
var spell_cooldown = 0
var spell_size = 0
var additional_attacks = 0

#chef_small_knife
var chef_small_knife_ammo = 0
var chef_small_knife_baseammo = 0
var chef_small_knife_attackspeed = 1.5
var chef_small_knife_level = 0

#Tornado
var tornado_ammo = 0
var tornado_baseammo = 0
var tornado_attackspeed = 3
var tornado_level = 0

#chef_scissor
var chef_scissor_ammo = 0
var chef_scissor_level = 0
var scissor_level = 0

# 旋转菜刀相关属性
var knife_count = 5
var knife_distance = 70
var rotation_speed = -2.0
var knife_damage = 1
var knife_scale = Vector2(1, 1)
var base_rotation = 0.0
var knives = []
var chef_big_knife_level = 1


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



func _ready():
	upgrade_character("chef_small_knife1")
	attack()
	set_expbar(experience, calculate_experiencecap())
	_on_hurt_box_hurt(0,0,0)
	if chef_big_knife_level > 0:
		initialize_rotating_knives()

func _physics_process(delta):
	movement()
	if chef_big_knife_level > 0:
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
	if chef_small_knife_level > 0:
		chef_small_knifeTimer.wait_time = chef_small_knife_attackspeed * (1-spell_cooldown)
		if chef_small_knifeTimer.is_stopped():
			chef_small_knifeTimer.start()
	if tornado_level > 0:
		tornadoTimer.wait_time = tornado_attackspeed * (1-spell_cooldown)
		if tornadoTimer.is_stopped():
			tornadoTimer.start()
	if chef_scissor_level > 0:
		spawn_chef_scissor()

func _on_hurt_box_hurt(damage, _angle, _knockback):
	hp -= clamp(damage-armor, 1.0, 999.0)
	healthBar.max_value = maxhp
	healthBar.value = hp
	if hp <= 0:
		death()

func _on_ice_spear_timer_timeout():
	chef_small_knife_ammo += chef_small_knife_baseammo + additional_attacks
	chef_small_knifeAttackTimer.start()


func _on_ice_spear_attack_timer_timeout():
	if chef_small_knife_ammo > 0:
		var chef_small_knife_attack = chef_small_knife.instantiate()
		chef_small_knife_attack.position = position
		chef_small_knife_attack.target = get_random_target()
		chef_small_knife_attack.level = chef_small_knife_level
		add_child(chef_small_knife_attack)
		chef_small_knife_ammo -= 1
		if chef_small_knife_ammo > 0:
			chef_small_knifeAttackTimer.start()
		else:
			chef_small_knifeAttackTimer.stop()

func _on_tornado_timer_timeout():
	tornado_ammo += tornado_baseammo + additional_attacks
	tornadoAttackTimer.start()

func _on_tornado_attack_timer_timeout():
	if tornado_ammo > 0:
		var tornado_attack = tornado.instantiate()
		tornado_attack.position = position
		tornado_attack.last_movement = last_movement
		tornado_attack.level = tornado_level
		add_child(tornado_attack)
		tornado_ammo -= 1
		if tornado_ammo > 0:
			tornadoAttackTimer.start()
		else:
			tornadoAttackTimer.stop()

func spawn_chef_scissor():
	# 获取现有剪刀数量
	var get_scissor_total = chef_scissorBase.get_child_count()
	print("现有剪刀数量:", get_scissor_total)
	
	# 计算需要添加的剪刀数量
	var calc_spawns = (chef_scissor_ammo + additional_attacks) - get_scissor_total
	print("需要添加的剪刀数量:", calc_spawns)
	
	# 只添加新的剪刀，不清除现有的
	while calc_spawns > 0:
		var chef_scissor_spawn = chef_scissor.instantiate()
		chef_scissor_spawn.global_position = global_position
		chef_scissorBase.add_child(chef_scissor_spawn)
		calc_spawns -= 1
	
	# 更新所有剪刀
	var get_scissors = chef_scissorBase.get_children()
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
		"chef_small_knife1":
			chef_small_knife_level = 1
			chef_small_knife_baseammo += 1
		"chef_small_knife2":
			chef_small_knife_level = 2
			chef_small_knife_baseammo += 1
		"chef_small_knife3":
			chef_small_knife_level = 3
		"chef_small_knife4":
			chef_small_knife_level = 4
			chef_small_knife_baseammo += 2
		"tornado1":
			tornado_level = 1
			tornado_baseammo += 1
		"tornado2":
			tornado_level = 2
			tornado_baseammo += 1
		"tornado3":
			tornado_level = 3
			tornado_attackspeed -= 0.5
		"tornado4":
			tornado_level = 4
			tornado_baseammo += 1
		"chef_scissor1":
			chef_scissor_level = 1
			chef_scissor_ammo = 1
		"chef_scissor2":
			chef_scissor_level = 2
		"chef_scissor3":
			chef_scissor_level = 3
		"chef_scissor4":
			chef_scissor_level = 4
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
		"food":
			hp += 20
			hp = clamp(hp,0,maxhp)
		"chef_big_knife1":
			chef_big_knife_level = 1
			knife_count = 2
			knife_damage = 1
			knife_distance = 70
			rotation_speed = -2.0
			initialize_rotating_knives()
		"chef_big_knife2":
			chef_big_knife_level = 2
			knife_count = 3
			knife_damage = 2
			knife_distance = 80
			rotation_speed = -2.2
			initialize_rotating_knives()
		"chef_big_knife3":
			chef_big_knife_level = 3
			knife_count = 4
			knife_damage = 3
			knife_distance = 90
			rotation_speed = -2.4
			initialize_rotating_knives()
		"chef_big_knife4":
			chef_big_knife_level = 4
			knife_count = 5
			knife_damage = 4
			knife_distance = 100
			rotation_speed = -2.6
			initialize_rotating_knives()
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
	
	# 创建新的旋转刀
	for i in range(knife_count):
		var knife_instance = chef_big_knife.instantiate()
		knife_instance.global_position = global_position
		knife_instance.damage = knife_damage
		knife_instance.scale = knife_scale
		# 连接信号（如果需要的话）
		knife_instance.connect("body_entered", _on_knife_body_entered)
		add_child(knife_instance)
		knives.append(knife_instance)

func update_rotating_knives():
	# 更新旋转刀的位置
	var angle_step = 2 * PI / knife_count
	base_rotation += rotation_speed * get_process_delta_time()
	
	for i in range(knife_count):
		if i < knives.size() and is_instance_valid(knives[i]):
			var angle = base_rotation + i * angle_step
			var offset = Vector2(cos(angle), sin(angle)) * knife_distance
			knives[i].global_position = global_position + offset
			
			# 更新刀的角度属性，使其指向正确的方向
			knives[i].angle = offset.normalized()

func upgrade_knife():
	knife_count += 1
	
	match knife_count:
		2:
			knife_damage = 1
			knife_distance = 70
			rotation_speed = -2.0
		3:
			knife_damage = 2
			knife_distance = 80
			rotation_speed = -2.2
		4:
			knife_damage = 3
			knife_distance = 90
			rotation_speed = -2.4
	
	# 重新初始化旋转刀
	initialize_rotating_knives()

func _on_knife_body_entered(body):
	if body.is_in_group("enemy"):
		# 计算从玩家到敌人的方向向量
		var direction_vector = body.global_position - global_position
		
		# 确保方向始终是从玩家推向敌人（无论敌人在哪一侧）
		var knockback_direction = direction_vector.normalized()
		var knockback_strength = 150  # 击退力度
		
		# 打印调试信息
		print("Player pos: ", global_position)
		print("Enemy pos: ", body.global_position)
		print("Direction vector: ", direction_vector)
		print("Knockback direction: ", knockback_direction)
		
		# 对敌人造成伤害
		if body.has_method("_on_hurt_box_hurt"):
			# 直接调用敌人的受伤函数，传递正确的击退方向
			body._on_hurt_box_hurt(knife_damage, knockback_direction, knockback_strength)
