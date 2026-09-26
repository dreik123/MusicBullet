extends Node2D

const MISS_RADIUS = 150.0
const STROKE_COLOR = Color(1, 1, 1, 0.6)
const STROKE_WIDTH = 3.0

func _draw():
	draw_circle(Vector2.ZERO, MISS_RADIUS, STROKE_COLOR, false, STROKE_WIDTH)
