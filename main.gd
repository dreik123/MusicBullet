extends Node2D

@export var note_scene: PackedScene

var music_time = 0.0
var next_note_index = 0
var recorded_notes = []
var score = 0
var note_travel_time = 2.0

var notes = [
		{
			"time": 0.0,
			"pitch": 60
		},
		{
			"time": 0.5,
			"pitch": 62
		},
		{
			"time": 1.0,
			"pitch": 64
		},
		{
			"time": 1.5,
			"pitch": 62
		},
]
func _process(delta):
	music_time += delta
	if next_note_index < notes.size():
		var note_data = notes[next_note_index]
		
		if music_time >= note_data["time"] - note_travel_time:
			spawn_note(note_data)
			next_note_index += 1
	
func spawn_note(note_data):
	var note = note_scene.instantiate()
	add_child(note)
	###########################
	note.setup(
		note_data["time"],
		note_data["pitch"]
	)

	###########################
	note.position = Vector2(
		576 + note.note_speed * note_travel_time,
		300 - (note.pitch - 60) * 20
	)
