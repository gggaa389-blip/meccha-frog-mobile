extends Control

signal data_is_sent

var player_data: Dictionary

func _ready() -> void :
	#print(true and false)
	#print(false and false)
	#print(true and true)
	
	if Data.data.game.first_launch:
		Data.data.game.first_launch = false
		# [Mobile APK] There is no Steam persona on phones: use a local name.
		if OS.has_feature("mobile") or OS.get_name() == "Android" or OS.get_name() == "iOS":
			Data.data.settings.username = "Mobile Player"
			Global.pdata.username = Data.data.settings.username
		else:
			Data.data.settings.username = Steam.getPersonaName()
		Data.save()
	
	MultiplayerHandler.lobby_created.connect(_on_lobby_created)


func get_computer_username() -> String:
	var username = ""
	
	if OS.has_environment("USERNAME"): # Works for Windows
		username = OS.get_environment("USERNAME")
	elif OS.has_environment("USER"):     # Works for macOS and Linux
		username = OS.get_environment("USER")
	else:
		username = "Unknown Player"
		
	return username


func _on_lobby_created(_lobby: String):
	player_data.lobby = _lobby
