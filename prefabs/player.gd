extends CharacterBody3D

# Movement variables
@export var SPEED: float = 5.0
@export var JUMP_VELOCITY: float = 4.5
@export var ACCELERATION: float = 10.0
@export var DECELERATION: float = 15.0

# Camera sensitivity
@export var MOUSE_SENSITIVITY: float = 0.003

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

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
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction based on standard UI actions (WASD or Arrow keys by default)
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	# Calculate direction relative to the TwistPivot's orientation
	var direction = (twist_pivot.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		# Smooth acceleration
		velocity.x = move_toward(velocity.x, direction.x * SPEED, ACCELERATION * delta)
		velocity.z = move_toward(velocity.z, direction.z * SPEED, ACCELERATION * delta)
	else:
		# Smooth friction/braking when no keys are pressed
		velocity.x = move_toward(velocity.x, 0, DECELERATION * delta)
		velocity.z = move_toward(velocity.z, 0, DECELERATION * delta)

	# Built-in Godot physics method that handles sliding along walls and ramps
	move_and_slide()
	
	# Press 'Escape' to free the mouse cursor
	if Input.is_action_just_pressed("ui_cancel"):
		if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			return

		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		
