extends Area2D

var level = 1
var hp = 1
var speed = 100
var damage = 5
var knockback_amount = 100
var attack_size = 1.0

var target = Vector2.ZERO
var angle = Vector2.ZERO

@onready var player_soldier = get_tree().get_first_node_in_group("player")
@onready var soldier_bullet_aniamtion= get_node("%AnimationPlayer")

signal remove_from_array(object)

func _ready():
	angle = global_position.direction_to(target)
	rotation = angle.angle() + deg_to_rad(135)
	match level:
		1:
			hp = 1
			speed = 300
			damage = 5
			knockback_amount = 100
			attack_size = 1.0 
		2:
			hp = 1
			speed = 300
			damage = 5
			knockback_amount = 100
			attack_size = 1.0 
		3:
			hp = 2
			speed = 300
			damage = 8
			knockback_amount = 100
			attack_size = 1.0 
		4:
			hp = 2
			speed = 300
			damage = 8
			knockback_amount = 100
			attack_size = 1.0
		5:
			hp = 2
			speed = 300
			damage = 8
			knockback_amount = 100
			attack_size = 1.0
	
	var tween = create_tween()
	tween.tween_property(self,"scale",Vector2(1,1)*attack_size,1).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	tween.play()

func _physics_process(delta):
	position += angle*speed*delta
	soldier_bullet_aniamtion.play("bullet")

func enemy_hit(charge = 1):
	hp -= charge
	if hp <= 0:
		emit_signal("remove_from_array",self)
		queue_free()


func _on_timer_timeout():
	emit_signal("remove_from_array",self)
	queue_free()
