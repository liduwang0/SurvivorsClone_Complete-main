extends CharacterBody2D

# 武器定义 - 集中管理所有武器的基本属性
const WEAPONS = {
	"chef_small_knife": {
		"scene": preload("res://Player/Attack/chef_small_knife.tscn"),
		"timer_method": "timer", # 使用计时器生成弹药
		"base_level": 1,
		"max_level": 4,
		"levels": {
			1: {"baseammo": 1, "attackspeed": 1.5, "damage": 1},
			2: {"baseammo": 2, "attackspeed": 1.4, "damage": 2},
			3: {"baseammo": 3, "attackspeed": 1.3, "damage": 3},
			4: {"baseammo": 4, "attackspeed": 1.2, "damage": 4}
		}
	},
	"chef_rolling_pin": {
		"scene": preload("res://Player/Attack/chef_rolling_pin.tscn"),
		"timer_method": "timer", # 使用计时器生成弹药
		"base_level": 1,
		"max_level": 5,
		"levels": {
			1: {"baseammo": 1, "attackspeed": 3.0, "damage": 1},
			2: {"baseammo": 2, "attackspeed": 3.0, "damage": 2},
			3: {"baseammo": 3, "attackspeed": 3.0, "damage": 3},
			4: {"baseammo": 4, "attackspeed": 3.0, "damage": 4},
			5: {"baseammo": 1, "attackspeed": 1.2, "damage": 5, "special": "four_directions"}
		}
	},
	"chef_scissor": {
		"scene": preload("res://Player/Attack/chef_scissor.tscn"),
		"timer_method": "direct", # 直接生成
		"base_level": 1,
		"max_level": 4,
		"levels": {
			1: {"baseammo": 1, "attackspeed": 2.0, "paths": 1},
			2: {"baseammo": 1, "attackspeed": 1.8, "paths": 2},
			3: {"baseammo": 2, "attackspeed": 1.6, "paths": 3},
			4: {"baseammo": 2, "attackspeed": 1.4, "paths": 3}
		}
	},
	"chef_pan": {
		"scene": preload("res://Player/Attack/chef_pan.tscn"),
		"timer_method": "continuous", # 连续计时器方式
		"base_level": 1,
		"max_level": 4,
		"levels": {
			1: {"baseammo": 1, "attackspeed": 4.0, "damage": 1},
			2: {"baseammo": 2, "attackspeed": 3.8, "damage": 2},
			3: {"baseammo": 3, "attackspeed": 3.2, "damage": 3},
			4: {"baseammo": 4, "attackspeed": 3.0, "damage": 4}
		}
	},
	"chef_big_knife": {
		"scene": preload("res://Player/Attack/chef_big_knife.tscn"),
		"timer_method": "orbital", # 轨道方式
		"base_level": 1,
		"max_level": 4,
		"levels": {
			1: {"count": 1, "damage": 1, "distance": 70, "rotation_speed": -0.6},
			2: {"count": 2, "damage": 2, "distance": 80, "rotation_speed": -0.7},
			3: {"count": 3, "damage": 3, "distance": 90, "rotation_speed": -0.8},
			4: {"count": 4, "damage": 4, "distance": 100, "rotation_speed": -0.9}
		}
	},
	"chef_whisk": {
		"scene": preload("res://Player/Attack/chef_whisk.tscn"),
		"timer_method": "vortex", # 漩涡方式
		"base_level": 1,
		"max_level": 4,
		"levels": {
			1: {"baseammo": 1, "attackspeed": 5.0, "damage": 1, "vortex_radius": 80, "vortex_duration": 3.0, "vortex_pull_force": 200},
			2: {"baseammo": 1, "attackspeed": 4.5, "damage": 2, "vortex_radius": 60, "vortex_duration": 3.5, "vortex_pull_force": 300},
			3: {"baseammo": 2, "attackspeed": 4.0, "damage": 3, "vortex_radius": 70, "vortex_duration": 4.0, "vortex_pull_force": 400},
			4: {"baseammo": 2, "attackspeed": 3.5, "damage": 4, "vortex_radius": 80, "vortex_duration": 4.5, "vortex_pull_force": 500}
		}
	}
}

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
var chef_whisk = preload("res://Player/Attack/chef_whisk.tscn")

#AttackNodes
@onready var chef_small_knife_timer = get_node("%chef_small_knifeTimer")
@onready var chef_small_knife_attack_timer = get_node("%chef_small_knifeAttackTimer")
@onready var chef_rolling_pin_timer = get_node("%chef_rolling_pinTimer")
@onready var chef_rolling_pin_attack_timer = get_node("%chef_rolling_pinAttackTimer")
@onready var chef_scissor_base = get_node("%chef_scissorBase")
@onready var chef_whisk_timer = get_node("%chef_whiskTimer")
@onready var chef_whisk_attack_timer = get_node("%chef_whiskAttackTimer")

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

#chef_whisk 打蛋器的属性
var chef_whisk_level = 0
var chef_whisk_baseammo = 1
var chef_whisk_ammo = 0
var chef_whisk_attackspeed = 5.0
var chef_whisk_vortex_radius = 50
var chef_whisk_vortex_duration = 3.0
var chef_whisk_vortex_pull_force = 20

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
	# 只在计时器触发时生成平底锅，而不是在升级时
	if chef_pan_timer >= chef_pan_attackspeed * (1-spell_cooldown):
		chef_pan_timer = 0
		
		# 获取当前平底锅数量
		var current_pans = chef_pan_base.get_child_count()
		
		# 计算需要生成的平底锅数量（考虑额外攻击）
		var target_pans = chef_pan_baseammo + additional_attacks
		var pans_to_spawn = target_pans - current_pans
		
		# 确保不会生成负数的平底锅
		pans_to_spawn = max(0, pans_to_spawn)
		
		# 打印调试信息
		print("平底锅生成 - 当前:", current_pans, " 目标:", target_pans, " 需要生成:", pans_to_spawn)
		
		# 同时生成多个平底锅
		while pans_to_spawn > 0:
			var chef_pan_spawn = chef_pan.instantiate()
			chef_pan_spawn.global_position = global_position
			chef_pan_base.add_child(chef_pan_spawn)
			pans_to_spawn -= 1

func _ready():
	#upgrade_character("chef_small_knife1")
	# 添加这一行来测试擀面杖
	#upgrade_character("chef_rolling_pin1")
	upgrade_character("chef_pan1")
	attack()
	set_expbar(experience, calculate_experiencecap())
	_on_hurt_box_hurt(0,0,0)
	if chef_big_knife_level > 0:
		initialize_rotating_knives()
	
	
	# 确保擀面杖初始弹药为0
	chef_rolling_pin_ammo = 0
	
	# 确保所有武器的初始弹药为0
	chef_small_knife_ammo = 0
	chef_rolling_pin_ammo = 0
	chef_scissor_ammo = 0

var test_weapon_level = 1	
func test_upgrade():
	if Input.is_action_just_pressed("test"):
		# 这里可以轻松切换要测试的武器类型
		var weapon_to_test = "chef_whisk"  # 改为打蛋器以进行测试
		
		# 使用通用函数升级武器
		upgrade_weapon(weapon_to_test, test_weapon_level)
		test_weapon_level += 1
		
		# 重置等级，如果超过了最大等级
		if test_weapon_level > WEAPONS[weapon_to_test]["levels"].size():
			test_weapon_level = 1
		
		print("测试升级", weapon_to_test, "到等级", test_weapon_level - 1)
	
func _physics_process(delta):
	test_upgrade()
	movement()
	if chef_big_knife_level > 0:
		update_rotating_knives()
	
	# Pan weapon update
	if chef_pan_level > 0:
		chef_pan_timer += delta
		if chef_pan_timer >= chef_pan_attackspeed * (1-spell_cooldown):
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
		
	# 打蛋器攻击
	if chef_whisk_level > 0 and chef_whisk_timer:
		chef_whisk_timer.wait_time = chef_whisk_attackspeed * (1-spell_cooldown)
		if chef_whisk_timer.is_stopped():
			chef_whisk_timer.start()
	
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
	# 增加基础弹药量 + 额外攻击
	chef_small_knife_ammo += chef_small_knife_baseammo + additional_attacks
	chef_small_knife_attack_timer.start()
	
	# 打印调试信息
	#print("小刀计时器触发，当前弹药:", chef_small_knife_ammo)

func _on_chef_small_knife_attack_timer_timeout():
	if chef_small_knife_ammo > 0:
		# 打印调试信息
		#print("小刀攻击计时器触发，当前弹药:", chef_small_knife_ammo)
		
		# 生成小刀
		var chef_small_knife_attack = chef_small_knife.instantiate()
		chef_small_knife_attack.position = position
		chef_small_knife_attack.target = get_random_target()
		chef_small_knife_attack.level = chef_small_knife_level
		add_child(chef_small_knife_attack)
		
		# 减少弹药
		chef_small_knife_ammo -= 1
		
		# 如果还有弹药，继续计时器
		if chef_small_knife_ammo > 0:
			chef_small_knife_attack_timer.start()
		else:
			chef_small_knife_attack_timer.stop()

func _on_chef_rolling_pin_timer_timeout():
	# 基础弹药 + 额外攻击
	chef_rolling_pin_ammo += chef_rolling_pin_baseammo + additional_attacks
	chef_rolling_pin_attack_timer.start()
	
	# 打印当前弹药数量，用于调试
	#print("擀面杖计时器触发，当前弹药:", chef_rolling_pin_ammo)

func _on_chef_rolling_pin_attack_timer_timeout():
	if chef_rolling_pin_ammo > 0:
		# 打印当前弹药数量，用于调试
		#print("擀面杖攻击计时器触发，当前弹药:", chef_rolling_pin_ammo)
		
		# 确保last_movement不为零向量
		var attack_direction = last_movement
		if attack_direction == Vector2.ZERO:
			attack_direction = Vector2.RIGHT
		
		# 检查是否是第5级，需要朝四个方向发射
		if chef_rolling_pin_level == 5:
			# 朝四个方向发射擀面杖
			var directions = [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN]
			for direction in directions:
				var chef_rolling_pin_attack = chef_rolling_pin.instantiate()
				chef_rolling_pin_attack.position = position
				chef_rolling_pin_attack.angle = direction
				chef_rolling_pin_attack.level = chef_rolling_pin_level
				add_child(chef_rolling_pin_attack)
		else:
			# 正常朝一个方向发射
			var chef_rolling_pin_attack = chef_rolling_pin.instantiate()
			chef_rolling_pin_attack.position = position
			chef_rolling_pin_attack.angle = attack_direction
			chef_rolling_pin_attack.level = chef_rolling_pin_level
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
	#print("现有剪刀数量:", get_scissor_total)
	
	# 计算需要添加的剪刀数量
	var calc_spawns = (chef_scissor_ammo + additional_attacks) - get_scissor_total
	#print("需要添加的剪刀数量:", calc_spawns)
	
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
		#print("更新剪刀 - 等级:", chef_scissor_level)
		if i.get("paths") != null:
			pass
			#print("剪刀路径数:", i.paths)

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
			upgrade_weapon("chef_pan", 1)
		"chef_pan2":
			upgrade_weapon("chef_pan", 2)
		"chef_pan3":
			upgrade_weapon("chef_pan", 3)
		"chef_pan4":
			upgrade_weapon("chef_pan", 4)
		"chef_small_knife1":
			upgrade_weapon("chef_small_knife", 1)
		"chef_small_knife2":
			upgrade_weapon("chef_small_knife", 2)
		"chef_small_knife3":
			upgrade_weapon("chef_small_knife", 3)
		"chef_small_knife4":
			upgrade_weapon("chef_small_knife", 4)
		"chef_rolling_pin1":
			upgrade_weapon("chef_rolling_pin", 1)
		"chef_rolling_pin2":
			upgrade_weapon("chef_rolling_pin", 2)
		"chef_rolling_pin3":
			upgrade_weapon("chef_rolling_pin", 3)
		"chef_rolling_pin4":
			upgrade_weapon("chef_rolling_pin", 4)
		"chef_rolling_pin5":
			upgrade_weapon("chef_rolling_pin", 5)
		"chef_scissor1":
			upgrade_weapon("chef_scissor", 1)
		"chef_scissor2":
			upgrade_weapon("chef_scissor", 2)
		"chef_scissor3":
			upgrade_weapon("chef_scissor", 3)
		"chef_scissor4":
			upgrade_weapon("chef_scissor", 4)
		"chef_whisk1":
			upgrade_weapon("chef_whisk", 1)
		"chef_whisk2":
			upgrade_weapon("chef_whisk", 2)
		"chef_whisk3":
			upgrade_weapon("chef_whisk", 3)
		"chef_whisk4":
			upgrade_weapon("chef_whisk", 4)
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
			upgrade_weapon("chef_big_knife", 1)
		"chef_big_knife2":
			upgrade_weapon("chef_big_knife", 2)
		"chef_big_knife3":
			upgrade_weapon("chef_big_knife", 3)
		"chef_big_knife4":
			upgrade_weapon("chef_big_knife", 4)
		"chef_rolling_pin1", "chef_rolling_pin2", "chef_rolling_pin3", "chef_rolling_pin4":
			var new_level = chef_rolling_pin_level + 1
			if new_level <= 5:  # 防止超过最大等级
				upgrade_weapon("chef_rolling_pin", new_level)
	adjust_gui_collection(upgrade)
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
				#print("在 player_test.gd 中调用 update_angle")

func upgrade_weapon(weapon_type, level):
	# 确保武器类型有效
	if not WEAPONS.has(weapon_type):
		print("错误: 无效的武器类型", weapon_type)
		return
		
	# 确保等级有效
	if not WEAPONS[weapon_type]["levels"].has(level):
		print("错误: 武器", weapon_type, "没有等级", level)
		return
	
	# 获取武器数据
	var weapon_data = WEAPONS[weapon_type]["levels"][level]
	
	# 根据武器类型应用不同的升级逻辑
	match weapon_type:
		"chef_small_knife":
			chef_small_knife_level = level
			chef_small_knife_baseammo = weapon_data["baseammo"]
			chef_small_knife_attackspeed = weapon_data["attackspeed"]
			
			# 更新计时器
			if chef_small_knife_timer:
				chef_small_knife_timer.wait_time = chef_small_knife_attackspeed * (1-spell_cooldown)
				if level == 1 and chef_small_knife_timer.is_stopped():
					chef_small_knife_timer.start()
		
		"chef_rolling_pin":
			chef_rolling_pin_level = level
			chef_rolling_pin_baseammo = weapon_data["baseammo"]
			chef_rolling_pin_attackspeed = weapon_data["attackspeed"]
			
			# 更新计时器
			if chef_rolling_pin_timer:
				chef_rolling_pin_timer.wait_time = chef_rolling_pin_attackspeed * (1-spell_cooldown)
				# 如果这是首次升级，确保计时器启动
				if level == 1 and chef_rolling_pin_timer.is_stopped():
					chef_rolling_pin_timer.start()
		
		"chef_scissor":
			chef_scissor_level = level
			chef_scissor_baseammo = weapon_data["baseammo"]
			chef_scissor_attackspeed = weapon_data["attackspeed"]
			
			# 直接应用弹药量
			chef_scissor_ammo = chef_scissor_baseammo + additional_attacks
			spawn_chef_scissor()
		
		"chef_pan":
			chef_pan_level = level
			chef_pan_baseammo = weapon_data["baseammo"]
			chef_pan_attackspeed = weapon_data["attackspeed"]
		
		"chef_big_knife":
			chef_big_knife_level = level
			knife_count = weapon_data["count"]
			knife_damage = weapon_data["damage"]
			knife_distance = weapon_data["distance"]
			rotation_speed = weapon_data["rotation_speed"]
			
			# 初始化旋转刀
			initialize_rotating_knives()
			
		"chef_whisk":
			chef_whisk_level = level
			chef_whisk_baseammo = weapon_data["baseammo"]
			chef_whisk_attackspeed = weapon_data["attackspeed"]
			chef_whisk_vortex_radius = weapon_data["vortex_radius"]
			chef_whisk_vortex_duration = weapon_data["vortex_duration"]
			chef_whisk_vortex_pull_force = weapon_data["vortex_pull_force"]
			
			# 更新计时器
			if chef_whisk_timer:
				chef_whisk_timer.wait_time = chef_whisk_attackspeed * (1-spell_cooldown)
				# 如果这是首次升级，确保计时器启动
				if level == 1 and chef_whisk_timer.is_stopped():
					chef_whisk_timer.start()
	
	# 仅在调试模式下打印信息
	if OS.is_debug_build():
		print(weapon_type, "升级到等级", level)
		
		# 打印关键属性
		var key_properties = []
		if weapon_data.has("baseammo"):
			key_properties.append("弹药: " + str(weapon_data["baseammo"]))
		if weapon_data.has("damage"):
			key_properties.append("伤害: " + str(weapon_data["damage"]))
		if weapon_data.has("attackspeed"):
			key_properties.append("攻速: " + str(weapon_data["attackspeed"]))
		if weapon_data.has("count"):
			key_properties.append("数量: " + str(weapon_data["count"]))
		if weapon_type == "chef_whisk":
			key_properties.append("漩涡半径: " + str(weapon_data["vortex_radius"]))
		
		if key_properties.size() > 0:
			print("属性: ", ", ".join(key_properties))
	
	# 更新攻击
	attack()

func _on_chef_whisk_timer_timeout():
	# 增加基础弹药量 + 额外攻击
	chef_whisk_ammo += chef_whisk_baseammo + additional_attacks
	chef_whisk_attack_timer.start()
	
	if OS.is_debug_build():
		print("[打蛋器] 计时器触发，当前弹药:", chef_whisk_ammo)

func _on_chef_whisk_attack_timer_timeout():
	if chef_whisk_ammo <= 0:
		chef_whisk_attack_timer.stop()
		return
		
	if OS.is_debug_build():
		print("[打蛋器] 攻击计时器触发，当前弹药:", chef_whisk_ammo)
	
	# 生成漩涡打蛋器
	spawn_chef_whisk_vortex(Vector2.ZERO)
	
	# 如果还有弹药，继续计时器
	if chef_whisk_ammo > 0:
		chef_whisk_attack_timer.start()
	else:
		chef_whisk_attack_timer.stop()

# 生成打蛋器漩涡
func spawn_chef_whisk_vortex(_target_position):
	var chef_whisk_spawn = chef_whisk.instantiate()
	
	# 设置基本属性
	chef_whisk_spawn.global_position = global_position
	chef_whisk_spawn.level = chef_whisk_level
	
	# 从武器配置获取级别属性并传递
	var weapon_level_data = WEAPONS["chef_whisk"]["levels"][chef_whisk_level]
	
	# 注意：直接传递配置参数，不添加任何修改、乘数或缩放
	chef_whisk_spawn.damage = weapon_level_data["damage"]
	chef_whisk_spawn.vortex_radius = weapon_level_data["vortex_radius"]
	chef_whisk_spawn.vortex_duration = weapon_level_data["vortex_duration"]
	chef_whisk_spawn.pull_force = weapon_level_data["vortex_pull_force"]
	
	# 仅应用全局法术大小修饰符
	chef_whisk_spawn.scale = Vector2(1, 1) * (1 + spell_size)
	
	# 打印更详细的配置信息
	print("[打蛋器] 生成漩涡 - 等级:", chef_whisk_level)
	print("  - 伤害:", weapon_level_data["damage"])
	print("  - 半径:", weapon_level_data["vortex_radius"])
	print("  - 持续时间:", weapon_level_data["vortex_duration"])
	print("  - 拉力:", weapon_level_data["vortex_pull_force"])
	
	# 将打蛋器添加到游戏世界而不是玩家
	var root = get_tree().get_root()
	var current_scene = root.get_child(root.get_child_count() - 1)
	current_scene.add_child(chef_whisk_spawn)
	
	# 减少弹药
	chef_whisk_ammo -= 1

# 添加此函数，用于打蛋器获取方向
func get_last_movement():
	return last_movement
