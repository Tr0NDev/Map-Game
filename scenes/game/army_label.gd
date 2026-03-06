extends Label

@onready var map_node : Node2D = $"../../.."
@onready var army_panel : Panel = $"../"

func _process(_delta):
	for country in Data.country_list.values():
		if country.name == map_node.last_country_clicked:
			if country.name == Data.player_country.name:
				display_army_stats(country)

func format_number(n: float) -> String:
	if n >= 1000000:
		var val = n / 1000000.0
		return str(snapped(val, 0.1)).replace(".0", "") + "M"
	elif n >= 1000:
		var val = n / 1000.0
		return str(snapped(val, 0.1)).replace(".0", "") + "k"
	return str(int(n))

func display_army_stats(country):
	var army = country.army 
	
	var stats_text = "Army :\n"
	stats_text += "  Soldier : {soldier}\n"
	stats_text += "  Tank : {tank}\n"
	stats_text += "  Arm.Vehicle : {av}\n"
	stats_text += "  Aircraft : {air}\n"
	stats_text += "  Destroyer : {dest}\n"
	stats_text += "  Submarine : {sub}\n"
	stats_text += "  Air.Carrier : {carrier}\n"
	stats_text += "  Cyber Power : {cyber}/100"
	
	text = stats_text.format({
		"soldier": format_number(army.soldier),
		"tank": format_number(army.tank),
		"av": format_number(army.armored_vehicle),
		"air": format_number(army.aircraft),
		"dest": format_number(army.destroyer),
		"sub": format_number(army.submarine),
		"carrier": format_number(army.aircraft_carrier),
		"cyber": army.cyber_power
	})


func _on_army_close_button_down() -> void:
	army_panel.global_position = Vector2(0, 0)
	army_panel.hide()
	pass
