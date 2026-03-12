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
	
func get_consumption(country, resource: String) -> float:
	var pop = country.population.pop_number
	var army = country.army
	var consumption_rates_map = {
		"food": 1.0 / 7000.0,
		"energy": 1.0 / 100000.0,
		"gas": 1.0 / 100000.0,
		"oil": 1.0 / 10000000.0,
	}
	var military_consumption = {
		"soldier": {"oil": 0.001},
		"tank": {"oil": 0.1, "metal": 2},
		"armored_vehicle": {"oil": 0.01, "metal": 1},
		"aircraft": {"oil": 1, "metal": 3},
		"destroyer": {"oil": 1, "metal": 5},
		"submarine": {"oil": 1, "metal": 4, "uranium": 1},
		"aircraft_carrier": {"oil": 1, "metal": 2, "uranium": 2},
		"cyber_power": {"digital": 1, "gold": 1},
	}
	var total = 0.0
	if consumption_rates_map.has(resource):
		total += int(pop * consumption_rates_map[resource])
	for unit in military_consumption:
		var count = army.get(unit)
		if count == null or count == 0: continue
		if military_consumption[unit].has(resource):
			total += int(count * military_consumption[unit][resource])
	return total

func display_resource_stats(country):
	var res = country.resources
	var infra = country.infrastructure

	var stats_text = "Resources (+Prod / -Cons):\n"
	stats_text += "  Oil: {oil}   (+{oil_prod} / -{oil_cons})\n"
	stats_text += "  Metal: {metal}   (+{metal_prod} / -{metal_cons})\n"
	stats_text += "  Coal: {coal}   (+{coal_prod})\n"
	stats_text += "  Gas: {gas}   (+{gas_prod} / -{gas_cons})\n"
	stats_text += "  Uranium: {uranium}   (+{uranium_prod} / -{uranium_cons})\n"
	stats_text += "  Food: {food}   (+{food_prod} / -{food_cons})\n"
	stats_text += "  Energy: {energy}   (+{energy_prod} / -{energy_cons})\n"
	stats_text += "  Wood: {wood}   (+{wood_prod})\n"
	stats_text += "  Gold: {gold}   (+{gold_prod} / -{gold_cons})\n"
	stats_text += "  Rare Earth: {rare_earth}   (+{rare_earth_prod})\n"
	stats_text += "  Digital: {digital}   (+{digital_prod} / -{digital_cons})"

	text = stats_text.format({
		"oil": format_number(res.oil),
		"oil_prod": format_number(get_production(infra, "oil_refinery")),
		"oil_cons": format_number(get_consumption(country, "oil")),
		"metal": format_number(res.metal),
		"metal_prod": format_number(get_production(infra, "metal_foundry")),
		"metal_cons": format_number(get_consumption(country, "metal")),
		"coal": format_number(res.coal),
		"coal_prod": format_number(get_production(infra, "coal_mine")),
		"gas": format_number(res.gas),
		"gas_prod": format_number(get_production(infra, "gas_pipeline")),
		"gas_cons": format_number(get_consumption(country, "gas")),
		"uranium": format_number(res.uranium),
		"uranium_prod": format_number(get_production(infra, "nuclear_plant")),
		"uranium_cons": format_number(get_consumption(country, "uranium")),
		"food": format_number(res.food),
		"food_prod": format_number(get_production(infra, "farm")),
		"food_cons": format_number(get_consumption(country, "food")),
		"energy": format_number(res.energy),
		"energy_prod": format_number(get_production(infra, "power_plant")),
		"energy_cons": format_number(get_consumption(country, "energy")),
		"wood": format_number(res.wood),
		"wood_prod": format_number(get_production(infra, "sawmill")),
		"gold": format_number(res.gold),
		"gold_prod": format_number(get_production(infra, "gold_mine")),
		"gold_cons": format_number(get_consumption(country, "gold")),
		"rare_earth": format_number(res.rare_earth),
		"rare_earth_prod": format_number(get_production(infra, "rare_earth_mine")),
		"digital": format_number(res.digital),
		"digital_prod": format_number(get_production(infra, "data_center")),
		"digital_cons": format_number(get_consumption(country, "digital")),
	})

func get_production(infra, infra_name: String) -> float:
	var production_map = {
		"oil_refinery": 50,
		"metal_foundry": 120,
		"coal_mine": 80,
		"gas_pipeline": 40,
		"nuclear_plant": 10,
		"farm": 500,
		"power_plant": 300,
		"sawmill": 150,
		"gold_mine": 5,
		"rare_earth_mine": 8,
		"data_center": 200,
	}
	var count = infra.get(infra_name)
	if count == null:
		return 0.0
	return count * production_map.get(infra_name, 0)
	
	
	

func _on_resources_close_button_down() -> void:
	resources_panel.global_position = Vector2(0, 0)
	resources_panel.hide()
	pass
