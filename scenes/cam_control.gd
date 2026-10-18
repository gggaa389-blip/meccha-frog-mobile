extends Node3D


# Camera sensitivity
@export var MOUSE_SENSITIVITY: float = 0.003

# Node references
@onready var twist_pivot: Node3D = $TwistPivot
@onready var pitch_pivot: Node3D = $TwistPivot/PitchPivot

func _ready():
	return
	# Capture the mouse so it doesn't click outside the game window
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event: InputEvent):
	# Handle mouse look
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		# Rotate the player body left/right
		twist_pivot.rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		# Tilt the camera up/down
		pitch_pivot.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
		
		# Clamp the vertical look so you can't flip upside down (-90 to 90 degrees)
		pitch_pivot.rotation.x = clamp(pitch_pivot.rotation.x, deg_to_rad(-80), deg_to_rad(80))

func _physics_process(delta: float):
	
	# Press 'Escape' to free the mouse cursor
	if Input.is_action_just_pressed("ui_cancel"):
		if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			return

		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		
