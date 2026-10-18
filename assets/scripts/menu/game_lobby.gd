extends Control



func _on_start_pressed() -> void :
	GameHandler.start_game.rpc()

func _on_exit_pressed() -> void :
	MultiplayerHandler.client_disconnect()


func _on_back_pressed() -> void:
	$"../GAMEOVER".hide()
	%UI.show()
	MultiplayerHandler.client_disconnect()
	GameHandler.reset_players()

func gameover(winner: int) -> void:
	if winner == 1:
		$"../GAMEOVER/Label".self_modulate = Color.RED
		$"../GAMEOVER/Label".text = "ميستر زرافة هو الفائز!"
	else:
		$"../GAMEOVER/Label".self_modulate = Color.GREEN
		$"../GAMEOVER/Label".text = "فريق الأكلات السريعة فازوا!"
	$"../GAMEOVER".show()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
