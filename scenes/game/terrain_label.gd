extends Label

@onready var map_node : Node2D = $"../../.."
@onready var terrain_panel : Panel = $"../"
@onready var vbox = $"../VBoxContainer"

var last_displayed_country = ""

func _process(_delta):
	for country in Data.country_list.values():
		if country.name == map_node.last_country_clicked:
			if country.name == Data.player_country.name:
				if country.name != last_displayed_country:
					last_displayed_country = country.name
					display_terrain_stats(country)
					display_terrain_button(country)

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


func display_terrain_stats(country):
	var ter = country.terrain
	var stats_text = "Terrain:\n"
	stats_text += "  Oil Available: {oil_ava}\n"
	stats_text += "  Metal Available: {metal_ava}\n"
	stats_text += "  Coal Available: {coal_ava}\n"
	stats_text += "  Gas Available: {gas_ava}\n"
	stats_text += "  Uranium Available: {uranium_ava}\n"
	stats_text += "  Food Available: {food_ava}\n"
	stats_text += "  Energy Available: {energy_ava}\n"
	stats_text += "  Wood Available: {wood_ava}\n"
	stats_text += "  Gold Available: {gold_ava}\n"
	stats_text += "  Rare Earth Available: {rare_earth_ava}\n"

	text = stats_text.format({
		"oil_ava": ter.view_oil,
		"metal_ava": ter.view_metal,
		"coal_ava": ter.view_coal,
		"gas_ava": ter.view_gas,
		"uranium_ava": ter.view_uranium,
		"food_ava": ter.view_food,
		"energy_ava": ter.view_energy,
		"wood_ava": ter.view_wood,
		"gold_ava": ter.view_gold,
		"rare_earth_ava": ter.view_rare_earth,
	})


func display_terrain_button(country):
	var ter = country.terrain

	for child in vbox.get_children():
		child.queue_free()
	
	var resources = {
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
	
	for resource_name in resources:
		var btn = Button.new()
		btn.text = "+"
		btn.custom_minimum_size = Vector2(15, 15)
		btn.add_theme_font_size_override("font_size", 10)
		btn.pressed.connect(_on_resource_pressed.bind(resource_name))
		vbox.add_child(btn)

var searching = {}

func _on_resource_pressed(resource_name: String):
	if searching.get(resource_name, false):
		return
	searching[resource_name] = true
	search_resource(resource_name)

func search_resource(resource_name: String):
	var ter = Data.player_country.terrain
	var resource_key = resource_name.to_lower().replace(" ", "_")
	var view_key = "view_" + resource_key

	var current_view = ter.get(view_key)
	var max_val = ter.get(resource_key)

	var remaining = max_val - current_view
	if remaining <= 0:
		print(resource_name + ": fully explored!")
		searching[resource_name] = false
		return

	var ratio = 1.0 - (current_view / float(max_val))
	var discovery = int(remaining * ratio * randf_range(0.05, 0.15))
	discovery = max(1, discovery)

	var new_value = current_view + discovery

	if multiplayer.is_server():
		Data.apply_terrain_field.rpc(Data.player_country.name, view_key, new_value)
	else:
		Data.request_set_terrain_field.rpc_id(1, Data.player_country.name, view_key, new_value)

	last_displayed_country = ""
	searching[resource_name] = false








func _on_country_close_button_down() -> void:
	terrain_panel.global_position = Vector2(0, 0)
	terrain_panel.hide()
	pass
