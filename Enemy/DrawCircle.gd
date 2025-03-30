extends Node2D

var radius = 50

func _init(r = 50):
	radius = r

func _draw():
	draw_circle(Vector2.ZERO, radius, Color(1.0, 0.5, 0.2, 0.3))
	draw_arc(Vector2.ZERO, radius, 0, 2*PI, 32, Color(1.0, 0.5, 0.2, 0.8), 2.0)
