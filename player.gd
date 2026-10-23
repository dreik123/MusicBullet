extends CharacterBody2D

const RAYCAST_MARGIN = 100.0

# Holding the shoot button fires automatically at the first note on the aimed lane, but only at
# that note's ideal moment, and it gives at most HOLD_MAX_ACCURACY of the points.
# A well-timed single click can still score the full 100%.
const HOLD_MAX_ACCURACY = 0.5
const HOLD_TOLERANCE = 0.08  # seconds after the ideal moment in which a held shot may hit

@onready var muzzle = $Muzzle
@onready var aim_line = $AimLine
@onready var note_audio = $NoteAudio

func _ready():
	note_audio.stream = load("res://note_piano.wav")

func _process(delta):
	var mouse_pos = get_global_mouse_position()
	var mouse_dir = mouse_pos - global_position
	var mouse_angle_rad = mouse_dir.angle()
	var snapped_angle_rad = get_tree().current_scene._snap_angle_to_lane_rad(mouse_angle_rad)
	set_global_rotation(snapped_angle_rad)
	update_aim_line()

	if Input.is_action_pressed("shoot"):
		_hold_fire(delta)

func get_raycast_length():
	return get_tree().current_scene.get_note_spawn_radius() + RAYCAST_MARGIN

func update_aim_line():
	aim_line.points = PackedVector2Array([
		muzzle.position,
		muzzle.position + Vector2.RIGHT * get_raycast_length()
	])

func _input(event):
	if event.is_action_pressed("shoot"):
		var main = get_tree().current_scene
		if not main.get("playing") or main.get("level_ended"):
			return
		shoot()

# Casts the instant ray along the aimed lane. The ray stops at the screen edge, so notes
# outside the visible area cannot be hit. Returns the first note on the ray, or null.
func _cast_ray():
	var main = get_tree().current_scene
	var ray_start = muzzle.global_position
	var ray_direction = Vector2.RIGHT.rotated(global_rotation)
	var visible_distance = main._ray_viewport_exit_distance(ray_start, ray_direction)
	var ray_length = min(get_raycast_length(), visible_distance)
	var query = PhysicsRayQueryParameters2D.create(
		ray_start,
		ray_start + ray_direction * ray_length
	)
	query.collide_with_areas = true

	var ray_result = get_world_2d().direct_space_state.intersect_ray(query)
	if ray_result.is_empty():
		return null

	var collider = ray_result["collider"]
	if collider.is_in_group("notes"):
		return collider
	return null

func shoot():
	var note = _cast_ray()
	if note != null:
		handle_note_hit(note, get_tree().current_scene.music_time)

# Called every frame while the shoot button is held.
func _hold_fire(delta):
	var main = get_tree().current_scene
	if not main.get("playing") or main.get("level_ended"):
		return
	var note = _cast_ray()
	if note == null:
		return
	var late_by = main.music_time - note.get_ideal_time()
	if late_by >= 0.0 and late_by <= max(HOLD_TOLERANCE, delta * 2.0):
		handle_note_hit(note, main.music_time, HOLD_MAX_ACCURACY)

func play_note_sound(pitch: int, duration: float):
	var player = AudioStreamPlayer.new()
	player.stream = note_audio.stream
	player.pitch_scale = pow(2.0, (pitch - 60) / 12.0)
	add_child(player)
	player.play()
	var tween = create_tween()
	tween.tween_interval(duration)
	tween.tween_property(player, "volume_db", -40.0, 0.25)
	tween.tween_callback(player.queue_free)

func handle_note_hit(note, shot_time, max_accuracy = 1.0):
	# A note that was already hit this frame must not be scored twice.
	if note.is_queued_for_deletion():
		return

	# Play each pitch in the note's pitches array
	for pitch in note.pitches:
		play_note_sound(pitch, note.duration)

	var timing_error = shot_time - note.get_ideal_time()
	var absolute_error = abs(timing_error)

	var accuracy = min(max(0.0, 1.0 - absolute_error / 0.5), max_accuracy)
	var note_score = round(accuracy * 100)
	var recorded_note = {
		"pitches": note.pitches,
		"time": shot_time,
		"error": timing_error,
		"accuracy": accuracy,
		"score": note_score,
		"orig_time": note.arrival_time
	}

	get_tree().current_scene.recorded_notes.append(recorded_note)
	get_tree().current_scene.add_score(note_score)

	note.queue_free()
