extends Node2D

@onready var animation_player = $AnimationPlayer

func _ready():
	# 自动播放特效动画
	if animation_player.has_animation("bullet_shoot_effect"):
		animation_player.play("bullet_shoot_effect")
		# 设置为循环播放
		animation_player.get_animation("bullet_shoot_effect").loop_mode = 1  # 1 = LOOP_LINEAR

# 不再需要销毁自己，因为它会随着子弹一起被销毁
# func _on_animation_finished(anim_name):
#	if anim_name == "bullet_shoot_effect":
#		queue_free() 
