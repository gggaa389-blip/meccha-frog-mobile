extends Control

@onready var lobby_game: PackedScene = preload("res://assets/scenes/lobby.tscn")

var lobby_type: Enums.server_type = Enums.server_type.enet #TODO: change to steam


func _on_settings_pressed() -> void :
	%SettingsMenu.show()

func _on_lobby_pressed() -> void :
	hide()
	%Lobby.show()


func _on_customize_pressed() -> void :
	hide()
	%Customize.show()
