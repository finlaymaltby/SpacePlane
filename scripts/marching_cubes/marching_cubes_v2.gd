extends MeshInstance3D

# params
# no of voxels along each axis
@export var detail: int = 8
@export_range(-1,1) var isolevel: float = 0.1
@export var x_width: int = 1000
@export var y_height: int = 1000
@export var z_length: int = 1000
@export var min_noise_size: float = 80
@export var max_noise_size: float = 200

@export var noise_offset_x: float = 5000
@onready var resolution: int = detail * 8
@onready var min_noise_scale: float = 1/min_noise_size
@onready var max_noise_scale: float = 1/max_noise_size

# shader things
var rd: RenderingDevice
var shader: RID
var tri_buffer: RID
var param_buffer: RID
var pipeline: RID
var uniform_set: RID

# make da mesh
var vertices: PackedVector3Array = []
var normals: PackedVector3Array = []

@onready var mesh_created: bool = false

func _ready() -> void:
	init_shader()
	run_compute()
	retreive()
	make_mesh()

func init_shader():
	rd = RenderingServer.create_local_rendering_device()
	var shader_file := load("res://scripts/marching_cubes/marching_cubes.glsl")
	var shader_spirv: RDShaderSPIRV = shader_file.get_spirv()
	shader = rd.shader_create_from_spirv(shader_spirv)
	
	var max_tris_per_voxel := 5
	var num_voxels: int = pow(resolution, 3)
	var floats_per_tri := 16
	var bytes_per_float := 4
	var tri_buffer_size := bytes_per_float * floats_per_tri * max_tris_per_voxel * num_voxels
	tri_buffer = rd.storage_buffer_create(tri_buffer_size)
	var tri_uniform := RDUniform.new()
	tri_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	tri_uniform.binding = 0 # this needs to match the "binding" in our shader file
	tri_uniform.add_id(tri_buffer)
	
	var param_bytes := PackedFloat32Array([resolution, 
										   isolevel,
										   x_width,
										   y_height,
										   z_length,
										   min_noise_scale,
										   max_noise_scale,
										   noise_offset_x
											]).to_byte_array()
	param_buffer = rd.storage_buffer_create(param_bytes.size(), param_bytes)
	var param_uniform := RDUniform.new()
	param_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	param_uniform.binding = 1
	param_uniform.add_id(param_buffer)
	
	# Create a compute pipeline
	uniform_set = rd.uniform_set_create([tri_uniform, param_uniform], shader, 0) # the last parameter (the 0) needs to match the "set" in our shader file
	pipeline = rd.compute_pipeline_create(shader)
	
func run_compute() -> void:
	var compute_list := rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(compute_list, pipeline)
	rd.compute_list_bind_uniform_set(compute_list, uniform_set, 0)
	@warning_ignore("integer_division")
	rd.compute_list_dispatch(compute_list, resolution/8, resolution/8, resolution/8)
	rd.compute_list_end()
	
	rd.submit()
	

func retreive():
	rd.sync()
	# Read back the data from the buffer
	var tri_bytes := rd.buffer_get_data(tri_buffer)
	var tri_data := tri_bytes.to_float32_array()
	@warning_ignore("integer_division")
	for idx in range(len(tri_data) / 16):
		var i = 16 * idx
		vertices.append(Vector3(tri_data[i], tri_data[i+1], tri_data[i+2]))
		vertices.append(Vector3(tri_data[i+4], tri_data[i+5], tri_data[i+6]))
		vertices.append(Vector3(tri_data[i+8], tri_data[i+9], tri_data[i+10]))
		normals.append(Vector3(tri_data[i+12], tri_data[i+13], tri_data[i+14]))
		normals.append(Vector3(tri_data[i+12], tri_data[i+13], tri_data[i+14]))
		normals.append(Vector3(tri_data[i+12], tri_data[i+13], tri_data[i+14]))

func make_uvs() -> PackedVector2Array:
	var uvs: PackedVector2Array = []
	for vert in vertices:
		uvs.append(Vector2(0.5 + atan2(vert.x, vert.z)/(2*PI), vert.y/y_height))
	return uvs
	
func make_uv2s() -> PackedVector2Array:
	var uv2s: PackedVector2Array = []
	for vert in vertices:
		uv2s.append(Vector2(vert.x/x_width,vert.z/z_length))
	
	return uv2s
	
func make_mesh():
	var mesh_data := []
	mesh_data.resize(ArrayMesh.ARRAY_MAX)
	mesh_data[ArrayMesh.ARRAY_VERTEX] = vertices
	mesh_data[ArrayMesh.ARRAY_NORMAL] = normals
	mesh_data[ArrayMesh.ARRAY_TEX_UV] = make_uvs()
	mesh_data[ArrayMesh.ARRAY_TEX_UV2] = make_uv2s()

	mesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, mesh_data)
	$TerrainArea/TerrainCollision.shape = mesh.create_trimesh_shape()
	$TerrainArea/TerrainCollision.shape.backface_collision = true
	mesh_created = true
	%Player.reset()

func _notification(what: int) -> void:
	# Object destructor, triggered before the engine deletes this Node.
	if what == NOTIFICATION_PREDELETE:
		cleanup_gpu()

#free everything
func cleanup_gpu() -> void:
	rd.free_rid(pipeline)
	rd.free_rid(tri_buffer)
	rd.free_rid(param_buffer)
	rd.free_rid(shader)
	
	pipeline = RID()
	tri_buffer = RID()
	param_buffer = RID()
	shader = RID()
	
	rd.free()
	rd = null

# Warning: hacky
func is_inside(pos: Vector3) -> bool:
	if not mesh_created:
		return true
		
	var ray := RayCast3D.new()
	add_child(ray)
	ray.exclude_parent = false
	ray.hit_from_inside = true
	ray.collide_with_areas = true
	ray.collide_with_bodies = false
	ray.collision_mask = pow(2, 3-1)
	
	var dir := (Vector3(0, 5000, 0) - pos).normalized()
	ray.global_position = pos
	ray.target_position = 10000 * dir + Vector3(0, 5000, 0) 
	ray.hit_back_faces = true
	ray.force_raycast_update()
	var point: Vector3 = ray.get_collision_point()
	if not point:
		breakpoint
	
	ray.hit_back_faces = false
	ray.force_raycast_update()
	var point2: Vector3 = ray.get_collision_point()
	ray.queue_free()
	if not point2:
		return true
	return point.distance_squared_to(point2) >= 0.001
