extends Node2D

@onready var label = $Label
var damage = 0

func _ready():
	if not label:
		print("错误：找不到Label节点")
		queue_free()
		return
		
	label.text = str(int(damage))
	
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color(1, 1, 0))
	
	start_animation()

func start_animation():
	var tween = create_tween()
	tween.tween_property(self, "position", position + Vector2(0, -40), 0.7)
	tween.parallel().tween_property(label, "modulate", Color(1, 1, 1, 0), 0.7)
	tween.tween_callback(queue_free)

func setup(value: float):
	damage = value
