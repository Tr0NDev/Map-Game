extends Label

@onready var map_node : Node2D = $"../../.."
@onready var economy_panel : Panel = $"../"

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
	
	var money = float(eco.money if eco.money != null else 0)
	var mil = float(eco.military_budget if eco.military_budget != null else 0)
	var infra = float(eco.infrastructure_budget if eco.infrastructure_budget != null else 0)
	var soc = float(eco.social_bugdet if eco.social_bugdet != null else 0)
	
	var stats_text = "Economy:\n"
	stats_text += "  Type: {type}\n"
	stats_text += "  Money: {money}$\n"
	stats_text += "  Average Salary: {salary}$\n"
	stats_text += "  Tax: {tax}%\n"
	stats_text += "  Military Budget: {mil}% ({milcalc}$)\n"
	stats_text += "  Infra. Budget: {infra}% ({infracalc}$)\n"
	stats_text += "  Social Budget: {soc}% ({soccalc}$)"
	
	text = stats_text.format({
		"type": eco.type if eco.type != null else "unknown",
		"money": format_number(money),
		"salary": format_number(float(eco.avg_salary if eco.avg_salary != null else 0)),
		"tax": eco.tax_rate if eco.tax_rate != null else 0,
		"mil": mil,
		"milcalc": format_number((mil * money) / 100),
		"infra": infra,
		"infracalc": format_number((infra * money) / 100),
		"soc": soc,
		"soccalc": format_number((soc * money) / 100)
	})


func _on_economy_close_button_down() -> void:
	economy_panel.global_position = Vector2(0, 0)
	economy_panel.hide()
	pass
