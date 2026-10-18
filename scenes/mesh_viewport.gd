extends MeshInstance3D

@onready var paint_viewport: SubViewport = $PaintViewport
@onready var canvas: Control = $PaintViewport/Canvas

var material: StandardMaterial3D

func _ready():
	# Wait a split second for nodes to initialize
	await get_tree().process_frame
	
	material = get_active_material(0) as StandardMaterial3D
	# Put the viewport live texture directly onto the 3D character skin
	material.albedo_texture = paint_viewport.get_texture()

func paint_at_uv(uv: Vector2, brush_color: Color, brush_size: int):
	# Create a tiny 2D square to act as a paint stamp
	var brush = ColorRect.new()
	brush.color = brush_color
	brush.size = Vector2(brush_size, brush_size)
	
	# Map the 0.0-1.0 UV coordinate directly to our 1024x1024 viewport pixels
	var pixel_pos = uv * Vector2(paint_viewport.size)
	brush.position = pixel_pos - (brush.size / 2.0)
	
	# Stamp it onto the canvas!
	canvas.add_child(brush)


# Godot natively provides this function for pickable 3D objects!
func _input_event(camera, event, position, normal, shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Godot handles the heavy vertex lifting behind the scenes here
		var uv = camera.project_position_to_uv(position, self) 
		if uv != Vector2(-1, -1):
			paint_at_uv(uv, Color.RED, 15)
