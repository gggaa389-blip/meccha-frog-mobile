extends Node

var char_bullet = load("res://assets/scenes/char_bullet.tscn")
var giraffe_bullet = load("res://assets/scenes/giraffe_bullet.tscn")

@onready var player: Node3D = $"../.."

@onready var controller: CharacterBody3D = $".."
@onready var anim_player: AnimationPlayer = $"../Chameleon/AnimationPlayer"
@onready var anim_player_monster: AnimationPlayer = $"../Hunter/AnimationPlayer"

@onready var anim_tree_giraffe: AnimationTree = $"../Hunter/AnimationTree"
@onready var anim_girf_state: AnimationNodeStateMachinePlayback = anim_tree_giraffe.get("parameters/Normal/StateMachine/playback")

@onready var anim_tree_char: AnimationTree = $"../Chameleon/AnimationTree"
@onready var anim_char_state: AnimationNodeStateMachinePlayback = anim_tree_char.get("parameters/Normal/StateMachine/playback")

var test: int

var bullets: int = 10:
	set(value):
		bullets = value
		$"../../UI/Bullets".text = "%s/10" % bullets

@export var is_giraffe: bool = false


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	#if not is_multiplayer_authority():
		#return
	if player.dead:
		return
	
	handle_char_mvmnt_anims()
	handle_action_inputs()


func handle_char_mvmnt_anims():
	var speed = player.cur_velocity.length()
	
	if speed < 0.1:
		anim_char_state.travel("Idle")
		anim_girf_state.travel("Idle")
	#elif speed < 5.0:
		#anim_char_state.travel("Walk")
		#anim_girf_state.travel("Walk")
	else:
		anim_char_state.travel("Walk")
		anim_girf_state.travel("Walk")


func handle_action_inputs():
	if not is_multiplayer_authority():
		return
	if Input.is_action_just_pressed("fire"):
		shoot.rpc()
		#print('here')
		
	if Input.is_action_just_pressed("heal"):
		get_owner().disactivate_talkie()
		heal.rpc()
	
	if Input.is_action_just_pressed("reload"):
		reload.rpc()


func got_gun() -> void:
	if is_giraffe:
		return
	anim_tree_char.set("parameters/Normal/has_gun/blend_amount", 1.0)

@rpc("authority", "call_local", "reliable")
func shoot() -> void :
	if is_giraffe:
		anim_tree_giraffe.set("parameters/Normal/Throw/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
		var bullet = giraffe_bullet.instantiate()
		player.camera.get_node("BulletMarker").add_child(bullet)
	#elif player.has_gun and bullets > 0:
		#anim_tree_char.set("parameters/Normal/Shoot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
		#var bullet = char_bullet.instantiate()
		#player.camera.get_node("BulletMarker").add_child(bullet)
		#bullets -= 1

@rpc("authority", "call_local", "reliable")
func reload() -> void:
	if is_giraffe or !player.has_gun:
		return
	anim_tree_char.set("parameters/Normal/Reload/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
	bullets = 10

@rpc("authority", "call_local", "reliable")
func talkie_on(on: bool) -> void:
	if is_giraffe or !player.has_talkie:
		return
	#anim_tree_char.set("parameters/Normal/talkie_on/blend_amount", float(on))
	#anim_tree_char.set("parameters/Death/talkie_on/blend_amount", float(on))
	if on: $"../../AnimationPlayer".play("talkie_on")
	else: $"../../AnimationPlayer".play("talkie_off")

@rpc("authority", "call_local", "reliable")
func revive() -> void :
	if is_giraffe:
		return
	$"../WakeUpAudio".play()
	anim_tree_char.set("parameters/Normal/Revive/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
	player.has_soda = false

@rpc("authority", "call_local", "reliable")
func revived() -> void :
	if is_giraffe:
		return
	anim_tree_char.get("parameters/playback").travel("Normal")


@rpc("authority", "call_local", "reliable")
func heal() -> void :
	if is_giraffe or player.heals <= 0:
		return
	$"../DeliciousAudio".play()
	anim_tree_char.set("parameters/Normal/Heal/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
	player.health += 20
	player.heals -= 1
	if player.health >= 100:
		player.health = 100

@rpc("authority", "call_local", "reliable")
func carry() -> void:
	anim_tree_giraffe.set("parameters/Normal/Carry/blend_amount", 1.0)

@rpc("authority", "call_local", "reliable")
func drop() -> void:
	anim_tree_giraffe.set("parameters/Normal/Carry/blend_amount", 0.0)

@rpc("authority", "call_local", "reliable")
func die():
	if is_giraffe:
		return
	anim_tree_char.get("parameters/playback").travel("Death")


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	player.has_gun = player.has_gun
		
