extends Node
@onready var create_panel : Panel = $"../"
@onready var vbox : VBoxContainer = $"../ScrollContainer/Vbox"

var build_costs = {
	"farm": {"food": 0, "wood": 500, "money": 10000000},
	"sawmill": {"wood": 0, "metal": 200, "money": 25000000},
	"coal_mine": {"metal": 300, "money": 40000000},
	"power_plant": {"metal": 500, "coal": 200, "money": 60000000},
	"metal_foundry": {"metal": 800, "coal": 400, "money": 80000000},
	"gas_pipeline": {"metal": 600, "money": 120000000},
	"oil_refinery": {"metal": 1000, "oil": 500, "money": 200000000},
	"data_center": {"metal": 500, "rare_earth": 100, "digital": 200, "money": 300000000},
	"gold_mine": {"metal": 400, "money": 400000000},
	"rare_earth_mine": {"metal": 600, "money": 600000000},
	"nuclear_plant": {"metal": 2000, "uranium": 500, "money": 1000000000},
	"soldier": {"food": 100, "money": 50000},
	"tank": {"metal": 50, "oil": 20, "money": 5000000},
	"armored_vehicle": {"metal": 30, "oil": 10, "money": 2000000},
	"aircraft": {"metal": 100, "oil": 50, "rare_earth": 10, "money": 20000000},
	"destroyer": {"metal": 500, "oil": 200, "money": 80000000},
	"submarine": {"metal": 400, "oil": 150, "uranium": 10, "money": 100000000},
	"aircraft_carrier": {"metal": 2000, "oil": 500, "money": 500000000},
	"cyber_power": {"digital": 500, "rare_earth": 50, "gold": 10, "money": 50000000},
	"missile": {"metal": 200, "digital": 50, "money": 5000000},
}

var build_labels = {
	"farm": "Farm", "sawmill": "Sawmill", "coal_mine": "Coal Mine",
	"power_plant": "Power Plant", "metal_foundry": "Metal Foundry",
	"gas_pipeline": "Gas Pipeline", "oil_refinery": "Oil Refinery",
	"data_center": "Data Center", "gold_mine": "Gold Mine",
	"rare_earth_mine": "Rare Earth Mine", "nuclear_plant": "Nuclear Plant",
	"soldier": "Soldier", "tank": "Tank", "armored_vehicle": "Armored Vehicle",
	"aircraft": "Aircraft", "destroyer": "Destroyer", "submarine": "Submarine",
	"aircraft_carrier": "Aircraft Carrier", "cyber_power": "Cyber Power",
	"missile": "Missile",
}

var infra_keys = ["farm", "sawmill", "coal_mine", "power_plant", "metal_foundry", "gas_pipeline", "oil_refinery", "data_center", "gold_mine", "rare_earth_mine", "nuclear_plant"]
var military_keys = ["soldier", "tank", "armored_vehicle", "aircraft", "destroyer", "submarine", "aircraft_carrier", "cyber_power", "missile"]


func _ready():
	create_panel.visibility_changed.connect(func():
		if create_panel.visible:
			display_build_menu()
	)

func display_build_menu():
	if Data.player_country == null:
		return
	for child in vbox.get_children():
		child.queue_free()

	add_section("Infrastructure", infra_keys)
	vbox.add_child(HSeparator.new())
	add_section("Military", military_keys)

func add_section(title: String, keys: Array):
	var title_lbl = Label.new()
	title_lbl.text = title
	title_lbl.add_theme_font_size_override("font_size", 16)
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title_lbl)

	for key in keys:
		var row = HBoxContainer.new()

		var name_lbl = Label.new()
		name_lbl.text = build_labels[key]
		name_lbl.custom_minimum_size = Vector2(140, 0)
		row.add_child(name_lbl)

		var cost_lbl = Label.new()
		var cost_text = ""
		for resource in build_costs[key]:
			cost_text += fmt(build_costs[key][resource]) + " " + resource + "  "
		cost_lbl.text = cost_text.strip_edges()
		cost_lbl.add_theme_font_size_override("font_size", 10)
		cost_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(cost_lbl)

		var qty_spin = SpinBox.new()
		qty_spin.min_value = 1
		qty_spin.max_value = 9999
		qty_spin.value = 1
		qty_spin.custom_minimum_size = Vector2(80, 0)
		row.add_child(qty_spin)

		var build_btn = Button.new()
		build_btn.text = "Build"
		build_btn.pressed.connect(func(): on_build_pressed(key, int(qty_spin.value)))
		row.add_child(build_btn)

		vbox.add_child(row)

func on_build_pressed(key: String, qty: int):
	var country = Data.player_country
	var costs = build_costs[key]

	for resource in costs:
		var total_cost = costs[resource] * qty
		if resource == "money":
			if float(country.economy.money) < total_cost:
				Data.show_popup("Not enough money!\nNeed " + fmt(total_cost) + "$")
				return
		else:
			var current = country.resources.get(resource)
			if current == null:
				current = 0
			if current < total_cost:
				Data.show_popup("Not enough " + resource + "!\nNeed " + fmt(float(total_cost)))
				return

	for resource in costs:
		var total_cost = costs[resource] * qty
		if resource == "money":
			var new_money = float(country.economy.money) - total_cost
			if multiplayer.is_server():
				Data.apply_economy_field.rpc(country.name, "money", new_money)
			else:
				Data.request_set_economy_field.rpc_id(1, country.name, "money", new_money)
		else:
			var current = country.resources.get(resource)
			if current == null:
				current = 0
			var new_val = current - total_cost
			if multiplayer.is_server():
				Data.apply_resources_field.rpc(country.name, resource, new_val)
			else:
				Data.request_set_resources_field.rpc_id(1, country.name, resource, new_val)

	if infra_keys.has(key):
		var current = country.infrastructure.get(key)
		if current == null:
			current = 0
		var new_val = current + qty
		if multiplayer.is_server():
			Data.apply_infra_field.rpc(country.name, key, new_val)
		else:
			Data.request_set_infra_field.rpc_id(1, country.name, key, new_val)
	elif military_keys.has(key):
		var current = country.army.get(key)
		if current == null:
			current = 0
		var new_val = current + qty
		if multiplayer.is_server():
			Data.apply_army_field.rpc(country.name, key, new_val)
		else:
			Data.request_set_army_field.rpc_id(1, country.name, key, new_val)

	Data.show_popup("Built " + str(qty) + "x " + build_labels[key] + "!")
	display_build_menu()

func fmt(n: float) -> String:
	if n >= 1000000:
		return str(snapped(n / 1000000.0, 0.1)).replace(".0", "") + "M"
	elif n >= 1000:
		return str(snapped(n / 1000.0, 0.1)).replace(".0", "") + "k"
	return str(int(n))

func _on_create_close_button_down() -> void:
	create_panel.global_position = Vector2(0, 0)
	create_panel.hide()
