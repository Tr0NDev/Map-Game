extends Node

func _on_button_button_down() -> void:
	var country_name = Data.player_country.name
	var current_money = Data.player_country.economy.money
	Data.set_economy_field.rpc(country_name, "money", 0)
	print("0 pour " + country_name)
