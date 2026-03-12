extends Label

@onready var turn : Node = $"../Turn"

func _process(_delta):
	text = "Turn: " + str(Data.tour) + "\n" +str(len(Data.ready_turn)) + "/" + str(len(Data.player_countries))
	if len(Data.ready_turn) == len(Data.player_countries) and len(Data.player_countries) > 0:
		next_turn()

func next_turn():
	if multiplayer.is_server():
		Data.clear_ready_turn()
		turn.next_turn()
		for country_name in Data.player_countries.values():
			var pid = turn.get_player_id(country_name)
			var production = turn.get_production_recap(country_name)
			var consumption = turn.get_consumption_recap(country_name)
			if pid == 1:
				Data.show_recap(production, consumption)
			else:
				Data.show_recap.rpc_id(pid, production, consumption)

func _on_next_turn_button_button_down() -> void:
	if multiplayer.is_server():
		Data.toggle_ready(Data.player_country.name)
	else:
		Data.toggle_ready.rpc_id(1, Data.player_country.name)
