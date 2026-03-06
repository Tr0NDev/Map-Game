extends Control

@onready var host : Button = $"Host_Button"
@onready var ip_input : LineEdit = $"LineEdit"

func _on_host_button_button_down() -> void:
	Network.host_game()
	get_tree().change_scene_to_file("res://scenes/game/game.tscn")

func _on_join_button_button_down() -> void:
	Network.join_game(ip_input.text)
	await Network.player_connected
	get_tree().change_scene_to_file("res://scenes/game/game.tscn")
