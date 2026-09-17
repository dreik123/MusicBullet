extends Area2D


@export var speed = 500.0
var shot_time = 0.0

func _process(delta):
	position += Vector2.RIGHT.rotated(rotation) * speed * delta
	
func _on_area_entered(area):
	if area.is_in_group("notes"):
		var timing_error = shot_time - area.time
		var absolute_error = abs(timing_error)
		
		var accuracy = max(0.0, 1.0 - absolute_error / 0.5)
		var note_score = round(accuracy * 100)
		var recorded_note = {
			"pitch": area.pitch,
			"time": shot_time,
			"error": timing_error,
			"accuracy": accuracy,
			"score": note_score
		}
		
		get_tree().current_scene.recorded_notes.append(recorded_note)
		get_tree().current_scene.score += note_score
		
		print("Записано нот:", get_tree().current_scene.recorded_notes)
		
		print("Нота! pitch =", area.pitch, " time =", area.time)
		print("Выстрел time =", shot_time, "Ошибка по времени =", timing_error)
		area.queue_free()
		queue_free()
