extends Node3D
class_name Player

@export var speed: float = 4.5
@export var jumpVelocity = 4.5
@export var mouseSensitivity: float = .002
@export var verticalRotation: float = 0.0

@export var health: int = 100:
	set(value):
		health = value
		#$UI/Health.text = "Health: " + str(health)

@onready var camera: Camera3D = $Controller/TwistPivot/PitchPivot/Camera
@onready var anim_manager = $Controller/AnimManager
@onready var char_controller: CharacterBody3D = $Controller

@onready var twist_pivot: Node3D = $Controller/TwistPivot
@onready var pitch_pivot: Node3D = $Controller/TwistPivot/PitchPivot

#TODO: get rid of it
@onready var controller: CharacterBody3D = $Controller
@onready var hunter: Node3D = $Controller/Hunter
@onready var chameleon: Node3D = $Controller/Chameleon

@export var cur_velocity: Vector3


#@export var skin_idx: int = 0
#var clothes_skins: Array = ["res://assets/models/players/businessMaleA.png",
							#"res://assets/models/players/businessMaleB.png",
							#"res://assets/models/players/racerBlueMale.png",
							#"res://assets/models/players/racerOrangeFemale.png"]

var giraffe: Node3D = null

var jump_velocity: float = 4.5

var gravity_on: bool = true
var paint_on: bool = false:
	set(value):
		paint_on = value
		$Controller/Chameleon/AnimationTree.active = not paint_on
		%ColorPicker.visible = value #TODO: uncomment
		if paint_on: 
			return
		state = Enums.player_states.normal
		# [Mobile APK] Phones have no captured mouse: keep it visible.
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if _is_mobile() else Input.MOUSE_MODE_CAPTURED


var username: String = "ZooHair"
var pid: int = 1
var steamID: int = 0
var cosmetics: Array = []

var heals: int = 0:
	set(value):
		heals = value
		$UI/Teapots.text = "Teapots: " + str(heals)

var keys: int = 0:
	set(value):
		keys = value
		$UI/Keys.text = "Keys: " + str(keys)

var has_gun: bool = false:
	set(value):
		anim_manager.got_gun()
		has_gun = value
		$UI/Bullets.visible = value

var has_talkie: bool = false:
	set(value):
		has_talkie = value
		$UI/Talkie.visible = value

var talkie_on: bool = false:
	set(value):
		talkie_on = value
		#$Controller/Character/Root/Skeleton3D/HandL/Talkie.visible = value
		if talkie_on: $UI/Talkie.text = "(Q) Talkie ON"
		else: $UI/Talkie.text = "(Q) Talkie OFF"

var has_soda: bool = false:
	set(value):
		has_soda = value
		$UI/Revive.text = "Soda: %s" % int(value)
		$UI/Revive.visible = value

var can_carry: bool = false:
	set(value):
		if !anim_manager.is_giraffe: return
		can_carry = value
		$UI/Action.visible = value

var can_revive: bool = false:
	set(value):
		if anim_manager.is_giraffe: return
		can_revive = value
		$UI/Action.text = "Press F to Revive"
		$UI/Action.visible = value and has_soda

var target: CharacterBody3D = null

var is_on_manhole: bool = false:
	set(value):
		if anim_manager.is_giraffe:
			is_on_manhole = false
			return
		is_on_manhole = value and keys > 0
		$UI/Action.text = "Press F to Vault"
		$UI/Action.visible = value


var sheep_force: float = 100.0

var dead: bool = false:
	set(value):
		dead = value
		$Controller/CarryArea/CollisionShape3D.disabled = !value
var state: Enums.player_states = Enums.player_states.normal
var last_state: Enums.player_states = Enums.player_states.normal

var can_monster: bool = false

func _enter_tree() -> void :
	set_multiplayer_authority(pid)
	

func setup_cosmetics():
	for cosmetic in cosmetics:
		var model = get_node_or_null("%Cosmetics/" + cosmetic)
		if model:
			model.show()

func _ready() -> void :
	#$Controller/TalkieChatHandler.speak = false
	$UI/VFX/ColorRect.material.set("shader_parameter/vignette_strength", 0.0) #When player restarts the vignette remembers its state so i initialize it
	
	# [Mobile APK] No mouse capture on phones (touch drives the camera).
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if _is_mobile() else Input.MOUSE_MODE_CAPTURED
	Util.set_processes(self, false)

	name = str(pid)
	char_controller.get_node("usernameLabel").text = username
	setup_cosmetics()
	
	if pid == 1:
		health = 1000 #TODO: make it 1000
		#$UI/Teapots.hide()
		#$UI/Keys.hide()
		hunter.show()
		chameleon.hide()
		camera.position = Vector3(0, 1.5, -0.4)
		$Controller/CollisionShape3D.shape.height = 2.1
		$Controller/CollisionShape3D.position.y = 1.05
		#camera.reparent($Controller/Giraffe/metarig/Skeleton3D/Bone/CamMarker)
		#camera.position = Vector3.ZERO
		anim_manager.is_giraffe = true
		$Controller/usernameLabel.position.y = 2.5
		$Controller/VoicechatHandler/Sprite.position.y = 3.0
		$Controller/ShootAudio.stream = load("res://assets/audio/girraffe_shoot.wav")
	else:
		chameleon.show()
		hunter.hide()
		#camera.position = Vector3(0, 0.8, -0.2)
		#camera.reparent($Controller/Character/Root/Skeleton3D/Head/CamMarker)
		#camera.position = Vector3.ZERO
		$Controller/usernameLabel.position.y = 1.5
		$Controller/VoicechatHandler/Sprite.position.y = 2.0
		$Controller/ShootAudio.stream = load("res://assets/audio/ketchup_shoot.wav")
		$UI/VFX/Crosshair.hide()
	
	if not is_multiplayer_authority(): 
		$UI.hide()
		return
	#$Controller/Character/Root/Skeleton3D/Head.hide()
	#$Controller/Giraffe/metarig/Skeleton3D/Head.hide()
	#change player skin
	#set_player_skin(skin_idx)
	
	$Controller/Label3D.text = str(pid)
	
	Global.player = self
	char_controller.get_node("usernameLabel").hide()
	#char_controller.get_node("Camera").current = true
	camera.current = true
	#TODO: set position and rotation of the char_controller
	#controller.global_position = Vector3(0, 5, -18)
	#controller.global_rotation.y = -180
	Util.set_processes(self, true)
	# [Mobile APK] Local player on a phone gets the touch controls.
	if _is_mobile():
		_add_mobile_controls()


#func set_player_skin(skin_nbr: int):
	#var player_clothes: StandardMaterial3D = StandardMaterial3D.new()
	#player_clothes.albedo_texture = load(clothes_skins[skin_nbr])
	#player_clothes.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	#$Controller/Character/Root/Skeleton3D/Character.material_override = player_clothes
	#$Controller/Character/Root/Skeleton3D/Head.get_child(skin_nbr).show()


func _unhandled_input(event: InputEvent) -> void :
	if event is InputEventMouseButton and paint_on and event.is_pressed():
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	# Handle mouse look
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		
		if state == Enums.player_states.normal:
			if !paint_on:
				#Yaw
				char_controller.rotate_y(-event.relative.x * mouseSensitivity)

				#Pitch
				var delta_pitch = -event.relative.y * mouseSensitivity

				## Clamp the vertical rotation
				#verticalRotation += delta_pitch
				#verticalRotation = clamp(verticalRotation, deg_to_rad(-60), deg_to_rad(90))
#
				## Apply the clamped rotation to the camera pivot
				#camera.rotation.x = verticalRotation
				
				# Tilt the camera up/down
				pitch_pivot.rotate_x(-event.relative.y * mouseSensitivity)
			else:
				# Rotate the player body left/right
				twist_pivot.rotate_y(-event.relative.x * mouseSensitivity)
				# Tilt the camera up/down
				pitch_pivot.rotate_x(-event.relative.y * mouseSensitivity)
				
				# Clamp the vertical look so you can't flip upside down (-90 to 90 degrees)
				pitch_pivot.rotation.x = clamp(pitch_pivot.rotation.x, deg_to_rad(-80), deg_to_rad(80))
				
					


		
		#elif state == Enums.player_states.spectating:
			#var look_dir = event.relative * 0.01
			#%Freecam.rotation.y -= look_dir.x * 1.0 * 1.0
			#%Freecam.rotation.x = clamp( %Freecam.rotation.x - look_dir.y * 1.0 * 1.0, -1.5, 1.5)

func _input(event: InputEvent) -> void :
	if Input.is_action_just_pressed("talkie") and has_talkie:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		#activate_talkie()
	if Input.is_action_just_pressed('paint_mode'):
		paint_on = !paint_on
		twist_pivot.rotation_degrees.y = 0
		
	if Input.is_action_just_pressed('gravity_toggle'):
		gravity_on = !gravity_on
	if Input.is_action_just_pressed("ui_accept"):
		print("me: %s\nstate: %s" % [multiplayer.get_unique_id(), state])
	if  Input.is_action_just_pressed("run"):
		if pid == 1:
			speed = 8.0
		else:
			speed = 6.5
	if Input.is_action_just_released("run"):
		speed = 4.5
	if Input.is_action_just_pressed("drop") and pid == 1:
		if not target: return
		%RPCS.get_dropped(target.get_parent().pid)
		anim_manager.drop.rpc()
	#if Input.is_action_just_pressed("action"):
		#if is_on_manhole:
			#disactivate_talkie()
			#teleport_manhole()
		#elif can_revive and has_soda:
			#disactivate_talkie()
			#if target.get_owner().pid == 1: return
			#%RPCS.revive(target.get_parent().pid)
			#anim_manager.revive.rpc()
		#elif can_carry:
			#%RPCS.get_carried(target.get_parent().pid)
			#anim_manager.carry.rpc()
	if event.is_action_pressed("mute"):
		return #TODO: uncomment this
		$Controller/VoicechatHandler.speak = not $Controller/VoicechatHandler.speak
		$UI/Mic.visible = not $Controller/VoicechatHandler.speak
	if event.is_action_pressed("escape"):
		%PauseMenu.visible = ! %PauseMenu.visible
		if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE: #TODO: uncomment this
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		elif Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	#if event.is_action_pressed("monster_enter") and can_monster:
		#$Controller/monster.show()
		#%RPCS.request_action()
	#if event.is_action_pressed("jumpscare") and can_monster:
		#%RPCS.request_jumpscare()

#func activate_talkie() -> void:
	##stop normal voice and activate talkie and vice versa
	#$Controller/VoicechatHandler.speak = not $Controller/VoicechatHandler.speak
	#$UI/Mic.visible = not $Controller/VoicechatHandler.speak
	#talkie_on = !talkie_on
	#anim_manager.talkie_on.rpc(talkie_on)
	#$Controller/TalkieChatHandler.speak = talkie_on

#func disactivate_talkie() -> void:
	##stop normal voice and activate talkie and vice versa
	#$Controller/VoicechatHandler.speak = false
	#$UI/Mic.visible = false
	#talkie_on = false
	#anim_manager.talkie_on.rpc(false)
	#$Controller/TalkieChatHandler.speak = false

#func change_to_getting_carried() -> void:
	#giraffe = get_tree().get_first_node_in_group("player").get_node("CarryPos")
	#state = Enums.player_states.carried

#func change_to_revived() -> void:
	##print('revived me: %s' % pid)
	#anim_manager.revived.rpc()
	#health = 100
	#state = Enums.player_states.normal
	#camera.rotate_y(0.0)#
	#dead = false
	#SignalBus.player_revived.emit(pid)

#func change_to_normal() -> void:
	#controller.global_position.y = 0 #it was controller.global_position.y
	#camera.rotate_y(0.0)
	#state = Enums.player_states.spectating#TODO: the carried player is dead before getting carried

##Teleports the player to manhole
#func teleport_manhole() -> void:
	#var manhole: Node3D = $"../World".pick_rnd_manhole()
	#controller.global_position = manhole.global_position


func _physics_process(delta: float) -> void :
	#if not is_multiplayer_authority(): return
	#if dead and state != Enums.player_states.spectating:
		#state = Enums.player_states.spectating
	match (state):
		Enums.player_states.normal:
			
			if not controller.is_on_floor() and gravity_on:
				controller.velocity += controller.get_gravity() * delta
			
			if Input.is_action_just_pressed("jump") and controller.is_on_floor() and gravity_on:
				controller.velocity.y = jump_velocity

			# Camera directions
			var forward = camera.global_transform.basis.z
			forward.y = 0
			var right = camera.global_transform.basis.x
			right.y = 0
			var upward = camera.global_transform.basis.y
			upward.z = 0
			upward.x = 0
			
			# Get the input direction and handle the movement/deceleration.
			var input_dir := Vector3.ZERO
			
			input_dir += forward * Input.get_axis("forward", "backwards")
			input_dir += right * Input.get_axis("left", "right")
			
			if !gravity_on:
				input_dir += upward * Input.get_axis("downward", "upward")
			
			input_dir = input_dir.normalized()
			
			controller.velocity = input_dir * speed

			## Movement relative to camera
			#var direction = (forward * input_dir.y + right * input_dir.x).normalized()
			#
			##var direction := (controller.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
			#if direction:
				#controller.velocity.x = direction.x * speed
				#controller.velocity.z = direction.z * speed
			#else:
				#controller.velocity.x = move_toward(controller.velocity.x, 0, speed)
				#controller.velocity.z = move_toward(controller.velocity.z, 0, speed)
			
			cur_velocity = controller.velocity
			controller.move_and_slide()
			
		#Enums.player_states.carried:
			##controller.global_position = giraffe.global_position + Vector3(0, 1.4, 1)
			#controller.global_position = giraffe.global_position
			#controller.global_rotation = giraffe.global_rotation
		
		#TODO: Maybe we can change it to make the player able to spectate woth a moving camera
		Enums.player_states.spectating:
			#if not controller.is_on_floor():
				#controller.velocity += controller.get_gravity() * delta
			
			controller.velocity.x = move_toward(controller.velocity.x, 0, speed)
			controller.velocity.z = move_toward(controller.velocity.z, 0, speed)
			
			cur_velocity = controller.velocity
			controller.move_and_slide()
			
			camera.global_position = $Controller/Character/Root/Skeleton3D/Head.global_position + Vector3(0, .2, 0)
			


func hurt(damage: int) -> void:
	health -= damage
	if health <= 0:
		health = 0
		local_death()
	if not is_multiplayer_authority():
		return
	var vignette_pwr: float = 2 - (health * 0.02)
	$UI/VFX/ColorRect.material.set("shader_parameter/vignette_strength", vignette_pwr)
	camera.hit()
	$AnimationPlayer.play("hit")

func heal():
	#update red vignette
	var vignette_pwr: float = 2 - (health * 0.02)
	$"../../UI/VFX/ColorRect".material.set("shader_parameter/vignette_strength", vignette_pwr)

#func _on_death_area_body_entered(body: Node3D) -> void :
	#if not is_multiplayer_authority(): return
	#Data.give_achievement("Noob.")
	#local_death()

func local_death() -> void :
	if dead: return
	state = Enums.player_states.spectating
	%RPCS.die.rpc()
	#anim_manager.die.rpc()

func local_death_set() -> void :
	if dead: return
	state = Enums.player_states.spectating
	$Controller/DeadAudio.play()
	dead = true
	#controller.freeze = true
	#if pid != 1:
	SignalBus.player_died.emit(pid)
	
	anim_manager.die()
	#%VFX.get_node("Explosion").play("Explosion")
	#%SFX.get_node("explode").play()


@rpc("any_peer", "call_local", "reliable")
func force_kill():
	if multiplayer.get_remote_sender_id() != 1: return
	local_death_set()


func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.is_in_group("player") and body != controller:
		var _parent: Node3D = body.get_parent()
		#if _parent.state == Enums.player_states.spectating:
		_parent.can_carry = true
		_parent.target = controller
		#print("body: %s and target: %s" % [_parent.name, target.get_parent().name])
		if pid == 1: return
		_parent.can_revive = true


func _on_area_3d_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		var _parent: Node3D = body.get_parent()
		_parent.can_carry = false
		_parent.target = null
		_parent.can_revive = false
		


# ------------------------------------------------------------------
# [Mobile APK] Touch support (added for the Android build)
# ------------------------------------------------------------------

func _is_mobile() -> bool:
	return OS.has_feature("mobile") or OS.get_name() == "Android" or OS.get_name() == "iOS"


func _add_mobile_controls() -> void:
	if not is_multiplayer_authority():
		return
	if has_node("MobileControls"):
		return
	var script := load("res://assets/mobile/mobile_controls.gd") as GDScript
	if script == null:
		push_warning("[Mobile] mobile_controls.gd failed to load")
		return
	var controls := script.new() as CanvasLayer
	if controls == null:
		return
	if controls.has_method("set_player"):
		controls.call("set_player", self)
	add_child(controls)


## [Mobile APK] Called by the touch surface with drag pixels.
## Same yaw/pitch rules as the mouse code in _unhandled_input().
func mobile_look(relative: Vector2) -> void:
	if state != Enums.player_states.normal:
		return
	var sens := mouseSensitivity * 2.5
	if !paint_on:
		char_controller.rotate_y(-relative.x * sens)
	else:
		twist_pivot.rotate_y(-relative.x * sens)
	pitch_pivot.rotate_x(-relative.y * sens)
	pitch_pivot.rotation.x = clamp(pitch_pivot.rotation.x, deg_to_rad(-80), deg_to_rad(80))
