extends Label

@onready var map_node : Node2D = $"../../.."
@onready var resources_panel : Panel = $"../"

func _process(_delta):
	for country in Data.country_list.values():
		if country.name == map_node.last_country_clicked:
			if country.name == Data.player_country.name:
				display_resource_stats(country)

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

func display_resource_stats(country):
	var res = country.resources
	
	var stats_text = "Resources:\n"
	stats_text += "  Oil: {oil}\n"
	stats_text += "  Metal: {metal}\n"
	stats_text += "  Coal: {coal}\n"
	stats_text += "  Gas: {gas}\n"
	stats_text += "  Uranium: {uranium}\n"
	stats_text += "  Food: {food}\n"
	stats_text += "  Energy: {energy}\n"
	stats_text += "  Wood: {wood}\n"
	stats_text += "  Gold: {gold}\n"
	stats_text += "  Rare Earth: {rare_earth}\n"
	stats_text += "  Digital: {digital}"

	text = stats_text.format({
		"oil": format_number(res.oil),
		"metal": format_number(res.metal),
		"coal": format_number(res.coal),
		"gas": format_number(res.gas),
		"uranium": format_number(res.uranium),
		"food": format_number(res.food),
		"energy": format_number(res.energy),
		"wood": format_number(res.wood),
		"gold": format_number(res.gold),
		"rare_earth": format_number(res.rare_earth),
		"digital": format_number(res.digital)
	})


func _on_resources_close_button_down() -> void:
	resources_panel.global_position = Vector2(0, 0)
	resources_panel.hide()
	pass
