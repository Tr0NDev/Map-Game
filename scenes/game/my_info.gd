extends Label

@onready var map_node : Node2D = $"../.."

func _process(_delta):
	if Data.player_country == null:
		return
	var money = Data.player_country.economy.money
	text = Data.player_country.name + "\n" + str(int(money)) + "$"

func format_number(n) -> String:
	if n == null:
		return "0"
	n = float(n)
	if n >= 1000000:
		var val = n / 1000000.0
		return str(snapped(val, 0.1)).replace(".0", "") + "M"
	elif n >= 1000:
		var val = n / 1000.0
		return str(snapped(val, 0.1)).replace(".0", "") + "k"
	return str(int(n))
