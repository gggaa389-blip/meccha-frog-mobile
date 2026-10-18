extends Node

var is_monster: bool = false

func _ready() -> void :
	GameHandler.world = self
	await %PlayerList.player_added
