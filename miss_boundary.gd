extends Node2D

const MISS_RADIUS = 100.0
@export var MISS_BOUNDARY_RADIUS = MISS_RADIUS
var _miss_boundary_radius: float = MISS_BOUNDARY_RADIUS

const STROKE_COLOR = Color(1, 1, 1, 0.6)
const STROKE_WIDTH = 3.0

func _draw():
	draw_circle(Vector2.ZERO, MISS_RADIUS, STROKE_COLOR, false, STROKE_WIDTH)
