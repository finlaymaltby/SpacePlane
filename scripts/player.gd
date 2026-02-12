class_name Player extends CharacterBody3D

# fastest speed horizontally m/s
@export var max_speed : float = 1390.47 / 3.6
@export var accel : float = 60  #ms^-2
@export var wing_drag : float = 0.02
@export var tail_drag : float = 0.01

#degrees per second
@export var yaw_speed : float = 30
@export var pitch_speed : float = 100
@export var roll_speed : float = 120

# values :
@onready var drag : float = accel/max_speed 
var thrust : float = 1
var rot_vel : Vector3
var rot_speed : Vector3
var rot_accel : Vector3 
var scent_id : int = 0

# extern stuff
@onready var thrust_light_energy = $EngineLight.light_energy
@onready var scent_marker : PackedScene = preload("res://scenes/scent_marker.tscn")

func get_random_position() -> Vector3:
	var pos = Vector3(randf_range(-5000, 5000),
					  randf_range(0, 10000),
					  randf_range(-5000, 5000))
	return pos

func reset() -> void: 
	$ScentTimer.start()
	velocity = Vector3.FORWARD * 50
	rotation = Vector3.ZERO
	
	global_position = get_random_position()
	while %Terrain.is_inside(global_position):
		global_position = get_random_position()
		
	
	rot_vel = Vector3(0,0,0)
	rot_speed = Vector3(pitch_speed, yaw_speed, roll_speed)
	rot_accel = rot_speed/0.5
	
	for child in get_children():
		if child is ScentMarker:
			child.queue_free()
	
	scent_id = 0
	
func get_rotations(delta) -> void:
	var rot_dir = Vector3.ZERO
	
	rot_dir.x = Input.get_axis("pitch_down", "pitch_up")
	rot_dir.z = Input.get_axis("roll_right", "roll_left")
	rot_dir.y = Input.get_axis("yaw_right", "yaw_left")
	
	var eff = abs(basis.z.dot(velocity.normalized()))
	rot_vel += rot_dir * eff * rot_accel * delta



func _physics_process(delta: float) -> void:
	thrust = $PlaneUI/Thrust/ThrustSlider.value
	#thrust
	velocity += -basis.z * accel * thrust * delta
	#forward drag
	velocity += basis.z * drag * velocity.dot(-basis.z) * delta
	#wing
	var vy = velocity.dot(basis.y)
	velocity += -sign(vy) * basis.y * clamp(wing_drag * pow(vy,2) * delta, 0, abs(vy))
	#tail
	var vx = velocity.dot(basis.x)
	velocity += -sign(vx) * basis.x * clamp(tail_drag * pow(vx,2) * delta, 0, abs(vx))
	
	# apply rotations
	get_rotations(delta)
	rot_vel -= rot_vel * rot_accel/rot_speed * delta
	apply_rotation(rot_vel * delta)
	
	update_display(delta)
	
	$AudioStreamPlayer3D.volume_db = log(thrust)*2 - 10
	move_and_slide()

func update_display(delta: float) -> void:
	$PlaneUI/InfoDisplay/Speed.text = "Speed: " + str(round(3.6*velocity.length()))
	$PlaneUI/InfoDisplay/FPS.text = "FPS: " + str(round(1/delta))

func apply_rotation(rot: Vector3):
	rotate(basis.z, deg_to_rad(rot.z))
	rotate(basis.x, deg_to_rad(rot.x))
	rotate(basis.y, deg_to_rad(rot.y))

func _on_scent_timer_timeout() -> void:
	var scent = scent_marker.instantiate()
	scent.id = scent_id
	get_parent().add_child(scent)
	scent.global_position = global_position
	scent_id += 1


func _on_terrain_area_body_entered(body: Node3D) -> void:
	if body != self:
		return
	$"..".end_game()
