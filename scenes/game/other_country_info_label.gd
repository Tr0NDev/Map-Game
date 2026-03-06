extends Label
@onready var map_node : Node2D = $"../../../.."
@onready var country_panel : Panel = $"../"
@onready var vbox = $"../Other_Country_Vbox"
var last_country = ""
var current_country = null
var revealed = {}

func _process(_delta):
	if map_node.last_country_clicked != last_country:
		for country in Data.country_list.values():
			if country.name == map_node.last_country_clicked:
				if country.name != Data.player_country.name:
					current_country = country
					revealed = {}
					display_terrain_stats(country)
					display_country_terrain_button(country)
					last_country = map_node.last_country_clicked

func format_number(n: float) -> String:
	if n >= 1000000:
		var val = n / 1000000.0
		return str(snapped(val, 0.1)).replace(".0", "") + "M"
	elif n >= 1000:
		var val = n / 1000.0
		return str(snapped(val, 0.1)).replace(".0", "") + "k"
	return str(int(n))

func get_resource_value(ter, resource_name: String):
	var key = "view_" + resource_name.to_lower().replace(" ", "_")
	return ter.get(key)

func display_terrain_stats(country):
	var ter = country.terrain
	var stats_text = "Terrain:\n"
	var resource_keys = {
		"Oil": ter.view_oil,
		"Metal": ter.view_metal,
		"Coal": ter.view_coal,
		"Gas": ter.view_gas,
		"Uranium": ter.view_uranium,
		"Food": ter.view_food,
		"Energy": ter.view_energy,
		"Wood": ter.view_wood,
		"Gold": ter.view_gold,
		"Rare Earth": ter.view_rare_earth,
	}
	for resource_name in resource_keys:
		var val = resource_keys[resource_name]
		var display = "?" 
		if revealed.get(resource_name, false):
			display = format_number(val)
		stats_text += "  {name}: {val}\n".format({"name": resource_name, "val": display})
	text = stats_text

func display_country_terrain_button(country):
	var ter = country.terrain
	for child in vbox.get_children():
		child.queue_free()

	var resources = ["Oil", "Metal", "Coal", "Gas", "Uranium", "Food", "Energy", "Wood", "Gold", "Rare Earth"]

	for resource_name in resources:
		var btn = Button.new()
		btn.text = "✅"
		btn.custom_minimum_size = Vector2(15, 15)
		btn.add_theme_font_size_override("font_size", 10)
		btn.pressed.connect(_on_resource_pressed.bind(resource_name))
		vbox.add_child(btn)

func _on_resource_pressed(resource_name: String):
	var country_name = Data.player_country.name
	var current_money = Data.player_country.economy.money
	var new_money = current_money - 3000000

	if multiplayer.is_server():
		Data.apply_economy_field.rpc(country_name, "money", new_money)
	else:
		Data.request_set_economy_field.rpc_id(1, country_name, "money", new_money)

	revealed[resource_name] = true
	display_terrain_stats(current_country)

func _on_other_country_info_close_button_down() -> void:
	country_panel.global_position = Vector2(0, 0)
	country_panel.hide()
	map_node.last_country_clicked = ""
