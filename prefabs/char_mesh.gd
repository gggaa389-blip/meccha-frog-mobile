extends MeshInstance3D
#
#var paint_image: Image
#var paint_texture: ImageTexture
#var material: StandardMaterial3D
#
#@export var texture_size: int = 1024
#@export var default_color: Color = Color.WHITE
#
##func _ready():
	##paint_image = Image.create(texture_size, texture_size, false, Image.FORMAT_RGBA8)
	##paint_image.fill(default_color)
	##
	### TEST LINE: Draw a giant bright red square right in the middle of the texture
	##paint_image.fill_rect(Rect2i(200, 200, 400, 400), Color.RED)
	##
	##paint_texture = ImageTexture.create_from_image(paint_image)
	##material = get_active_material(0) as StandardMaterial3D
	##material.albedo_texture = paint_texture
#
#func _ready():
	## 1. Create a blank image to act as the canvas
	#paint_image = Image.create(texture_size, texture_size, false, Image.FORMAT_RGBA8)
	#paint_image.fill(default_color)
	#
	## 2. Convert it into a texture Godot's renderer can use
	#paint_texture = ImageTexture.create_from_image(paint_image)
	#
	## 3. Get the material (make sure it's "Unique" in the inspector so characters don't share paint!)
	#material = get_active_material(0) as StandardMaterial3D
	#
	## 4. Assign our dynamic texture to the material's Albedo slot
	#material.albedo_texture = paint_texture
#
## The function called to actually apply paint pixels
#func paint_at_uv(uv: Vector2, brush_color: Color, brush_radius: int):
	## Convert 0.0-1.0 UV space to actual pixel coordinates
	#var pixel_x = int(uv.x * texture_size)
	#var pixel_y = int(uv.y * texture_size)
	#
	## Draw a filled circle on the image data
	#for x in range(-brush_radius, brush_radius):
		#for y in range(-brush_radius, brush_radius):
			#if x*x + y*y <= brush_radius*brush_radius: # Circle formula
				#var target_x = clamp(pixel_x + x, 0, texture_size - 1)
				#var target_y = clamp(pixel_y + y, 0, texture_size - 1)
				#paint_image.set_pixel(target_x, target_y, brush_color)
				#
	## Push the modified image data back to the GPU
	#paint_texture.update(paint_image)
