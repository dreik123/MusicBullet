extends Area2D

@export var time: float
@export var pitch: int
@export var note_speed = 100.0
var target_position: Vector2
var direction: Vector2

func setup(note_time: float, note_pitch: int, note_target_position: Vector2):
	time = note_time
	pitch = note_pitch
	target_position = note_target_position
	direction = global_position.direction_to(target_position)

func _process(delta):
	var distance_to_target = global_position.distance_to(target_position)
	if distance_to_target <= note_speed * delta:
		global_position = target_position
		queue_free()
		return

	global_position += direction * note_speed * delta
