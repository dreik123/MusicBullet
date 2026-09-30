extends CharacterBody2D

const RAYCAST_MARGIN = 100.0

@onready var muzzle = $Muzzle
@onready var aim_line = $AimLine
@onready var note_audio = $NoteAudio

func _ready():
	note_audio.stream = create_placeholder_note_stream()

# Temporary placeholder tone; replace with the final note sound sample.
func create_placeholder_note_stream():
	var sample_rate = 44100
	var sample_count = int(sample_rate * 0.15)
	var audio_data = PackedByteArray()
	audio_data.resize(sample_count * 2)

	for sample_index in sample_count:
		var time = float(sample_index) / sample_rate
		var envelope = 1.0 - float(sample_index) / sample_count
		var sample = int(sin(TAU * 261.6256 * time) * envelope * 32767.0)
		audio_data[sample_index * 2] = sample & 0xff
		audio_data[sample_index * 2 + 1] = (sample >> 8) & 0xff

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = audio_data
	return stream

func _process(delta):
	var mouse_pos = get_global_mouse_position()
	var mouse_dir = mouse_pos - global_position
	var mouse_angle_rad = mouse_dir.angle()
	var snapped_angle_rad = get_tree().current_scene._snap_angle_to_lane_rad(mouse_angle_rad)
	set_global_rotation(snapped_angle_rad)
	update_aim_line()

func get_raycast_length():
	return get_tree().current_scene.get_note_spawn_radius() + RAYCAST_MARGIN

func update_aim_line():
	aim_line.points = PackedVector2Array([
		muzzle.position,
		muzzle.position + Vector2.RIGHT * get_raycast_length()
	])
	
func _input(event):
	if event.is_action_pressed("shoot"):
		if get_tree().current_scene.get("level_ended"):
			return
		shoot()
		
func shoot():
	var main = get_tree().current_scene
	var shot_time = main.music_time
	var ray_start = muzzle.global_position
	var ray_direction = Vector2.RIGHT.rotated(global_rotation)
	var query = PhysicsRayQueryParameters2D.create(
		ray_start,
		ray_start + ray_direction * get_raycast_length()
	)
	query.collide_with_areas = true

	var ray_result = get_world_2d().direct_space_state.intersect_ray(query)
	if ray_result.is_empty():
		return

	var collider = ray_result["collider"]
	if collider.is_in_group("notes"):
		handle_note_hit(collider, shot_time)

func handle_note_hit(note, shot_time):
	# Play each pitch in the note's pitches array
	for pitch in note.pitches:
		note_audio.pitch_scale = pow(2.0, (pitch - 60) / 12.0)
		note_audio.play()

	var timing_error = shot_time - note.time
	var absolute_error = abs(timing_error)

	var accuracy = max(0.0, 1.0 - absolute_error / 0.5)
	var note_score = round(accuracy * 100)
	var recorded_note = {
		"pitches": note.pitches,
		"time": shot_time,
		"error": timing_error,
		"accuracy": accuracy,
		"score": note_score
	}
	
	get_tree().current_scene.recorded_notes.append(recorded_note)
	get_tree().current_scene.score += note_score
	
	#print("Записано нот:", get_tree().current_scene.recorded_notes)
	
	#print("Нота! pitch =", note.pitch, " time =", note.time)
	#print("Выстрел time =", shot_time, "Ошибка по времени =", timing_error)
	note.queue_free()
