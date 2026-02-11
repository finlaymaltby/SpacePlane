extends Node3D

const max_num_missiles = 100
@onready var missileScene : PackedScene = preload("res://scenes/missile.tscn")

var num_missiles : int = 0
var missile_id : int = 0
	
func reset() -> void:
	num_missiles = 0
	missile_id = 0
	for body in get_children():
		if body is Missile:
			body.queue_free()

func get_random_pos() -> Vector3:
	var centre = %Player.global_position
	var randp = centre + 2500*Vector3(randf_range(-1,1),randf_range(-1,1),randf_range(-1,1))
	return Vector3(clamp(randp.x,-5000,5000), clamp(randp.y, 0, 10000), clamp(randp.z,-5000,5000))

func spawn_missile() -> void:
	if not %Terrain.mesh_created:
		return
	var missile : CharacterBody3D = missileScene.instantiate()
	missile.name = "missile" + str(missile_id)
	missile.id = missile_id
	add_child(missile)
	missile.global_position = get_random_pos()
	while %Terrain.is_inside(missile.global_position):
		missile.global_position = get_random_pos()
	
	num_missiles += 1
	missile_id += 1
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if num_missiles < max_num_missiles:
		spawn_missile()
		
func _on_child_exiting_tree(node: Node) -> void:
	num_missiles -= 1
	missile_id = node.id

func _on_terrain_area_body_entered(body: Node3D) -> void:
	if body.collision_layer == 2:
		num_missiles -= 1
		missile_id = body.id
		body.queue_free()
