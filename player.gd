extends CharacterBody2D

@export var projectile_scene: PackedScene
@onready var muzzle = $Muzzle
func _process(delta):
	look_at(get_global_mouse_position())
	
func _input(event):
	if event.is_action_pressed("shoot"):
		shoot()
		
func shoot():

	var projectile = projectile_scene.instantiate()
	
	get_tree().current_scene.add_child(projectile)
	
	projectile.global_position = muzzle.global_position
	projectile.global_rotation = global_rotation
	
	projectile.shot_time = get_tree().current_scene.music_time
