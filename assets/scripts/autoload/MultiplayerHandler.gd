extends Node

signal lobby_created

const DEFAULT_PORT = 8008
const DEFAULT_IP = "127.0.0.1"
var peer

var players: Dictionary[int, Dictionary] = {}
var lobby_id: int = 0

# [Mobile APK] Steam lobbies are desktop-only; phones use ENet.
func _is_mobile() -> bool:
	return OS.has_feature("mobile") or OS.get_name() == "Android" or OS.get_name() == "iOS"

func _steam_id() -> int:
	return 0 if _is_mobile() else Steam.getSteamID()

func _ready() -> void :
	if not _is_mobile():
		Steam.lobby_created.connect(on_steam_lobby_created)
		Steam.lobby_joined.connect(on_steam_lobby_joined)

	multiplayer.connected_to_server.connect(on_connected_to_server)
	multiplayer.peer_disconnected.connect(on_peer_left)



func create_server(server_type: Enums.server_type) -> void :
	# [Mobile APK] Fall back to ENet if Steam was picked on a phone.
	if _is_mobile() and server_type == Enums.server_type.steam:
		server_type = Enums.server_type.enet
	players.clear()
	match server_type:
		Enums.server_type.enet:
			peer = ENetMultiplayerPeer.new()
			peer.create_server(DEFAULT_PORT)

			multiplayer.multiplayer_peer = peer
			setup_player(Global.pdata, 1, _steam_id())
		Enums.server_type.steam:
			Steam.createLobby(Steam.LobbyType.LOBBY_TYPE_PUBLIC, 16)


func join_server(server_type: Enums.server_type, address: String) -> void :
	# [Mobile APK] Fall back to ENet if Steam was picked on a phone.
	if _is_mobile() and server_type == Enums.server_type.steam:
		server_type = Enums.server_type.enet
	players.clear()
	match server_type:
		Enums.server_type.enet:
			peer = ENetMultiplayerPeer.new()
			# [Mobile APK] Join the host typed in the lobby UI (e.g. its LAN
			# IP). The original code always used 127.0.0.1, so an ENet client
			# could never reach another device. Empty keeps the old default.
			var target_ip := address.strip_edges()
			var target_port := DEFAULT_PORT
			if ":" in target_ip:
				var parts := target_ip.rsplit(":", true, 1)
				if parts.size() == 2 and parts[1].is_valid_int():
					target_ip = parts[0]
					target_port = int(parts[1])
			if target_ip.is_empty():
				target_ip = DEFAULT_IP
			peer.create_client(target_ip, target_port)

			multiplayer.multiplayer_peer = peer
		Enums.server_type.steam:
			Steam.joinLobby(int(address))

@rpc("any_peer", "call_remote", "reliable")
func setup_player(pdata: Dictionary, pid: int, psteamID: int) -> void :
	if not players.has(pid):
		pdata.pid = pid
		pdata.steamID = psteamID
		players[pid] = pdata
		SignalBus.player_joined.emit(pid)
		print("%s has been setup" % pid)

	if multiplayer.is_server():
		for plr in players:
			setup_player.rpc(players[plr], plr, players[plr].steamID)
	print(players)

func on_connected_to_server() -> void :
	setup_player.rpc_id(1, Global.pdata, multiplayer.get_unique_id(), _steam_id())


func on_peer_left(pid) -> void :
	players.erase(pid)
	SignalBus.player_left.emit(pid)
	print("%s has left the game" % pid)

func client_disconnect() -> void :
	lobby_id = 0
	players.clear()
	peer = null
	multiplayer.multiplayer_peer = null
	get_tree().change_scene_to_file("res://assets/scenes/main_menu.tscn")
	print("you have left the game.")



func on_steam_lobby_created(result: int, new_lobby_id: int) -> void :
	if result == Steam.Result.RESULT_OK:
		lobby_id = new_lobby_id

		peer = SteamMultiplayerPeer.new()
		peer.debug_level = SteamMultiplayerPeer.DEBUG_LEVEL_PEER
		peer.host_with_lobby(lobby_id)
		multiplayer.multiplayer_peer = peer
		DisplayServer.clipboard_set(str(lobby_id))
		lobby_created.emit(str(lobby_id))
		setup_player(Global.pdata, 1, Steam.getSteamID())

func on_steam_lobby_joined(this_lobby_id: int, _permissions: int, _locked: bool, _response: int) -> void :
	if Steam.getLobbyOwner(this_lobby_id) == Steam.getSteamID():

		return


	peer = SteamMultiplayerPeer.new()
	peer.debug_level = SteamMultiplayerPeer.DEBUG_LEVEL_PEER
	peer.connect_to_lobby(this_lobby_id)
	multiplayer.multiplayer_peer = peer
	await multiplayer.connected_to_server
	setup_player.rpc_id(1, Global.pdata, multiplayer.get_unique_id(), Steam.getSteamID())
