extends Label

@onready var map_node : Node2D = $"../../.."
@onready var country_panel : Panel = $"../"
@onready var info_country_panel : Panel = $"../Other_Country_Info"

var last_country = ""


func _process(_delta):
	if Data.player_country == null:
		return
	if map_node.last_country_clicked != last_country:
		for country in Data.country_list.values():
			if country.name == map_node.last_country_clicked:
				if country.name != Data.player_country.name:
					display_population_stats(country)
	last_country = map_node.last_country_clicked

func format_number(n: float) -> String:
	if n >= 1000000:
		var val = n / 1000000.0
		return str(snapped(val, 0.1)).replace(".0", "") + "M"
	elif n >= 1000:
		var val = n / 1000.0
		return str(snapped(val, 0.1)).replace(".0", "") + "k"
	return str(int(n))
	
func display_population_stats(country):
	var pop = country.population
	
	var stats_text = "{name}:\n"
	stats_text += "  Population: {total}\n"
	stats_text += "  Approval: {approval}%\n"
	stats_text += "  Money: {money}"

	text = stats_text.format({
		"name": country.name,
		"total": format_number(pop.pop_number),
		"approval": format_number(pop.approval),
		"money": format_number(country.economy.money),
	})


func _on_other_country_close_button_down() -> void:
	country_panel.global_position = Vector2(0, 0)
	country_panel.hide()
	map_node.last_country_clicked = ""
	pass


func _on_button_button_down() -> void:
	info_country_panel.show()
	pass
