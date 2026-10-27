extends Area2D

const COLOR_FAR = Color(0.35, 0.55, 0.85, 1.0)
const COLOR_NEAR = Color(1.0, 0.5, 0.2, 1.0)

@export var time: float
@export var pitches: Array
@export var note_speed = 100.0
var arrival_time: float
var visible_duration = 0.0
var target_position: Vector2
var direction: Vector2
var duration = 1.0
var steps = []
var _tail: Line2D

@onready var visual = $Polygon2D

func setup(note_time: float, note_pitches: Array, note_target_position: Vector2, note_arrival_time: float):
	time = note_time
	pitches = note_pitches
	arrival_time = note_arrival_time
	target_position = note_target_position
	direction = global_position.direction_to(target_position)
	var entry_ratio = get_parent().get_viewport_entry_ratio(global_position, target_position, get_viewport_rect())
	if entry_ratio >= 0.0:
		var entry_position = global_position.lerp(target_position, entry_ratio)
		visible_duration = entry_position.distance_to(target_position) / note_speed

# Gives a segment (several fast notes merged into one target) a tail: a line behind the head
# as long as the distance the note travels during the time span of the segment.
func set_segment(span_seconds: float):
	if span_seconds <= 0.0:
		return
	_tail = Line2D.new()
	_tail.width = 12.0
	_tail.default_color = Color(1, 1, 1, 1)
	_tail.begin_cap_mode = Line2D.LINE_CAP_ROUND
	_tail.end_cap_mode = Line2D.LINE_CAP_ROUND
	_tail.show_behind_parent = true
	_tail.points = PackedVector2Array([Vector2.ZERO, -direction * note_speed * span_seconds])
	add_child(_tail)
	_tail.self_modulate = visual.self_modulate

# The moment when the colour is hottest: the middle of the visible flight, measured to the miss ring.
func get_ideal_time() -> float:
	var player = get_tree().current_scene.get_node("Player")
	var ring_radius = player.get_node("MissBoundary").MISS_BOUNDARY_RADIUS
	return arrival_time - ring_radius / note_speed - visible_duration / 2.0

func _process(delta):
	var main = get_tree().current_scene
	var player = main.get_node("Player")
	var miss_boundary_radius = player.get_node("MissBoundary").MISS_BOUNDARY_RADIUS
	var distance_to_player = global_position.distance_to(player.global_position)

	if distance_to_player <= miss_boundary_radius:
		queue_free()
		return

	var ring_arrival_time = arrival_time - (miss_boundary_radius / note_speed)
	var time_until_arrival = ring_arrival_time - main.music_time
	var heat = 0.0
	
	if time_until_arrival <= visible_duration:
		var peak = visible_duration / 2.0
		if peak > 0.0:
			heat = clamp(1.0 - abs(time_until_arrival - peak) / peak, 0.0, 1.0)
		visual.self_modulate = COLOR_FAR.lerp(COLOR_NEAR, heat)
		if _tail != null:
			_tail.self_modulate = visual.self_modulate

	var distance_to_target = global_position.distance_to(target_position)
	if distance_to_target <= note_speed * delta:
		global_position = target_position
		queue_free()
		return

	global_position += direction * note_speed * delta
