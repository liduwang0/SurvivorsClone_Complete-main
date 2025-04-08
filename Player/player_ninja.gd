extends CharacterBody2D

#初始化时启动攻击：
#在 _ready() 函数中调用 attack()，是为了确保角色一开始就能使用武器攻击。这样一旦游戏开始，玩家就不需要等待第一次攻击计时器完成。
#升级后重新配置攻击：
#在 upgrade_character() 函数结束时调用 attack()，是为了在玩家升级武器后立即应用新的攻击参数。比如，当你的苦无升级到更高级别时，攻击速度会变快，通过在升级后调用 attack()，可以立即重置计时器使用新的攻击速度。



var movement_speed = 100.0
var hp = 800
var maxhp = 800
var last_movement = Vector2.UP
var time = 0

var experience = 0
var experience_level = 1
var collected_experience = 0

#Attacks
var kunai = preload("res://Player/Attack/ninja_kunai.tscn")

#AttackNodes
@onready var kunai_timer = get_node("%ninja_kunai_Timer")
@onready var kunai_attack_timer = get_node("%ninja_kunai_AttackTimer")

#UPGRADES
var collected_upgrades = []
var upgrade_options = []
var armor = 0
var speed = 0
var spell_cooldown = 0
var spell_size = 0
var additional_attacks = 0

#kunai
var kunai_level = 0
var kunai_baseammo = 1
var kunai_ammo = 0
var kunai_reload_time = 2.0  # 换弹需要2秒
var kunai_fire_interval = 0.2  # 连发间隔0.2秒

#Enemy Related
var enemy_close = []

@onready var sprite = $Sprite2D
@onready var walkTimer = get_node("%walkTimer")

#GUI
@onready var expBar = get_node("%ExperienceBar")
@onready var lblLevel = get_node("%lbl_level")
@onready var levelPanel = get_node("%LevelUp")
@onready var upgradeOptions = get_node("%UpgradeOptions")
@onready var itemOptions = preload("res://Utility/item_option_ninja.tscn")
@onready var sndLevelUp = get_node("%snd_levelup")
@onready var healthBar = get_node("%HealthBar")
@onready var lblTimer = get_node("%lblTimer")
@onready var collectedWeapons = get_node("%CollectedWeapons")
@onready var collectedUpgrades = get_node("%CollectedUpgrades")
@onready var itemContainer = preload("res://Player/GUI/item_container_ninja.tscn")

@onready var deathPanel = get_node("%DeathPanel")
@onready var lblResult = get_node("%lbl_Result")
@onready var sndVictory = get_node("%snd_victory")
@onready var sndLose = get_node("%snd_lose")

#Signal
signal playerdeath

func _ready():
	upgrade_character("ninja_kunai1")
	attack()
	set_expbar(experience, calculate_experiencecap())
	_on_hurt_box_hurt(0,0,0)
	
	# 确保所有武器的初始弹药为0
	kunai_ammo = 0

func _physics_process(delta):
	movement()

func _process(delta):
	pass

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
	# kunai攻击
	if kunai_level > 0 and kunai_timer:
		kunai_timer.wait_time = kunai_reload_time * (1-spell_cooldown)
		if kunai_timer.is_stopped():
			kunai_timer.start()

func _on_hurt_box_hurt(damage, _angle, _knockback):
	hp -= clamp(damage-armor, 1.0, 999.0)
	healthBar.max_value = maxhp
	healthBar.value = hp
	if hp <= 0:
		death()

func _on_kunai_timer_timeout():
	# 武器换弹完成，可以再次攻击了
	if kunai_ammo <= 0:
		kunai_ammo = kunai_baseammo + additional_attacks
		kunai_attack_timer.wait_time = kunai_fire_interval  # 设置射击间隔
		kunai_attack_timer.start()
	else:
		print("警告：换弹触发时弹药未用完!")
		
func _on_kunai_attack_timer_timeout():
	if kunai_ammo > 0:
		# 发射苦无
		var kunai_attack = kunai.instantiate()
		kunai_attack.position = position
		kunai_attack.target = get_random_target()
		kunai_attack.level = kunai_level
		add_child(kunai_attack)
		
		# 减少弹药
		kunai_ammo -= 1
		print("剩余弹药: ", kunai_ammo)  # 调试信息
		
		# 如果还有弹药，继续发射
		if kunai_ammo > 0:
			kunai_attack_timer.stop()
			kunai_attack_timer.start()
		else:
			# 弹药用完，开始换弹
			print("弹药用完，开始换弹，需要 ", kunai_reload_time, " 秒")
			kunai_timer.stop()
			kunai_timer.start()
			kunai_attack_timer.stop()
	else:
		# 没有弹药，确保武器冷却计时器在运行
		if kunai_timer.is_stopped():
			kunai_timer.start()
		kunai_attack_timer.stop()
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
		"ninja_kunai1":
			upgrade_kunai(1)
		"ninja_kunai2":
			upgrade_kunai(2)
		"ninja_kunai3":
			upgrade_kunai(3)
		"ninja_kunai4":
			upgrade_kunai(4)
		"ninja_kunai5":
			upgrade_kunai(5)
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
	for i in UpgradeDbNinja.UPGRADES:
		if i in collected_upgrades: #Find already collected upgrades
			pass
		elif i in upgrade_options: #If the upgrade is already an option
			pass
		elif UpgradeDbNinja.UPGRADES[i]["type"] == "item": #Don't pick food
			pass
		elif UpgradeDbNinja.UPGRADES[i]["prerequisite"].size() > 0: #Check for PreRequisites
			var to_add = true
			for n in UpgradeDbNinja.UPGRADES[i]["prerequisite"]:
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
	var get_upgraded_displayname = UpgradeDbNinja.UPGRADES[upgrade]["displayname"]
	var get_type = UpgradeDbNinja.UPGRADES[upgrade]["type"]
	if get_type != "item":
		var get_collected_displaynames = []
		for i in collected_upgrades:
			get_collected_displaynames.append(UpgradeDbNinja.UPGRADES[i]["displayname"])
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

func upgrade_kunai(target_level = 0):
	# 如果没有提供目标等级，则增加当前等级
	if target_level == 0:
		target_level = kunai_level + 1
	
	# 设置等级
	kunai_level = target_level
	
	# 根据等级设置属性
	match kunai_level:
		1:
			kunai_baseammo = 1
			kunai_reload_time = 1.5  # 换弹时间
			kunai_fire_interval = 0.2  # 射击间隔
		2:
			kunai_baseammo = 2
			kunai_reload_time = 1.4
			kunai_fire_interval = 0.2
		3:
			kunai_baseammo = 3
			kunai_reload_time = 1.3
			kunai_fire_interval = 0.2
		4:
			kunai_baseammo = 4
			kunai_reload_time = 1.2
			kunai_fire_interval = 0.2
		5:
			kunai_baseammo = 15
			kunai_reload_time = 0  # 较长的换弹时间
			kunai_fire_interval = 0.1  # 更快的射击速度
	
	# 更新计时器
	if kunai_timer:
		kunai_timer.wait_time = kunai_reload_time * (1-spell_cooldown)
