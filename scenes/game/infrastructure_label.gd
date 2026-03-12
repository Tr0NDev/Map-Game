extends Label
@onready var map_node : Node2D = $"../../.."
@onready var infra_panel : Panel = $"../"
@onready var vbox = $"../VBoxContainer"

var last_displayed_country = ""

var infra_to_terrain = {
	"oil_refinery": "view_oil",
	"metal_foundry": "view_metal",
	"coal_mine": "view_coal",
	"gas_pipeline": "view_gas",
	"nuclear_plant": "view_uranium",
	"farm": "view_food",
	"power_plant": "view_energy",
	"sawmill": "view_wood",
	"gold_mine": "view_gold",
	"rare_earth_mine": "view_rare_earth",
}

#ajuster pour meilleur equilibrage :) :) :) 
var infra_prices = {
	"farm": 10000000,
	"sawmill": 25000000,
	"coal_mine": 40000000,
	"power_plant": 60000000,
	"metal_foundry": 80000000,
	"gas_pipeline": 120000000,
	"oil_refinery": 200000000,
	"data_center": 300000000,
	"gold_mine": 400000000,
	"rare_earth_mine": 600000000,
	"nuclear_plant": 1000000000,
}

func _process(_delta):
	for country in Data.country_list.values():
		if country.name == map_node.last_country_clicked:
			if country.name == Data.player_country.name:
				display_stats(country)
				if country.name != last_displayed_country:
					last_displayed_country = country.name
					display_infra_buttons(country)

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

func display_stats(country):
	var infra = country.infrastructure
	var ter = country.terrain
	
	var stats_text = "Infrastructure (max):               Create()\n"
	stats_text += "  Oil Refineries: {oil_refinery} ({oil_max})\n"
	stats_text += "  Metal Foundries: {metal_foundry} ({metal_max})\n"
	stats_text += "  Coal Mines: {coal_mine} ({coal_max})\n"
	stats_text += "  Gas Pipelines: {gas_pipeline} ({gas_max})\n"
	stats_text += "  Nuclear Plants: {nuclear_plant} ({uranium_max})\n"
	stats_text += "  Farms: {farm} ({food_max})\n"
	stats_text += "  Power Plants: {power_plant} ({energy_max})\n"
	stats_text += "  Sawmills: {sawmill} ({wood_max})\n"
	stats_text += "  Gold Mines: {gold_mine} ({gold_max})\n"
	stats_text += "  Rare Earth Mines: {rare_earth_mine} ({rare_earth_max})\n"
	stats_text += "  Data Centers: {data_center} ({digital_max})"
	text = stats_text.format({
		"oil_refinery": format_number(infra.oil_refinery),
		"oil_max": format_number(ter.view_oil / 100.0),
		"metal_foundry": format_number(infra.metal_foundry),
		"metal_max": format_number(ter.view_metal / 100.0),
		"coal_mine": format_number(infra.coal_mine),
		"coal_max": format_number(ter.view_coal / 100.0),
		"gas_pipeline": format_number(infra.gas_pipeline),
		"gas_max": format_number(ter.view_gas / 100.0),
		"nuclear_plant": format_number(infra.nuclear_plant),
		"uranium_max": format_number(ter.view_uranium / 100.0),
		"farm": format_number(infra.farm),
		"food_max": format_number(ter.view_food / 100.0),
		"power_plant": format_number(infra.power_plant),
		"energy_max": format_number(ter.view_energy / 100.0),
		"sawmill": format_number(infra.sawmill),
		"wood_max": format_number(ter.view_wood / 100.0),
		"gold_mine": format_number(infra.gold_mine),
		"gold_max": format_number(ter.view_gold / 100.0),
		"rare_earth_mine": format_number(infra.rare_earth_mine),
		"rare_earth_max": format_number(ter.view_rare_earth / 100.0),
		"data_center": format_number(infra.data_center),
		"digital_max": format_number(0),
	})

func display_infra_buttons(country):
	for child in vbox.get_children():
		child.queue_free()

	for infra_name in infra_to_terrain:
		var btn = Button.new()
		var price = infra_prices.get(infra_name, 0)
		btn.text = format_number(price) + "$"
		btn.custom_minimum_size = Vector2(15, 15)
		btn.add_theme_font_size_override("font_size", 10)
		btn.pressed.connect(_on_infra_pressed.bind(infra_name))
		vbox.add_child(btn)

func _on_infra_pressed(infra_name: String):
	var country = Data.player_country
	var infra = country.infrastructure
	var terrain_key = infra_to_terrain[infra_name]
	var view_val = country.terrain.get(terrain_key)
	var max_infra = int(view_val / 100.0)
	var current = infra.get(infra_name)
	if current == null:
		current = 0

	if current >= max_infra:
		Data.show_popup("Max reached for " + infra_name + "\n(" + str(current) + "/" + str(max_infra) + ")")
		return

	var price = infra_prices.get(infra_name, 0)
	var money = float(country.economy.money)
	if money < price:
		Data.show_popup("Not enough money!\nNeed " + format_number(price) + "$\nYou have " + format_number(money) + "$")
		return

	var new_value = current + 1
	var new_money = money - price

	if multiplayer.is_server():
		Data.apply_infra_field.rpc(country.name, infra_name, new_value)
		Data.apply_economy_field.rpc(country.name, "money", new_money)
	else:
		Data.request_set_infra_field.rpc_id(1, country.name, infra_name, new_value)
		Data.request_set_economy_field.rpc_id(1, country.name, "money", new_money)

	last_displayed_country = ""
	Data.show_popup("New " + infra_name + " built!\n-" + format_number(price) + "$\nNow " + str(new_value) + "/" + str(max_infra))

func _on_infrastructure_close_button_down() -> void:
	infra_panel.global_position = Vector2(0, 0)
	infra_panel.hide()
