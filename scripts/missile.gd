class_name Missile extends CharacterBody3D

const max_speed : float = 700
const accel : float = 250 
@onready var drag : float = accel/max_speed
const detect_dist : float = 500
const detect_angle : float = 80
const detect_radius : float = detect_dist * atan(deg_to_rad(detect_angle))
const rot_speed : float = 50

@onready var player : Player = get_node("/root/Game/Player")
@onready var game : Game = get_node("/root/Game")

var speed : float = 0
var id : int = 0

enum SearchState {
	Searching,
	LockedTrail,
	LockedPlayer
}

var current_state : SearchState = SearchState.Searching

func _ready() -> void:
	$DetectionArea/DetectCollision.shape.height = detect_dist
	$DetectionArea/DetectCollision.shape.radius = detect_radius
	$DetectionArea.position = Vector3.FORWARD * detect_dist/2
	
	$SearchlightLight.spot_range = 2 * detect_dist
	speed = 1
	
	$Timer.wait_time += randf_range(-5, 10)
	$Timer.start()
	
func set_colour(colour: Color) -> void:
	var mat: StandardMaterial3D = $Searchlight.mesh.material
	mat.albedo_color = colour
	$SearchlightLight.light_color = colour
	
func within_angle(other : Vector3, angle : float) -> bool:
	return (-global_basis.z).angle_to(other - global_position) <= deg_to_rad(angle)
	
func has_los(other : Vector3) -> bool:
	$Ray.target_position = to_local(other)
	$Ray.force_raycast_update()
	if not $Ray.is_colliding():
		return false
	var mask = $Ray.get_collider().collision_layer
	return mask == 1
	
func aim_at(pos : Vector3, delta : float) -> void:
	if within_angle(pos, rot_speed * delta):
		look_at(pos)
	else:
		var target_dir : Vector3 = (pos - global_position).normalized()
		var axis = target_dir.cross(-global_basis.z).normalized()
		var new_dir = -global_basis.z.rotated(axis, -deg_to_rad(rot_speed * delta))
		look_at(global_position + new_dir)
				
func _physics_process(delta) -> void:
	var bodies : Array[Node3D] = $DetectionArea.get_overlapping_bodies()
	bodies = bodies.filter(func(n): return within_angle(n.global_position, detect_angle))
	bodies = bodies.filter(func(n): return has_los(n.global_position))
	
	current_state = SearchState.Searching
	
	var best_target : Node3D
	for body in bodies:
		if (body == player):
			current_state = SearchState.LockedPlayer
			best_target = body
			break
		current_state = SearchState.LockedTrail
		if (not best_target) or body.id > best_target.id:
			best_target = body
			
	speed = clampf(speed - drag * speed * delta, 0 , max_speed)
	
	match current_state: 
		SearchState.Searching:
			set_colour(Color.YELLOW)
			rotate(basis.x, deg_to_rad(rot_speed) * delta)
			rotate(basis.y, deg_to_rad(rot_speed) * delta / 2)
		SearchState.LockedTrail:
			$Timer.start()
			set_colour(Color.ORANGE)
			aim_at(best_target.global_position, delta)
			speed += 0.2 * accel * delta
		SearchState.LockedPlayer:
			$Timer.start()
			set_colour(Color(1, 30/255, 30/255))
			aim_at(best_target.global_position, delta)
			speed += accel * delta
			
	velocity = -basis.z * speed
	
	var coll := move_and_collide(velocity * delta)
	if coll:
		if coll.get_collider() == player:
			game.end_game()
	$AudioStreamPlayer3D.pitch_scale = speed/max_speed + 1
	
func apply_rotation(rot : Vector3):
	rotate(basis.z, deg_to_rad(rot.z))
	rotate(basis.x, deg_to_rad(rot.x))
	rotate(basis.y, deg_to_rad(rot.y))


func _on_timer_timeout() -> void:
	queue_free()
