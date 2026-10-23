extends Node2D

@export var note_scene: PackedScene

const ChartImporter = preload("res://chart_importer.gd")


const NOTE_SPAWN_MARGIN = 100.0

const LANE_COUNT = 8

# Lane limiting: notes that arrive within LANE_WINDOW seconds of each other may use at most
# MAX_LANES_IN_WINDOW different lanes. Only the direction of a note is changed, never its
# time or its pitch.
const LANE_WINDOW = 1.0
const MAX_LANES_IN_WINDOW = 2

# UI texts (change here to rename or translate)
const TXT_TITLE = "MusicBullet"
const TXT_START = "Start"
const TXT_QUIT = "Quit"
const TXT_SCORE = "Score: %d"
const TXT_RESULTS_TITLE = "Level complete"
const TXT_RESULTS_SCORE = "Score: %d"
const TXT_RESULTS_HITS = "Hits: %d / %d"
const TXT_PLAY_AGAIN = "Play again"
const TXT_MENU = "Menu"
const TXT_LOAD_MELODY = "Load melody"
const TXT_BUILT_IN_MELODY = "Built-in melody"
const TXT_MELODY_LABEL = "Melody: %s"
const TXT_MELODY_INFO = "%d notes, %d s"
const TXT_BUILT_IN_TITLE = "FirstLevel (built-in)"
const TXT_DIALOG_TITLE = "Choose a MusicXML file"
const TXT_DIALOG_FILTER = "*.mxl, *.musicxml, *.xml ; MusicXML files"

# Score of one perfect hit (must match the maximum score given by player.gd).
const MAX_SCORE_PER_NOTE = 100.0

# Rank thresholds: minimum percent of the maximum possible score, best rank first.
const RANKS = [
	{"name": "SSS", "min_percent": 95.0},
	{"name": "SS", "min_percent": 90.0},
	{"name": "S", "min_percent": 80.0},
	{"name": "A", "min_percent": 70.0},
	{"name": "B", "min_percent": 60.0},
	{"name": "C", "min_percent": 50.0},
	{"name": "D", "min_percent": 40.0},
	{"name": "E", "min_percent": 25.0},
	{"name": "F", "min_percent": 0.0},
]

var music_time = 0.0
var next_note_index = 0
var recorded_notes = []
var score = 0
var note_travel_time = 3.5
var level_ended = false
var playing = false
var _ui: CanvasLayer
var _menu: Control
var _start_button: Button
var _score_label: Label
var _results: Control
var _results_rank_label: Label
var _results_score_label: Label
var _results_hits_label: Label
var _play_again_button: Button
var _playback_id = 0
var _default_notes = []
var _custom_melody = false
var _melody_title = ""
var _melody_label: Label
var _message_label: Label
var _built_in_button: Button
var _file_dialog: FileDialog
var _min_pitch = 0
var _max_pitch = 127
var _lane_speed = []

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
	_default_notes = notes.duplicate(true)
	prepare_chart()
	create_miss_boundary()
	_build_ui()
	get_window().files_dropped.connect(_on_files_dropped)
	show_menu()

# Computes everything that depends only on the chart (and the screen size).
func prepare_chart():
	_min_pitch = 127
	_max_pitch = 0
	for note in notes:
		for pitch in note["pitches"]:
			_min_pitch = min(_min_pitch, pitch)
			_max_pitch = max(_max_pitch, pitch)

	_assign_lanes()

	for i in range(notes.size()):
		if i == 0:
			notes[i]["travel_time"] = 3.0
		else:
			var gap = notes[i]["time"] - notes[i-1]["time"]
			notes[i]["travel_time"] = clamp(remap(gap, 0.25, 1.25, 1.2, 3.0), 1.2, 3.0)

	_lane_speed.clear()
	var player_pos_for_lanes = $Player.global_position
	for lane in range(LANE_COUNT):
		var lane_angle = -180.0 + lane * (360.0 / LANE_COUNT)
		var lane_direction = Vector2.from_angle(deg_to_rad(lane_angle))
		var visible_length = _ray_viewport_exit_distance(player_pos_for_lanes, lane_direction)
		_lane_speed.append((visible_length + NOTE_SPAWN_MARGIN) / 1.2)

func show_menu():
	playing = false
	_playback_id += 1
	_results.visible = false
	_clear_notes()
	$Player.visible = false
	_score_label.visible = false
	_menu.visible = true
	_start_button.grab_focus()

func start_game():
	_playback_id += 1
	_results.visible = false
	_clear_notes()
	recorded_notes = []
	score = 0
	_update_score_label()
	_score_label.visible = true
	next_note_index = 0
	level_ended = false
	music_time = -note_travel_time
	_menu.visible = false
	$Player.visible = true
	playing = true

func _clear_notes():
	for note in get_tree().get_nodes_in_group("notes"):
		note.queue_free()

func _build_ui():
	_ui = CanvasLayer.new()
	_ui.layer = 10
	add_child(_ui)
	_build_menu()
	_build_hud()
	_build_results()
	_build_file_dialog()

func _build_menu():
	_menu = CenterContainer.new()
	_ui.add_child(_menu)
	_menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 16)
	_menu.add_child(box)

	var title = Label.new()
	title.text = TXT_TITLE
	title.add_theme_font_size_override("font_size", 72)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)

	_melody_label = Label.new()
	_melody_label.add_theme_font_size_override("font_size", 24)
	_melody_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_melody_label)

	_start_button = Button.new()
	_start_button.text = TXT_START
	_start_button.custom_minimum_size = Vector2(260, 60)
	_start_button.pressed.connect(_on_start_pressed)
	box.add_child(_start_button)

	var load_button = Button.new()
	load_button.text = TXT_LOAD_MELODY
	load_button.custom_minimum_size = Vector2(260, 60)
	load_button.pressed.connect(_on_load_pressed)
	box.add_child(load_button)

	_built_in_button = Button.new()
	_built_in_button.text = TXT_BUILT_IN_MELODY
	_built_in_button.custom_minimum_size = Vector2(260, 60)
	_built_in_button.pressed.connect(_use_built_in_melody)
	box.add_child(_built_in_button)

	var quit_button = Button.new()
	quit_button.text = TXT_QUIT
	quit_button.custom_minimum_size = Vector2(260, 60)
	quit_button.pressed.connect(_on_quit_pressed)
	box.add_child(quit_button)

	_message_label = Label.new()
	_message_label.add_theme_font_size_override("font_size", 20)
	_message_label.add_theme_color_override("font_color", Color(1.0, 0.45, 0.45))
	_message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_message_label.custom_minimum_size = Vector2(520, 0)
	box.add_child(_message_label)

	_update_melody_ui()

func _build_file_dialog():
	_file_dialog = FileDialog.new()
	_file_dialog.title = TXT_DIALOG_TITLE
	_file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	_file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	_file_dialog.filters = PackedStringArray([TXT_DIALOG_FILTER])
	_file_dialog.size = Vector2i(900, 550)
	_file_dialog.file_selected.connect(_on_melody_file_selected)
	add_child(_file_dialog)

func _on_load_pressed():
	_file_dialog.popup_centered()

func _on_melody_file_selected(path):
	_load_melody(path)

# Dropping a file on the window loads it too (only while the menu is open).
func _on_files_dropped(files):
	if _menu.visible and files.size() > 0:
		_load_melody(files[0])

func _load_melody(path):
	var result = ChartImporter.import_file(path)
	if not result["ok"]:
		_set_message(result["error"])
		return
	notes = result["notes"]
	_melody_title = result["title"]
	_custom_melody = true
	prepare_chart()
	_update_melody_ui()
	_set_message("")

func _use_built_in_melody():
	notes = _default_notes.duplicate(true)
	_custom_melody = false
	prepare_chart()
	_update_melody_ui()
	_set_message("")

func _update_melody_ui():
	var title = TXT_BUILT_IN_TITLE
	if _custom_melody:
		title = _melody_title
	var last_note = notes.back()
	var length = last_note["time"] + last_note["duration"]
	var line_one = TXT_MELODY_LABEL % title
	var line_two = TXT_MELODY_INFO % [notes.size(), int(length)]
	_melody_label.text = line_one + "\n" + line_two
	_built_in_button.visible = _custom_melody

func _set_message(text):
	_message_label.text = text

func _build_hud():
	_score_label = Label.new()
	_score_label.add_theme_font_size_override("font_size", 40)
	_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_score_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_score_label.custom_minimum_size = Vector2(0, 64)
	_ui.add_child(_score_label)
	_score_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_score_label.visible = false

func _build_results():
	_results = CenterContainer.new()
	_ui.add_child(_results)
	_results.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_results.visible = false

	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	_results.add_child(box)

	var title = Label.new()
	title.text = TXT_RESULTS_TITLE
	title.add_theme_font_size_override("font_size", 40)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)

	_results_rank_label = Label.new()
	_results_rank_label.add_theme_font_size_override("font_size", 200)
	_results_rank_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_results_rank_label)

	_results_score_label = Label.new()
	_results_score_label.add_theme_font_size_override("font_size", 36)
	_results_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_results_score_label)

	_results_hits_label = Label.new()
	_results_hits_label.add_theme_font_size_override("font_size", 28)
	_results_hits_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_results_hits_label)

	_play_again_button = Button.new()
	_play_again_button.text = TXT_PLAY_AGAIN
	_play_again_button.custom_minimum_size = Vector2(260, 60)
	_play_again_button.pressed.connect(_on_start_pressed)
	box.add_child(_play_again_button)

	var menu_button = Button.new()
	menu_button.text = TXT_MENU
	menu_button.custom_minimum_size = Vector2(260, 60)
	menu_button.pressed.connect(show_menu)
	box.add_child(menu_button)

func _show_results():
	_clear_notes()
	$Player.visible = false
	_score_label.visible = false
	var max_score = notes.size() * MAX_SCORE_PER_NOTE
	var percent = 0.0
	if max_score > 0.0:
		percent = 100.0 * score / max_score
	_results_rank_label.text = get_rank(percent)
	_results_score_label.text = TXT_RESULTS_SCORE % int(score)
	_results_hits_label.text = TXT_RESULTS_HITS % [recorded_notes.size(), notes.size()]
	_results.visible = true
	_play_again_button.grab_focus()

func get_rank(percent):
	for rank in RANKS:
		if percent >= rank["min_percent"]:
			return rank["name"]
	return RANKS[RANKS.size() - 1]["name"]

# Called by the Player after every hit.
func add_score(points):
	score += points
	_update_score_label()

func _update_score_label():
	_score_label.text = TXT_SCORE % int(score)

func _on_start_pressed():
	start_game()

func _on_quit_pressed():
	get_tree().quit()

func _get_lane_index_for_pitch(pitch):
	var range_size = max(_max_pitch - _min_pitch, 1)
	var t = float(pitch - _min_pitch) / float(range_size)
	return clamp(int(floor(t * LANE_COUNT)), 0, LANE_COUNT - 1)

# Gives every chart entry a lane. The natural lane comes from the highest pitch of the entry.
# If that would put more than MAX_LANES_IN_WINDOW different lanes inside LANE_WINDOW seconds,
# the entry is moved to the nearest lane that is already in use.
func _assign_lanes():
	var recent = []
	for note in notes:
		var natural = _get_lane_index_for_pitch(_highest_pitch(note["pitches"]))

		while not recent.is_empty() and note["time"] - recent[0]["time"] > LANE_WINDOW:
			recent.pop_front()

		# Lanes used inside the window, the most recently used lane first.
		var lanes_used = []
		for i in range(recent.size() - 1, -1, -1):
			if not lanes_used.has(recent[i]["lane"]):
				lanes_used.append(recent[i]["lane"])

		var lane = natural
		if not lanes_used.has(natural) and lanes_used.size() >= MAX_LANES_IN_WINDOW:
			lane = _closest_lane(natural, lanes_used)

		note["lane"] = lane
		recent.append(note)

func _closest_lane(natural, lanes_used):
	var best = lanes_used[0]
	var best_distance = _circular_lane_distance(natural, best)
	for lane in lanes_used:
		var distance = _circular_lane_distance(natural, lane)
		if distance < best_distance:
			best = lane
			best_distance = distance
	return best

func _circular_lane_distance(a, b):
	var distance = abs(a - b)
	return min(distance, LANE_COUNT - distance)

func _highest_pitch(pitches):
	var highest = pitches[0]
	for p in pitches:
		if p > highest:
			highest = p
	return highest

func create_miss_boundary():
	var miss_boundary = load("res://miss_boundary.gd").new()
	miss_boundary.name = "MissBoundary"
	$Player.add_child(miss_boundary)

func _snap_angle_to_lane(angle_degrees: float) -> float:
	var lane_size = 360.0 / LANE_COUNT
	var lane = round(angle_degrees / lane_size)
	return lane * lane_size

func _snap_angle_to_lane_rad(angle_rad: float) -> float:
	var angle_deg = rad_to_deg(angle_rad)
	var snapped_deg = _snap_angle_to_lane(angle_deg)
	return deg_to_rad(snapped_deg)

func _process(delta):
	if not playing or level_ended:
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
	var lane = note_data["lane"]
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
	_show_results()
	play_recorded_melody()

func play_recorded_melody():
	_playback_id += 1
	var my_id = _playback_id
	await get_tree().create_timer(1.0).timeout
	if my_id != _playback_id:
		return

	var last_time = 0.0
	for i in range(notes.size()):
		var chart_note = notes[i]
		var current_time = chart_note["time"]
		var delay = current_time - last_time
		if delay > 0.0:
			await get_tree().create_timer(delay).timeout
			if my_id != _playback_id:
				return

		var was_hit = false
		for recorded in recorded_notes:
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
