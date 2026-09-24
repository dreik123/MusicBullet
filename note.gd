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

@onready var visual = $Polygon2D

func _ready():
	print("Note created, groups: ", get_groups())

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

func _process(delta):
	var main = get_tree().current_scene
	var time_until_arrival = arrival_time - main.music_time
	var heat = 0.0
	if time_until_arrival <= visible_duration:
		var peak = visible_duration / 2.0
		if peak > 0.0:
			heat = clamp(1.0 - abs(time_until_arrival - peak) / peak, 0.0, 1.0)
	visual.self_modulate = COLOR_FAR.lerp(COLOR_NEAR, heat)

	var distance_to_target = global_position.distance_to(target_position)
	if distance_to_target <= note_speed * delta:
		global_position = target_position
		queue_free()
		return

	global_position += direction * note_speed * delta
