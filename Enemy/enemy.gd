extends CharacterBody2D


@export var movement_speed = 20.0
@export var hp = 10
@export var knockback_recovery = 3.5
@export var experience = 1
@export var enemy_damage = 1
var knockback = Vector2.ZERO

@onready var player = get_tree().get_first_node_in_group("player")
@onready var loot_base = get_tree().get_first_node_in_group("loot")
@onready var sprite = $Sprite2D
@onready var anim = $AnimationPlayer
@onready var snd_hit = $snd_hit
@onready var hitBox = $HitBox

var death_anim = preload("res://Enemy/explosion.tscn")
var exp_gem = preload("res://Objects/experience_gem.tscn")

signal remove_from_array(object)


func _ready():
	anim.play("walk")
	hitBox.damage = enemy_damage

func _physics_process(_delta):
	# 原有的击退逻辑
	knockback = knockback.move_toward(Vector2.ZERO, knockback_recovery)
	var direction = global_position.direction_to(player.global_position)
	velocity = direction*movement_speed
	velocity += knockback
	move_and_slide()
	
	# 方向处理
	if direction.x > 0.1:
		sprite.flip_h = true
	elif direction.x < -0.1:
		sprite.flip_h = false
		
	# 当击退接近结束且当前在受伤动画中，恢复行走动画
	if knockback.length() < 5 and anim.current_animation == "hurt":
		anim.play("walk")

func death():
	emit_signal("remove_from_array", self)
	
	# 禁用物理处理和碰撞，避免继续移动或造成伤害
	set_physics_process(false)
	if has_node("HitBox"):
		$HitBox.monitoring = false
	
	# 连接动画完成信号
	if !anim.animation_finished.is_connected(_on_death_animation_finished):
		anim.animation_finished.connect(_on_death_animation_finished)
	
	# 播放死亡动画
	anim.play("dead")

# 当死亡动画完成时调用
func _on_death_animation_finished(anim_name):
	if anim_name == "dead":
		# 生成经验宝石
		var new_gem = exp_gem.instantiate()
		new_gem.global_position = global_position
		new_gem.experience = experience
		loot_base.call_deferred("add_child", new_gem)
		
		# 如果您仍然想要爆炸效果，取消下面的注释
		# var enemy_death = death_anim.instantiate()
		# enemy_death.scale = sprite.scale
		# enemy_death.global_position = global_position
		# get_parent().call_deferred("add_child", enemy_death)
		
		# 从场景中移除敌人
		queue_free()

func _on_hurt_box_hurt(damage, angle, knockback_amount):
	hp -= damage
	knockback = angle * knockback_amount  # 设置击退值
	if hp <= 0:
		death()
	else:
		snd_hit.play()
		
		# 只播放受伤动画，不需要信号连接逻辑
		if anim.has_animation("hurt") and anim.current_animation != "hurt":
			anim.play("hurt")
			# 不再需要信号连接，由_physics_process处理恢复
