extends Label
@onready var map_node : Node2D = $"../../.."
@onready var infra_panel : Panel = $"../"
@onready var vbox = $"../VBoxContainer"

var last_displayed_country = ""

var infra_data = {
	"farm":           {"terrain": "view_food",      "icon": "🌾", "label": "Farm",            "resource": "food",      "price": 10000000},
	"sawmill":        {"terrain": "view_wood",      "icon": "🪵", "label": "Sawmill",         "resource": "wood",      "price": 25000000},
	"coal_mine":      {"terrain": "view_coal",      "icon": "🪨", "label": "Coal Mine",       "resource": "coal",      "price": 40000000},
	"power_plant":    {"terrain": "view_energy",    "icon": "⚡", "label": "Power Plant",     "resource": "energy",    "price": 60000000},
	"metal_foundry":  {"terrain": "view_metal",     "icon": "⚙",  "label": "Metal Foundry",   "resource": "metal",     "price": 80000000},
	"gas_pipeline":   {"terrain": "view_gas",       "icon": "💨", "label": "Gas Pipeline",    "resource": "gas",       "price": 120000000},
	"oil_refinery":   {"terrain": "view_oil",       "icon": "🛢",  "label": "Oil Refinery",    "resource": "oil",       "price": 200000000},
	"data_center":    {"terrain": "",               "icon": "💻", "label": "Data Center",     "resource": "digital",   "price": 300000000},
	"gold_mine":      {"terrain": "view_gold",      "icon": "🪙", "label": "Gold Mine",       "resource": "gold",      "price": 400000000},
	"rare_earth_mine":{"terrain": "view_rare_earth","icon": "💎", "label": "Rare Earth Mine", "resource": "rare_earth","price": 600000000},
	"nuclear_plant":  {"terrain": "view_uranium",   "icon": "☢",  "label": "Nuclear Plant",   "resource": "uranium",   "price": 1000000000},
}

func _process(_delta):
	if Data.player_country == null: return
	for country in Data.country_list.values():
		if country.name == map_node.last_country_clicked:
			if country.name == Data.player_country.name:
				if country.name != last_displayed_country:
					last_displayed_country = country.name
					display(country)

func format_number(n) -> String:
	if n == null: return "0"
	n = float(n)
	if n >= 1000000000:
		return str(snapped(n / 1000000000.0, 0.1)).replace(".0", "") + "B"
	elif n >= 1000000:
		return str(snapped(n / 1000000.0, 0.1)).replace(".0", "") + "M"
	elif n >= 1000:
		return str(snapped(n / 1000.0, 0.1)).replace(".0", "") + "k"
	return str(int(n))

func display(country):
	text = ""
	for child in vbox.get_children():
		child.queue_free()

	var title = Label.new()
	title.text = "🏭 Infrastructure"
	title.add_theme_font_size_override("font_size", 16)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(title)
	vbox.add_child(HSeparator.new())

	var money = float(country.economy.money)
	var money_lbl = Label.new()
	money_lbl.text = "💰 " + format_number(money) + "$"
	money_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	money_lbl.modulate = Color.GREEN
	money_lbl.add_theme_font_size_override("font_size", 13)
	vbox.add_child(money_lbl)
	vbox.add_child(HSeparator.new())

	for infra_name in infra_data:
		var d = infra_data[infra_name]
		var infra = country.infrastructure
		var current = infra.get(infra_name)
		if current == null: current = 0

		var max_infra = 999
		if d["terrain"] != "":
			var view_val = country.terrain.get(d["terrain"])
			if view_val == null: view_val = 0
			max_infra = int(view_val / 100.0)

		var price = d["price"]
		var can_afford = money >= price
		var at_max = current >= max_infra

		var row = HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.custom_minimum_size = Vector2(0, 32)

		# icône + nom
		var name_lbl = Label.new()
		name_lbl.text = d["icon"] + " " + d["label"]
		name_lbl.custom_minimum_size = Vector2(140, 0)
		name_lbl.add_theme_font_size_override("font_size", 12)
		name_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		if at_max:
			name_lbl.modulate = Color(0.5, 0.5, 0.5)
		row.add_child(name_lbl)

		# compteur current/max
		var count_lbl = Label.new()
		if d["terrain"] == "":
			count_lbl.text = str(current)
		else:
			count_lbl.text = str(current) + "/" + str(max_infra)
		count_lbl.custom_minimum_size = Vector2(50, 0)
		count_lbl.add_theme_font_size_override("font_size", 12)
		count_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		count_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		if at_max:
			count_lbl.modulate = Color.GREEN
		elif current > 0:
			count_lbl.modulate = Color.YELLOW
		else:
			count_lbl.modulate = Color.GRAY
		row.add_child(count_lbl)

		# bouton build
		var btn = Button.new()
		if at_max:
			btn.text = "✓ MAX"
			btn.disabled = true
		elif not can_afford:
			btn.text = format_number(price) + "$"
			btn.disabled = true
			btn.modulate = Color(0.6, 0.4, 0.4)
		else:
			btn.text = "+" + format_number(price) + "$"
			btn.modulate = Color.YELLOW
		btn.custom_minimum_size = Vector2(90, 28)
		btn.add_theme_font_size_override("font_size", 11)
		btn.pressed.connect(_on_infra_pressed.bind(infra_name))
		row.add_child(btn)

		vbox.add_child(row)

func _on_infra_pressed(infra_name: String):
	var country = Data.player_country
	var d = infra_data[infra_name]
	var infra = country.infrastructure
	var current = infra.get(infra_name)
	if current == null: current = 0

	var max_infra = 999
	if d["terrain"] != "":
		var view_val = country.terrain.get(d["terrain"])
		if view_val == null: view_val = 0
		max_infra = int(view_val / 100.0)

	if current >= max_infra:
		Data.show_popup("Max reached!\n" + str(current) + "/" + str(max_infra))
		return

	var price = d["price"]
	var money = float(country.economy.money)
	if money < price:
		Data.show_popup("Not enough money!\nNeed " + format_number(price) + "$\nYou have " + format_number(money) + "$")
		return

	if multiplayer.is_server():
		Data.apply_infra_field.rpc(country.name, infra_name, current + 1)
		Data.apply_economy_field.rpc(country.name, "money", money - price)
	else:
		Data.request_set_infra_field.rpc_id(1, country.name, infra_name, current + 1)
		Data.request_set_economy_field.rpc_id(1, country.name, "money", money - price)

	last_displayed_country = ""
	Data.show_popup(d["icon"] + " " + d["label"] + " built!\n-" + format_number(price) + "$")

func _on_infrastructure_close_button_down() -> void:
	infra_panel.global_position = Vector2(0, 0)
	infra_panel.hide()
