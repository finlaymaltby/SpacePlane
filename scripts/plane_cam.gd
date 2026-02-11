extends Node3D

@onready var sensitivity = GlobalSettings.sensitivity

@export var max_dist = 25
@export var min_dist = 15
@export var angular_speed = 180

var is_moving : bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var player := $".."
	if Input.is_action_just_released("look"):
		is_moving = true
		
	var direction : Vector3 = player.velocity
	var up : Vector3 = player.basis.y
	
	if is_moving:
		var max_angle = deg_to_rad(angular_speed) * delta
		
		var curr_forward : Vector3 = -(player.basis * basis.z)
		var angle_forward = curr_forward.angle_to(player.velocity)
		if not angle_forward < max_angle:
			direction = curr_forward.rotated(curr_forward.cross(player.velocity).normalized(), max_angle)
		
		var curr_up : Vector3 = global_basis.y
		var angle_up = curr_up.angle_to(player.basis.y)
		if not angle_up < max_angle:
			up = curr_up.rotated(curr_up.cross(player.basis.y).normalized(), max_angle)
			
		if (angle_forward < max_angle) and (angle_up < max_angle):
			is_moving = false
			
	if not Input.is_action_pressed("look"):
		look_at(player.position + direction, up)
		
	var speedcent = player.velocity.length()/player.max_speed
	var distance = lerp(min_dist, max_dist, speedcent)
	$CameraBase.position = Vector3.BACK * distance
	

func _input(event):
	if event is InputEventMouseMotion and Input.is_action_pressed("look"):
		rotate(basis.y, event.relative.x * sensitivity/1000)
		rotate(basis.x, event.relative.y * sensitivity/1000)
		
