extends Label

@onready var map_node : Node2D = $"../../.."
@onready var resources_panel : Panel = $"../"
@onready var vbox = $"../VBoxContainer"

var last_displayed_country = ""

var resource_data = [
	{"key": "oil",        "icon": "🛢",  "label": "Oil",        "infra": "oil_refinery"},
	{"key": "metal",      "icon": "⚙",   "label": "Metal",      "infra": "metal_foundry"},
	{"key": "coal",       "icon": "🪨",  "label": "Coal",       "infra": "coal_mine"},
	{"key": "gas",        "icon": "💨",  "label": "Gas",        "infra": "gas_pipeline"},
	{"key": "uranium",    "icon": "☢",   "label": "Uranium",    "infra": "nuclear_plant"},
	{"key": "food",       "icon": "🌾",  "label": "Food",       "infra": "farm"},
	{"key": "energy",     "icon": "⚡",  "label": "Energy",     "infra": "power_plant"},
	{"key": "wood",       "icon": "🪵",  "label": "Wood",       "infra": "sawmill"},
	{"key": "gold",       "icon": "🪙",  "label": "Gold",       "infra": "gold_mine"},
	{"key": "rare_earth", "icon": "💎",  "label": "Rare Earth", "infra": "rare_earth_mine"},
	{"key": "digital",    "icon": "💻",  "label": "Digital",    "infra": "data_center"},
]

var production_map = {
	"oil_refinery": 50, "metal_foundry": 120, "coal_mine": 80,
	"gas_pipeline": 40, "nuclear_plant": 10, "farm": 500,
	"power_plant": 300, "sawmill": 150, "gold_mine": 5,
	"rare_earth_mine": 8, "data_center": 200,
}

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

func _process(_delta):
	if Data.player_country == null: return
	if vbox == null: return
	for country in Data.country_list.values():
		if country.name == map_node.last_country_clicked:
			if country.name == Data.player_country.name:
				if country.name != last_displayed_country:
					last_displayed_country = country.name
					display(country)

func format_number(n) -> String:
	if n == null: return "0"
	n = float(n)
	if n >= 1000000:
		return str(snapped(n / 1000000.0, 0.1)).replace(".0", "") + "M"
	elif n >= 1000:
		return str(snapped(n / 1000.0, 0.1)).replace(".0", "") + "k"
	return str(int(n))

func get_production(infra, infra_name: String) -> float:
	var count = infra.get(infra_name)
	if count == null: return 0.0
	return count * production_map.get(infra_name, 0)

func get_consumption(country, resource: String) -> float:
	var pop = country.population.pop_number
	var army = country.army
	var total = 0.0
	if consumption_rates_map.has(resource):
		total += int(pop * consumption_rates_map[resource])
	for unit in military_consumption:
		var count = army.get(unit)
		if count == null or count == 0: continue
		if military_consumption[unit].has(resource):
			total += int(count * military_consumption[unit][resource])
	return total

func display(country):
	if vbox == null: return
	text = ""
	for child in vbox.get_children():
		child.queue_free()

	var title = Label.new()
	title.text = "📦 Resources"
	title.add_theme_font_size_override("font_size", 16)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(title)
	vbox.add_child(HSeparator.new())

	var hbox = HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(hbox)

	var col_left = VBoxContainer.new()
	col_left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var col_right = VBoxContainer.new()
	col_right.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	hbox.add_child(col_left)
	hbox.add_child(VSeparator.new())
	hbox.add_child(col_right)

	for i in range(resource_data.size()):
		var rd = resource_data[i]
		var col = col_left if i < ceil(resource_data.size() / 2.0) else col_right

		var key = rd["key"]
		var stock = country.resources.get(key)
		if stock == null: stock = 0
		var prod = get_production(country.infrastructure, rd["infra"])
		var cons = get_consumption(country, key)
		var net = prod - cons

		var entry = VBoxContainer.new()
		entry.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var row = HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var name_lbl = Label.new()
		name_lbl.text = rd["icon"] + " " + rd["label"]
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_lbl.add_theme_font_size_override("font_size", 12)
		row.add_child(name_lbl)

		var stock_lbl = Label.new()
		stock_lbl.text = format_number(stock)
		stock_lbl.add_theme_font_size_override("font_size", 12)
		stock_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		if stock <= 0:
			stock_lbl.modulate = Color.RED
		elif cons > 0 and stock < cons * 3:
			stock_lbl.modulate = Color.YELLOW
		else:
			stock_lbl.modulate = Color.WHITE
		row.add_child(stock_lbl)
		entry.add_child(row)

		if prod > 0 or cons > 0:
			var detail_lbl = Label.new()
			var detail = ""
			if prod > 0: detail += "+" + format_number(prod) + " "
			if cons > 0: detail += "-" + format_number(cons) + " "
			if net >= 0:
				detail += "(▲+" + format_number(net) + ")"
				detail_lbl.modulate = Color.GREEN
			else:
				detail += "(▼" + format_number(net) + ")"
				detail_lbl.modulate = Color.ORANGE_RED
			detail_lbl.text = detail
			detail_lbl.add_theme_font_size_override("font_size", 10)
			entry.add_child(detail_lbl)

		col.add_child(entry)
		col.add_child(HSeparator.new())

func _on_resources_close_button_down() -> void:
	resources_panel.global_position = Vector2(0, 0)
	resources_panel.hide()
