extends CharacterBody2D

const RAYCAST_MARGIN = 100.0

@onready var muzzle = $Muzzle
@onready var aim_line = $AimLine

func _process(delta):
	look_at(get_global_mouse_position())
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
	var timing_error = shot_time - note.time
	var absolute_error = abs(timing_error)

	var accuracy = max(0.0, 1.0 - absolute_error / 0.5)
	var note_score = round(accuracy * 100)
	var recorded_note = {
		"pitch": note.pitch,
		"time": shot_time,
		"error": timing_error,
		"accuracy": accuracy,
		"score": note_score
	}
	
	get_tree().current_scene.recorded_notes.append(recorded_note)
	get_tree().current_scene.score += note_score
	
	print("Записано нот:", get_tree().current_scene.recorded_notes)
	
	print("Нота! pitch =", note.pitch, " time =", note.time)
	print("Выстрел time =", shot_time, "Ошибка по времени =", timing_error)
	note.queue_free()
