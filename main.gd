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
var level_ended = false

var notes = [
		{
			"time": 0.0,
			"pitch": 60
		},
		{
			"time": 1.0,
			"pitch": 62
		},
		{
			"time": 2.0,
			"pitch": 64
		},
		{
			"time": 3.0,
			"pitch": 62
		},

]

func _ready():
	music_time = -note_travel_time
	spawn_due_notes()

func _process(delta):
	if level_ended:
		return
		
	music_time += delta
	spawn_due_notes()
	check_level_end()

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
	var spawn_angle = clamp(
		-90.0 + (note_data["pitch"] - 60) * PITCH_ANGLE_STEP,
		MIN_SPAWN_ANGLE,
		MAX_SPAWN_ANGLE
	)
	
	var outward_direction = Vector2.from_angle(deg_to_rad(spawn_angle))
	var far_outside_point = player_position + outward_direction * 5000.0
	var viewport_rect = get_viewport_rect()
	var entry_ratio = get_viewport_entry_ratio(far_outside_point, player_position, viewport_rect)
	
	var spawn_point = player_position + outward_direction * get_note_spawn_radius()
	if entry_ratio >= 0.0:
		var boundary_point = far_outside_point.lerp(player_position, entry_ratio)
		spawn_point = boundary_point + outward_direction * 50.0
		
	note.global_position = spawn_point
	note.note_speed = spawn_point.distance_to(player_position) / note_travel_time

	note.setup(
		note_data["time"] - note_travel_time,
		note_data["pitch"],
		player_position,
		note_data["time"]
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

func has_active_notes() -> bool:
	for note in get_tree().get_nodes_in_group("notes"):
		if not note.is_queued_for_deletion():
			return true
	return false

func check_level_end():
	if notes.is_empty():
		end_level()
		return
		
	var all_spawned = next_note_index >= notes.size()
	var none_active = not has_active_notes()
	
	var last_note_time = notes.back()["time"]
	var time_exceeded = music_time > last_note_time + 1.0
	
	print("check_level_end: next_note_index=", next_note_index, " notes.size()=", notes.size(), " all_spawned=", all_spawned, " none_active=", none_active, " active_count=", get_tree().get_nodes_in_group("notes").size())
	if (all_spawned and none_active) or time_exceeded:
		end_level()

func end_level():
	print("end_level() called from context, level_ended was: ", level_ended)
	level_ended = true
	print("Level ended! Starting melody playback...")
	play_recorded_melody()

func play_recorded_melody():
	# Wait 1.0 second for a clean transition before starting playback
	await get_tree().create_timer(1.0).timeout
	print("Melody playback started!")
	
	var last_time = 0.0
	for i in range(notes.size()):
		var chart_note = notes[i]
		var current_time = chart_note["time"]
		var delay = current_time - last_time
		if delay > 0.0:
			await get_tree().create_timer(delay).timeout
		
		# Check if this chart note was hit by searching in recorded_notes
		var was_hit = false
		for recorded in recorded_notes:
			var orig_time = recorded["time"] - recorded["error"] + note_travel_time
			if abs(orig_time - current_time) < 0.01 and recorded["pitch"] == chart_note["pitch"]:
				was_hit = true
				break
		
		if was_hit:
			print("Melody playback: playing pitch ", chart_note["pitch"], " at chart_time ", current_time)
			play_melody_sound(chart_note["pitch"])
		else:
			print("Melody playback: silence (missed note) at chart_time ", current_time)
			
		last_time = current_time
	print("Melody playback finished!")

func play_melody_sound(pitch: int):
	var note_audio = $Player/NoteAudio
	note_audio.pitch_scale = pow(2.0, (pitch - 60) / 12.0)
	note_audio.play()

func get_viewport_entry_ratio(start_position: Vector2, end_position: Vector2, viewport_rect: Rect2):
	var delta = end_position - start_position
	var p = [-delta.x, delta.x, -delta.y, delta.y]
	var q = [
		start_position.x - viewport_rect.position.x,
		viewport_rect.end.x - start_position.x,
		start_position.y - viewport_rect.position.y,
		viewport_rect.end.y - start_position.y
	]
	var entry_ratio = 0.0
	var exit_ratio = 1.0

	for index in p.size():
		if is_zero_approx(p[index]):
			if q[index] < 0.0:
				return -1.0
			continue

		var ratio = q[index] / p[index]
		if p[index] < 0.0:
			if ratio > exit_ratio:
				return -1.0
			entry_ratio = max(entry_ratio, ratio)
		else:
			if ratio < entry_ratio:
				return -1.0
			exit_ratio = min(exit_ratio, ratio)

	return entry_ratio
