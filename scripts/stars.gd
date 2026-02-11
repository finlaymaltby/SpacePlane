extends Node3D

const num_stars = 1000
const dist = 10000

@onready var material: StandardMaterial3D = preload("res://resources/star_material.tres")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	
	for i in range(num_stars):
		var star := MeshInstance3D.new()
		var shape := SphereMesh.new()
		shape.radius = 12
		shape.height = 24
		shape.material = material
		
		add_child(star)
		
		star.mesh = shape
		
		var pos := Vector3(rng.randf()-0.5, rng.randf()-0.5, rng.randf()-0.5)
		var centre := Vector3(0, 5000, 0 )
		
		star.global_position = centre + dist * pos.normalized()
