extends Node2D

@export var note_scene: PackedScene

const NOTE_SPAWN_MARGIN = 100.0
const PITCH_ANGLE_STEP = 15.0
const MIN_SPAWN_ANGLE = -180.0
const MAX_SPAWN_ANGLE = 0.0

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

func _ready():
	music_time = -note_travel_time
	spawn_due_notes()

func _process(delta):
	music_time += delta
	spawn_due_notes()

func spawn_due_notes():
	while next_note_index < notes.size():
		var note_data = notes[next_note_index]
		
		if music_time < note_data["time"] - note_travel_time:
			break

		spawn_note(note_data)
		next_note_index += 1
	
func spawn_note(note_data):
	var note = note_scene.instantiate()
	add_child(note)

	var player_position = $Player.global_position
	var spawn_radius = get_note_spawn_radius()
	var spawn_angle = clamp(
		-90.0 + (note_data["pitch"] - 60) * PITCH_ANGLE_STEP,
		MIN_SPAWN_ANGLE,
		MAX_SPAWN_ANGLE
	)
	note.global_position = player_position + Vector2.from_angle(deg_to_rad(spawn_angle)) * spawn_radius

	note.setup(
		note_data["time"] - note_travel_time,
		note_data["pitch"],
		player_position
	)

func get_note_spawn_radius():
	var viewport_rect = get_viewport_rect()
	var viewport_size = viewport_rect.size
	var half_screen_diagonal = sqrt(
		pow(viewport_size.x / 2.0, 2) + pow(viewport_size.y / 2.0, 2)
	)
	var player_position = $Player.global_position
	var farthest_corner_distance = max(
		max(
			player_position.distance_to(viewport_rect.position),
			player_position.distance_to(Vector2(viewport_rect.end.x, viewport_rect.position.y))
		),
		max(
			player_position.distance_to(Vector2(viewport_rect.position.x, viewport_rect.end.y)),
			player_position.distance_to(viewport_rect.end)
		)
	)
	return max(half_screen_diagonal, farthest_corner_distance) + NOTE_SPAWN_MARGIN
