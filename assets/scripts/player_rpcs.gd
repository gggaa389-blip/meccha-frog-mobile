extends Node

@onready var player: Player = get_owner()

@rpc("any_peer", "call_local", "reliable")
func die() -> void :
	player.local_death_set()

@rpc("authority", "call_local", "reliable")
func bahh() -> void :
	%SFX.get_node("baa").play()


@rpc("any_peer", "call_remote", "reliable")
func monster_spwned() -> void:
	$"../MonsterSpwndAudio".play()
	$"../Controller2/Camera/SpotLight3D".light_color = Color.ORANGE_RED
	$"../World/MonsterProp".hide()

func get_carried(pid: int) -> void:
	rpc_id(pid, "activate_carry")

#Make the player get carried
@rpc("authority", "call_local", "reliable")
func activate_carry() -> void:
	if multiplayer.get_remote_sender_id() != 1:
		return
	var victim: Node3D = GameHandler.world.get_node("Game/%s" % multiplayer.get_unique_id())
	victim.change_to_getting_carried()

func revive(pid: int) -> void:
	rpc_id(pid, "activate_revive")

#Make the player get revived
@rpc("any_peer", "call_local", "reliable")
func activate_revive() -> void:
	var victim: Node3D = GameHandler.world.get_node("Game/%s" % multiplayer.get_unique_id())
	victim.change_to_revived()

func get_dropped(pid: int) -> void:
	rpc_id(pid, "activate_drop")

#Make the player get dropped
@rpc("authority", "call_local", "reliable")
func activate_drop() -> void:
	if multiplayer.get_remote_sender_id() != 1:
		return
	var victim: Node3D = GameHandler.world.get_node("Game/%s" % multiplayer.get_unique_id())
	victim.change_to_normal()

@rpc("any_peer")
func request_action():
	rpc_id(1, "do_something")

func request_jumpscare() -> void:
	rpc_id(1, "launch_jumpscare")

@rpc("authority")
func do_something() -> void:
	if not multiplayer.is_server():
		return
	var victim: Node3D = get_tree().get_nodes_in_group("player")[0]
	victim.get_node("Controller2/Camera/SpotLight3D").light_color = Color.ORANGE_RED
	victim.get_node("MonsterSpwndAudio").play()
	victim.get_node("AnimationPlayer").play("light_change")
	victim.get_node("../World/MonsterProp").hide()

@rpc("authority")
func launch_jumpscare() -> void:
	if not multiplayer.is_server():
		return
	var victim: Node3D = get_tree().get_nodes_in_group("player")[0]
	victim.get_node("AnimationPlayer").play("jumpscare")
