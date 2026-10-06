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
var _lane_visible_length = []
var _lane_speed = []

var NOTE_SPEED = 6.0

var notes = [
	{"time": 0.0, "pitches": [50, 55, 64], "duration": 2.0},
	{"time": 0.5, "pitches": [69], "duration": 0.25},
	{"time": 0.75, "pitches": [72], "duration": 0.25},
	{"time": 1.0, "pitches": [71], "duration": 0.5},
	{"time": 2.0, "pitches": [50, 55, 65], "duration": 0.5},
	{"time": 2.5, "pitches": [50, 72], "duration": 1.0},
	{"time": 2.75, "pitches": [71], "duration": 0.25},
	{"time": 3.0, "pitches": [69], "duration": 0.25},
	{"time": 3.25, "pitches": [67], "duration": 0.5},
	{"time": 3.75, "pitches": [69], "duration": 0.25},
	{"time": 4.0, "pitches": [43, 48, 67], "duration": 0.5},
	{"time": 4.25, "pitches": [67], "duration": 0.25},
	{"time": 4.5, "pitches": [43, 48, 67], "duration": 0.5},
	{"time": 5.0, "pitches": [43, 50, 63], "duration": 0.5},
	{"time": 5.25, "pitches": [65], "duration": 0.25},
	{"time": 5.5, "pitches": [67], "duration": 0.25},
	{"time": 5.75, "pitches": [65], "duration": 0.25},
	{"time": 6.0, "pitches": [43, 50, 63], "duration": 0.5},
	{"time": 6.25, "pitches": [62], "duration": 0.25},
	{"time": 6.5, "pitches": [63], "duration": 0.5},
	{"time": 7.0, "pitches": [43, 50, 67], "duration": 0.5},
	{"time": 7.25, "pitches": [65], "duration": 0.25},
	{"time": 7.5, "pitches": [48, 55, 70], "duration": 0.5},
	{"time": 7.75, "pitches": [72], "duration": 0.25},
	{"time": 8.0, "pitches": [38, 45, 71], "duration": 2.0},
	{"time": 8.25, "pitches": [69], "duration": 0.25},
	{"time": 8.5, "pitches": [67], "duration": 0.25},
	{"time": 8.75, "pitches": [69], "duration": 0.25},
	{"time": 9.0, "pitches": [71], "duration": 1.0},
	{"time": 10.0, "pitches": [55, 67], "duration": 1.0},
	{"time": 11.0, "pitches": [51, 58, 70, 72], "duration": 1.0},
	{"time": 11.5, "pitches": [70, 72], "duration": 0.5},
	{"time": 12.0, "pitches": [50, 57, 69, 70], "duration": 1.0},
	{"time": 12.5, "pitches": [69, 70], "duration": 0.5},
	{"time": 13.0, "pitches": [55, 62, 67], "duration": 1.0},
	{"time": 14.0, "pitches": [45, 67], "duration": 1.0},
	{"time": 14.25, "pitches": [65], "duration": 0.25},
	{"time": 14.5, "pitches": [62], "duration": 0.25},
	{"time": 14.75, "pitches": [65], "duration": 0.25},
	{"time": 15.0, "pitches": [38, 43, 60, 67], "duration": 1.0},
	{"time": 15.5, "pitches": [60, 67], "duration": 0.5},
	{"time": 16.0, "pitches": [41, 44, 67], "duration": 0.5},
	{"time": 16.5, "pitches": [36, 43, 60, 67], "duration": 0.5},
	{"time": 17.0, "pitches": [38, 43, 63], "duration": 1.0},
	{"time": 17.5, "pitches": [59, 65], "duration": 0.5},
	{"time": 18.0, "pitches": [41, 67], "duration": 0.5},
	{"time": 18.5, "pitches": [59, 65], "duration": 0.5},
	{"time": 19.0, "pitches": [36, 62], "duration": 1.0},
	{"time": 19.5, "pitches": [55, 62], "duration": 0.5},
	{"time": 20.0, "pitches": [36, 63], "duration": 0.5},
	{"time": 20.25, "pitches": [67, 74], "duration": 0.25},
	{"time": 20.5, "pitches": [39, 67, 74], "duration": 1.5},
	{"time": 21.0, "pitches": [60, 63, 67], "duration": 0.5},
	{"time": 21.5, "pitches": [60, 63, 67], "duration": 0.5},
	{"time": 22.0, "pitches": [36, 41, 45, 55], "duration": 0.5},
	{"time": 22.25, "pitches": [57], "duration": 0.25},
	{"time": 22.5, "pitches": [36, 43, 60], "duration": 1.0},
	{"time": 23.5, "pitches": [36, 43, 60], "duration": 0.5},
	{"time": 24.0, "pitches": [36, 39, 43, 60], "duration": 2.0},
	{"time": 24.25, "pitches": [59], "duration": 0.25},
	{"time": 24.5, "pitches": [57], "duration": 0.25},
	{"time": 24.75, "pitches": [55], "duration": 0.25},
	{"time": 26.0, "pitches": [43, 50, 64, 69], "duration": 1.0},
	{"time": 26.5, "pitches": [67], "duration": 0.5},
	{"time": 27.0, "pitches": [38, 45, 62], "duration": 1.0},
	{"time": 27.5, "pitches": [67], "duration": 0.5},
	{"time": 28.0, "pitches": [41, 60, 69], "duration": 1.0},
	{"time": 28.25, "pitches": [57, 65], "duration": 0.25},
	{"time": 28.5, "pitches": [69], "duration": 1.0},
	{"time": 29.0, "pitches": [45], "duration": 1.0},
	{"time": 29.5, "pitches": [64, 71], "duration": 0.5},
	{"time": 30.0, "pitches": [40, 48, 74], "duration": 1.0},
	{"time": 30.5, "pitches": [76], "duration": 0.5},
	{"time": 31.0, "pitches": [41, 45, 48, 76], "duration": 1.0},
	{"time": 31.5, "pitches": [72, 83], "duration": 0.5},
	{"time": 32.0, "pitches": [48, 55, 59, 67], "duration": 2.0},
]

func play_reference_melody():
	var last_time = 0.0
	for i in range(notes.size()):
		var chart_note = notes[i]
		var current_time = chart_note["time"]
		var delay = current_time - last_time
		if delay > 0.0:
			await get_tree().create_timer(delay).timeout
		for pitch in chart_note["pitches"]:
			play_melody_sound(pitch, chart_note.get("duration", 1.0))
		last_time = current_time
func _unhandled_input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_F1:
		play_reference_melody()
func _ray_viewport_exit_distance(origin: Vector2, direction: Vector2) -> float:
	var rect = get_viewport_rect()
	var t_max = INF
	if direction.x > 0:
		t_max = min(t_max, (rect.end.x - origin.x) / direction.x)
	elif direction.x < 0:
		t_max = min(t_max, (rect.position.x - origin.x) / direction.x)
	if direction.y > 0:
		t_max = min(t_max, (rect.end.y - origin.y) / direction.y)
	elif direction.y < 0:
		t_max = min(t_max, (rect.position.y - origin.y) / direction.y)
	return t_max

func _ready():
	_min_pitch = 127
	_max_pitch = 0
	for note in notes:
		for pitch in note["pitches"]:
			_min_pitch = min(_min_pitch, pitch)
			_max_pitch = max(_max_pitch, pitch)

	for i in range(notes.size()):
		if i == 0:
			notes[i]["travel_time"] = 3.0
		else:
			var gap = notes[i]["time"] - notes[i-1]["time"]
			notes[i]["travel_time"] = clamp(remap(gap, 0.25, 1.25, 1.2, 3.0), 1.2, 3.0)

	create_miss_boundary()

	var player_pos_for_lanes = $Player.global_position
	for lane in range(LANE_COUNT):
		var lane_angle = -180.0 + lane * (360.0 / LANE_COUNT)
		var lane_direction = Vector2.from_angle(deg_to_rad(lane_angle))
		var visible_length = _ray_viewport_exit_distance(player_pos_for_lanes, lane_direction)
		_lane_visible_length.append(visible_length)
		_lane_speed.append((visible_length + NOTE_SPAWN_MARGIN) / 1.2)

	music_time = -note_travel_time
	spawn_due_notes()

func _get_lane_index_for_pitch(pitch):
	var range_size = max(_max_pitch - _min_pitch, 1)
	var t = float(pitch - _min_pitch) / float(range_size)
	return clamp(int(floor(t * LANE_COUNT)), 0, LANE_COUNT - 1)

func create_miss_boundary():
	var miss_boundary = load("res://miss_boundary.gd").new()
	miss_boundary.name = "MissBoundary"
	$Player.add_child(miss_boundary)

func _get_lane_angle_for_pitch(pitch):
	var lane = _get_lane_index_for_pitch(pitch)
	return -180.0 + lane * (360.0 / LANE_COUNT)

func _snap_angle_to_lane(angle_degrees: float) -> float:
	var lane_size = 360.0 / LANE_COUNT
	var lane = round(angle_degrees / lane_size)
	return lane * lane_size

func _snap_angle_to_lane_rad(angle_rad: float) -> float:
	var angle_deg = rad_to_deg(angle_rad)
	var snapped_deg = _snap_angle_to_lane(angle_deg)
	return deg_to_rad(snapped_deg)

func _process(delta):
	if level_ended:
		return

	music_time += delta
	spawn_due_notes()
	check_level_end()

func spawn_due_notes():
	while next_note_index < notes.size():
		var note_data = notes[next_note_index]

		if music_time < note_data["time"] - note_data["travel_time"]:
			break

		spawn_note(note_data)
		next_note_index += 1

func spawn_note(note_data):
	var note = note_scene.instantiate()
	add_child(note)

	var player_position = $Player.global_position
	var pitches = note_data["pitches"]
	var highest_pitch = pitches[0]
	for p in pitches:
		if p > highest_pitch:
			highest_pitch = p
	var lane = _get_lane_index_for_pitch(highest_pitch)
	var spawn_angle = -180.0 + lane * (360.0 / LANE_COUNT)
	var outward_direction = Vector2.from_angle(deg_to_rad(spawn_angle))
	var lane_speed = _lane_speed[lane]
	var spawn_distance = lane_speed * note_data["travel_time"]
	var spawn_point = player_position + outward_direction * spawn_distance

	note.global_position = spawn_point
	note.note_speed = lane_speed

	note.setup(
		note_data["time"] - note_data["travel_time"],
		pitches,
		player_position,
		note_data["time"]
	)
	note.duration = note_data.get("duration", 1.0)

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

	if (all_spawned and none_active) or time_exceeded:
		end_level()

func end_level():
	if level_ended:
		return
	level_ended = true
	play_recorded_melody()

func play_recorded_melody():
	await get_tree().create_timer(1.0).timeout

	var last_time = 0.0
	for i in range(notes.size()):
		var chart_note = notes[i]
		var current_time = chart_note["time"]
		var delay = current_time - last_time
		if delay > 0.0:
			await get_tree().create_timer(delay).timeout

		var was_hit = false
		for recorded in recorded_notes:
			#var orig_time = recorded["time"] - recorded["error"] + note_travel_time
			if abs(recorded["orig_time"] - current_time) < 0.01:
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
			for pitch in chart_note["pitches"]:
				play_melody_sound(pitch, chart_note.get("duration", 1.0))

		last_time = current_time

func play_melody_sound(pitch: int, duration: float):
	$Player.play_note_sound(pitch, duration)

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
