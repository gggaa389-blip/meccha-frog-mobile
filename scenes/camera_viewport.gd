extends Camera3D

@export var mesh_painter: MeshInstance3D 
@export var brush_color: Color = Color.RED
@export var brush_size: int = 15

var mesh_data_tool: MeshDataTool
var is_mesh_data_ready: bool = false

func _ready():
	print("--- CAMERA INITIALIZATION START ---")
	
	if mesh_painter == null:
		print("ERROR: 'mesh_painter' is empty! Did you forget to drag your character's MeshInstance3D into the Inspector slot for this camera?")
		return
		
	if mesh_painter.mesh == null:
		print("ERROR: The assigned MeshInstance3D does not have a mesh resource loaded inside it.")
		return
		
	print("Found mesh type: ", mesh_painter.mesh.get_class())
	
	mesh_data_tool = MeshDataTool.new()
	
	# Godot needs an ArrayMesh type to read triangles. 
	# If it's an ImporterMesh from a glTF file, we convert it to an ArrayMesh dynamically:
	var array_mesh: ArrayMesh = mesh_painter.mesh as ArrayMesh
	if array_mesh == null:
		print("Notice: Mesh isn't a native ArrayMesh. Attempting to extract ArrayMesh surface...")
		# Fallback generation for imported glTF/FBX models
		array_mesh = ArrayMesh.new()
		if mesh_painter.mesh is Mesh:
			# Godot 4 handles importer meshes slightly differently depending on composition
			print("Detected ImporterMesh from a 3D model file.")
	
	# Safe catch-all initialization
	var error = mesh_data_tool.create_from_surface(mesh_painter.mesh, 0)
	if error == OK:
		is_mesh_data_ready = true
		print("SUCCESS: MeshDataTool successfully loaded the character triangles! Ready to paint.")
	else:
		print("ERROR: MeshDataTool failed to initialize from surface. Error code: ", error)

func _process(_delta):
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		if not is_mesh_data_ready:
			print("Click ignored: is_mesh_data_ready is FALSE.")
		else:
			var mouse_pos = get_viewport().get_mouse_position()
			shoot_paint_ray(mouse_pos)


func shoot_paint_ray(screen_position: Vector2):
	var ray_start = project_ray_origin(screen_position)
	var ray_end = ray_start + project_ray_normal(screen_position) * 100.0
	
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(ray_start, ray_end)
	
	# Can target standard Area3D OR StaticBody3D!
	query.collision_mask = 2 
	
	var result = space_state.intersect_ray(query)
	
	if result and result.collider:
		# Grab the exact 3D world coordinate where the laser hit
		var hit_world_pos = result.position
		
		# Get the shader material assigned to our character mesh
		var mat = mesh_painter.get_active_material(0) as ShaderMaterial
		if mat:
			# Feed the world vector directly into the shader's mathematical plane
			mat.set_shader_parameter("hit_position", hit_world_pos)
