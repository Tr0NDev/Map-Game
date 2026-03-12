extends Label
@onready var map_node : Node2D = $"../../../.."
@onready var country_panel : Panel = $"../"
@onready var left_label : Label = $"../Left_Label"
@onready var right_label : Label = $"../Right_Label"
@onready var relation_button : Button = $"../Relation_Button"

var last_country = ""
var current_country = null
var revealed = {}
var revealed_military = {}
var relations = {}

func _ready():
	load_relations()

func load_relations():
	var file = FileAccess.open("res://countrydata/relations.json", FileAccess.READ)
	if file == null:
		return
	var json_text = file.get_as_text()
	file.close()
	var data = JSON.parse_string(json_text)
	if typeof(data) == TYPE_DICTIONARY:
		relations = data["relations"]

func _process(_delta):
	if map_node.last_country_clicked != last_country:
		for country in Data.country_list.values():
			if country.name == map_node.last_country_clicked:
				if country.name != Data.player_country.name:
					current_country = country
					revealed = {}
					revealed_military = {}
					_reveal_all(country)
					display_terrain_stats(country)
					for c in relation_button.pressed.get_connections():
						relation_button.pressed.disconnect(c["callable"])
					relation_button.pressed.connect(func(): _on_view_relations(country.name))
					last_country = map_node.last_country_clicked

func _get_fuzz_factor(country) -> float:
	var my_cyber = float(Data.player_country.army.cyber_power)
	var their_cyber = float(country.army.cyber_power)
	var diff = their_cyber - my_cyber
	if diff <= 0:
		return 0.0
	return clamp(diff * 0.5, 0.0, 5.0)

func _fuzz(real_val, fuzz_factor: float):
	if real_val == null:
		real_val = 0
	if fuzz_factor <= 0.0:
		return real_val
	var fuzz = float(real_val) * fuzz_factor
	return max(0, int(float(real_val) + randf_range(-fuzz, fuzz)))

func _fuzz_relation(real_val: int, fuzz_factor: float) -> int:
	if fuzz_factor <= 0.0:
		return real_val
	var fuzz = 100.0 * fuzz_factor * 0.05
	var fuzzed = real_val + randf_range(-fuzz, fuzz)
	return clamp(int(fuzzed), 0, 100)

func _reveal_all(country):
	var fuzz = _get_fuzz_factor(country)
	var terrain_resources = ["Oil", "Metal", "Coal", "Gas", "Uranium", "Food", "Energy", "Wood", "Gold", "Rare Earth"]
	for resource_name in terrain_resources:
		var key = "view_" + resource_name.to_lower().replace(" ", "_")
		var real_val = country.terrain.get(key)
		revealed[resource_name] = _fuzz(real_val, fuzz)
	var military_fields = ["soldier", "tank", "armored_vehicle", "aircraft", "destroyer", "submarine", "aircraft_carrier", "cyber_power", "missile"]
	for unit in military_fields:
		var real_val = country.army.get(unit)
		revealed_military[unit] = _fuzz(real_val, fuzz)

func format_number(n: float) -> String:
	if n >= 1000000:
		var val = n / 1000000.0
		return str(snapped(val, 0.1)).replace(".0", "") + "M"
	elif n >= 1000:
		var val = n / 1000.0
		return str(snapped(val, 0.1)).replace(".0", "") + "k"
	return str(int(n))

func display_terrain_stats(country):
	text = country.name

	var left_text = "Terrain:\n"
	var terrain_keys = ["Oil", "Metal", "Coal", "Gas", "Uranium", "Food", "Energy", "Wood", "Gold", "Rare Earth"]
	for resource_name in terrain_keys:
		var val = revealed.get(resource_name, 0)
		left_text += "  {name}: {val}\n".format({"name": resource_name, "val": format_number(float(val))})
	left_label.text = left_text

	var right_text = "Military:\n"
	var military_labels = {
		"soldier": "Soldiers",
		"tank": "Tanks",
		"armored_vehicle": "Armored Veh.",
		"aircraft": "Aircraft",
		"destroyer": "Destroyers",
		"submarine": "Submarines",
		"aircraft_carrier": "Carriers",
		"cyber_power": "Cyber Power",
		"missile": "Missile",
	}
	for unit in military_labels:
		var val = revealed_military.get(unit, 0)
		right_text += "  {name}: {val}\n".format({"name": military_labels[unit], "val": format_number(float(val))})
	right_label.text = right_text

func _on_view_relations(country_name: String):
	if not relations.has(country_name):
		Data.show_popup("No relation data for " + country_name)
		return

	var fuzz = _get_fuzz_factor(current_country)
	var canvas = CanvasLayer.new()
	get_tree().root.add_child(canvas)
	var panel = Panel.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color("#230107d9")
	panel.add_theme_stylebox_override("panel", style)
	panel.custom_minimum_size = Vector2(400, 350)
	canvas.add_child(panel)
	var main_vbox = VBoxContainer.new()
	main_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 15)
	panel.add_child(main_vbox)
	var title = Label.new()
	title.text = "Relations of " + country_name
	title.add_theme_font_size_override("font_size", 22)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(title)
	main_vbox.add_child(HSeparator.new())
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(0, 200)
	main_vbox.add_child(scroll)
	var content_vbox = VBoxContainer.new()
	content_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(content_vbox)
	var country_relations = relations[country_name]
	for other in country_relations:
		var real_val = country_relations[other]
		var display_val = _fuzz_relation(real_val, fuzz)
		var row = HBoxContainer.new()
		var name_lbl = Label.new()
		name_lbl.text = other
		name_lbl.custom_minimum_size = Vector2(150, 0)
		row.add_child(name_lbl)
		var val_lbl = Label.new()
		val_lbl.text = str(display_val) + "/100"
		val_lbl.modulate = _get_relation_color(display_val)
		row.add_child(val_lbl)
		content_vbox.add_child(row)
	var ok_btn = Button.new()
	ok_btn.text = "OK"
	ok_btn.custom_minimum_size = Vector2(100, 40)
	main_vbox.add_child(ok_btn)
	await get_tree().process_frame
	var screen_size = get_viewport().get_visible_rect().size
	panel.position = Vector2((screen_size.x - panel.size.x) / 2, (screen_size.y - panel.size.y) / 2)
	ok_btn.pressed.connect(func(): canvas.call_deferred("queue_free"))

func _get_relation_color(val: int) -> Color:
	if val >= 80:
		return Color.GREEN
	elif val >= 60:
		return Color.YELLOW
	elif val >= 40:
		return Color.ORANGE
	else:
		return Color.RED

func _on_other_country_info_close_button_down() -> void:
	country_panel.global_position = Vector2(0, 0)
	country_panel.hide()
	map_node.last_country_clicked = ""
