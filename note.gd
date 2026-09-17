extends Area2D

@export var time: float
@export var pitch: int
@export var note_speed = 100.0

func setup(note_time: float, note_pitch: int):
	time = note_time
	pitch = note_pitch

func _process(delta):
	position.x -= note_speed * delta
	if global_position.x < -100:
		queue_free()
