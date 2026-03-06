extends Label

@onready var map_node : Node2D = $"../../.."
@onready var infra_panel : Panel = $"../"

func _process(_delta):
	for country in Data.country_list.values():
		if country.name == map_node.last_country_clicked:
			if country.name == Data.player_country.name:
				display_stats(country)

func format_number(n: float) -> String:
	if n >= 1000000:
		var val = n / 1000000.0
		return str(snapped(val, 0.1)).replace(".0", "") + "M"
	elif n >= 1000:
		var val = n / 1000.0
		return str(snapped(val, 0.1)).replace(".0", "") + "k"
	return str(n)

func display_stats(country):
	var eco = country.economy
	var infra = country.infrastructure

	var stats_text = "Infrastructure:\n"
	stats_text += "  Factories: {factory}\n"
	stats_text += "  Railways: {railways}\n"
	stats_text += "  Ports: {ports}\n"
	stats_text += "  Airports: {airports}"

	text = stats_text.format({
		"factory": format_number(infra.factory),
		"railways": format_number(infra.railways),
		"ports": format_number(infra.ports),
		"airports": format_number(infra.airports)
	})


func _on_infrastructure_close_button_down() -> void:
	infra_panel.global_position = Vector2(0, 0)
	infra_panel.hide()
	pass
