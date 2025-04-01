extends Area2D

var damage = 10
var knockback_amount = 150
var attack_size = 1.0
var attack_range = 250  # 攻击范围半径

var target = Vector2.ZERO
var start_pos = Vector2.ZERO
var end_pos = Vector2.ZERO

@onready var player = get_tree().get_first_node_in_group("player")
signal remove_from_array(object)

func _ready():
	add_to_group("attack")
	
	# 根据等级调整伤害
	match player.chef_pan_level:
		1:
			damage = 10
			attack_size = 0.5
		2:
			damage = 20
			attack_size = 0.5
		3:
			damage = 30
			attack_size = 0.5
		4:
			damage = 40
			attack_size = 0.5
	
	await get_tree().process_frame
	find_random_enemy()
	setup_position_and_animation()

func find_random_enemy():
	var valid_enemies = []
	for enemy in player.enemy_close:
		if is_instance_valid(enemy):
			valid_enemies.append(enemy)
	
	if valid_enemies.size() > 0:
		var random_enemy = valid_enemies[randi() % valid_enemies.size()]
		end_pos = random_enemy.global_position
	else:
		var random_angle = randf() * 2 * PI
		var random_distance = randf() * 250
		end_pos = player.global_position + Vector2(cos(random_angle), sin(random_angle)) * random_distance

func setup_position_and_animation():
	var offset_y = -50  # 降低起始高度
	start_pos = end_pos + Vector2(0, offset_y)
	position = start_pos
	
	scale = Vector2(1, 1)
	rotation = deg_to_rad(-90)
	
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(2.5, 2.5) * attack_size, 0.1)
	tween.tween_property(self, "position", end_pos, 0.4).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(self, "rotation", deg_to_rad(0), 0.4)
	tween.tween_property(self, "scale", Vector2(0.1, 0.1), 0.2)
	
	await tween.finished
	queue_free()

func enemy_hit(_charge = 1):
	pass

func _on_timer_timeout():
	queue_free()
