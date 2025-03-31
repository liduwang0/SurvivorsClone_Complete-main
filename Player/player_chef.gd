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
var chef_knife_small = preload("res://Player/Attack/chef_small_knife.tscn")

# 旋转菜刀属性
var knife_count = 5  # 菜刀数量
var knife_distance = 70  # 菜刀距离角色的距离
var rotation_speed = -2.0  # 旋转速度 (弧度/秒)
var knife_damage = 1  # 菜刀伤害
var knife_scale = Vector2(1, 1)  # 菜刀大小
var base_rotation = 0.0  # 基础旋转角度
var knives = []  # 存储所有菜刀实例

# 小刀属性
var chef_knife_small_ammo = 0
var chef_knife_small_base_ammo = 3
var chef_knife_small_attack_speed = 1.5
var chef_knife_small_level = 2  # 0表示未解锁
var chef_knife_small_timer = 0

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
	
	# 如果已解锁chef_knife_small，初始化弹药
	if chef_knife_small_level > 0:
		chef_knife_small_ammo = chef_knife_small_base_ammo

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
	
	# chef_knife_small攻击逻辑
	if chef_knife_small_level > 0:
		chef_knife_small_timer += delta
		if chef_knife_small_timer >= chef_knife_small_attack_speed:
			chef_knife_small_timer = 0
			if chef_knife_small_ammo > 0:
				throw_chef_knife_small()

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

# 添加投掷小刀函数
func throw_chef_knife_small():
	# 减少弹药
	chef_knife_small_ammo -= 1
	
	# 获取最近的敌人作为目标
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

# 生成小刀
func spawn_chef_knife_small(start_pos, target_pos):
	var knife_instance = chef_knife_small.instantiate()
	knife_instance.position = start_pos
	knife_instance.target = target_pos
	knife_instance.level = chef_knife_small_level
	
	# 连接信号
	knife_instance.connect("remove_from_array", Callable(self, "_on_chef_knife_small_removed"))
	
	# 添加到场景
	get_parent().add_child(knife_instance)

# 当小刀被移除时调用
func _on_chef_knife_small_removed(knife):
	# 可以在这里添加额外逻辑，如粒子效果等
	pass

# 查找最近的敌人
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

# 升级小刀攻击
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


func _on_chef_knife_small_attack_timer_timeout() -> void:
	pass


func _on_chef_knife_small_timer_timeout() -> void:
	if chef_knife_small_level > 0 and chef_knife_small_ammo > 0:
		throw_chef_knife_small()
