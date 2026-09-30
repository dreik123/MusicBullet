extends Node2D

@export var note_scene: PackedScene


const NOTE_SPAWN_MARGIN = 100.0

const LANE_COUNT = 8

var music_time = 0.0
var next_note_index = 0
var recorded_notes = []
var score = 0
var note_travel_time = 3.5
var level_ended = false
var _min_pitch = 0
var _max_pitch = 127

var notes = [
	{"time": 0.0, "pitches": [64]},
	{"time": 0.5, "pitches": [69]},
	{"time": 0.75, "pitches": [72]},
	{"time": 1.0, "pitches": [71]},
	{"time": 2.0, "pitches": [65]},
	{"time": 2.5, "pitches": [72]},
	{"time": 2.75, "pitches": [71]},
	{"time": 3.0, "pitches": [69]},
	{"time": 3.25, "pitches": [67]},
	{"time": 3.75, "pitches": [69]},
	{"time": 4.0, "pitches": [67]},
	{"time": 4.25, "pitches": [67]},
	{"time": 4.5, "pitches": [67]},
	{"time": 5.0, "pitches": [63]},
	{"time": 5.25, "pitches": [65]},
	{"time": 5.5, "pitches": [67]},
	{"time": 5.75, "pitches": [65]},
	{"time": 6.0, "pitches": [63]},
	{"time": 6.25, "pitches": [62]},
	{"time": 6.5, "pitches": [63]},
	{"time": 7.0, "pitches": [67]},
	{"time": 7.25, "pitches": [65]},
	{"time": 7.5, "pitches": [70]},
	{"time": 7.75, "pitches": [72]},
	{"time": 8.0, "pitches": [71]},
	{"time": 8.25, "pitches": [69]},
	{"time": 8.5, "pitches": [67]},
	{"time": 8.75, "pitches": [69]},
	{"time": 9.0, "pitches": [71]},
	{"time": 10.0, "pitches": [67]},
	{"time": 11.0, "pitches": [70, 72]},
	{"time": 11.5, "pitches": [70, 72]},
	{"time": 12.0, "pitches": [69, 70]},
	{"time": 12.5, "pitches": [69, 70]},
	{"time": 13.0, "pitches": [67]},
	{"time": 14.0, "pitches": [67]},
	{"time": 14.25, "pitches": [65]},
	{"time": 14.5, "pitches": [62]},
	{"time": 14.75, "pitches": [65]},
	{"time": 15.0, "pitches": [60, 67]},
	{"time": 15.5, "pitches": [60, 67]},
	{"time": 16.0, "pitches": [67]},
	{"time": 16.5, "pitches": [60, 67]},
	{"time": 17.0, "pitches": [63]},
	{"time": 17.5, "pitches": [59, 65]},
	{"time": 18.0, "pitches": [67]},
	{"time": 18.5, "pitches": [59, 65]},
	{"time": 19.0, "pitches": [62]},
	{"time": 19.5, "pitches": [55, 62]},
	{"time": 20.0, "pitches": [63]},
	{"time": 20.25, "pitches": [67, 74]},
	{"time": 20.5, "pitches": [67, 74]},
	{"time": 21.0, "pitches": [60, 63, 67]},
	{"time": 21.5, "pitches": [60, 63, 67]},
	{"time": 22.0, "pitches": [55]},
	{"time": 22.25, "pitches": [57]},
	{"time": 22.5, "pitches": [60]},
	{"time": 23.5, "pitches": [60]},
	{"time": 24.0, "pitches": [60]},
	{"time": 24.25, "pitches": [59]},
	{"time": 24.5, "pitches": [57]},
	{"time": 24.75, "pitches": [55]},
	{"time": 26.0, "pitches": [64, 69]},
	{"time": 26.5, "pitches": [67]},
	{"time": 27.0, "pitches": [62]},
	{"time": 27.5, "pitches": [67]},
	{"time": 28.0, "pitches": [60, 69]},
	{"time": 28.25, "pitches": [57, 65]},
	{"time": 28.5, "pitches": [69]},
	{"time": 29.5, "pitches": [64, 71]},
	{"time": 30.0, "pitches": [74]},
	{"time": 30.5, "pitches": [76]},
	{"time": 31.0, "pitches": [76]},
	{"time": 31.5, "pitches": [72, 83]},
	{"time": 32.0, "pitches": [67]},
]

func _ready():
	# Initialize _min_pitch and _max_pitch
	create_miss_boundary()

func create_miss_boundary():
	var miss_boundary = load("res://miss_boundary.gd").new()
	miss_boundary.name = "MissBoundary"
	$Player.add_child(miss_boundary)
	print("Miss boundary node created")
	_min_pitch = 127
	_max_pitch = 0

	# Find min and max pitch in the notes array
	for note in notes:
		for pitch in note["pitches"]:
			_min_pitch = min(_min_pitch, pitch)
			_max_pitch = max(_max_pitch, pitch)

func _snap_angle_to_lane(angle_degrees: float) -> float:
	var lane_size = 360.0 / LANE_COUNT
	var lane = round(angle_degrees / lane_size)
	return lane * lane_size

func _snap_angle_to_lane_rad(angle_rad: float) -> float:
	return deg_to_rad(_snap_angle_to_lane(deg_to_rad(angle_rad)))

func _get_lane_angle_for_pitch(pitch):
	var range_size = max(_max_pitch - _min_pitch, 1)
	var t = float(pitch - _min_pitch) / float(range_size)
	var lane = clamp(int(floor(t * LANE_COUNT)), 0, LANE_COUNT - 1)
	return -180.0 + lane * (360.0 / LANE_COUNT)
	
	print("Pitch range: ", _min_pitch, "to", _max_pitch)
	
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
	var pitches = note_data["pitches"]
	var lowest_pitch = pitches[0]
	for p in pitches:
		if p < lowest_pitch:
			lowest_pitch = p
	var spawn_angle = _get_lane_angle_for_pitch(lowest_pitch)
	
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
		pitches,
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
			if abs(orig_time - current_time) < 0.01:
				var chart_pitches = chart_note["pitches"]
				var recorded_pitches = recorded["pitches"]
				var all_match = true
				for pitch in chart_pitches:
					if not recorded_pitches.has(pitch):
						all_match = false
						break
				if all_match:
					was_hit = true
					break
		
		if was_hit:
			print("Melody playback: playing pitches ", chart_note["pitches"], " at chart_time ", current_time)
			for pitch in chart_note["pitches"]:
				play_melody_sound(pitch)
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
