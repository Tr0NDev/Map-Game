extends Node
@onready var pop_panel : Panel = $"../"
@onready var vbox : VBoxContainer = $"../VBoxContainer"

func _ready():
	pop_panel.visibility_changed.connect(func():
		if pop_panel.visible:
			display()
	)

func display():
	for child in vbox.get_children():
		child.queue_free()
	if Data.player_country == null:
		return

	var pop = Data.player_country.population
	var eco = Data.player_country.economy

	add_label("👥 Population", 20, Color.WHITE)
	add_separator()
	add_label("Population: " + fmt(pop.pop_number), 14, Color.WHITE)

	var approval_color_var = approval_color(pop.approval)
	var approval_trend = get_approval_trend()
	add_label("Approval: " + str(pop.approval) + "% " + approval_trend, 14, approval_color_var)
	add_separator()

	add_label("Improve Approval:", 13, Color.GRAY)
	var approve_row = HBoxContainer.new()
	for c in [["+2 (10M$)", 10000000, 2], ["+5 (30M$)", 30000000, 5]]:
		var btn = Button.new()
		btn.text = c[0]
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var cost_val = c[1]
		var gain = c[2]
		btn.pressed.connect(func():
			if Data.player_country == null: return
			var money = float(Data.player_country.economy.money)
			if money < cost_val:
				Data.show_popup("Not enough money!")
				return
			var cn = Data.player_country.name
			var new_approval = clamp(Data.player_country.population.approval + gain, 0, 100)
			if multiplayer.is_server():
				Data.apply_economy_field.rpc(cn, "money", money - cost_val)
				Data.apply_population_field.rpc(cn, "approval", new_approval)
			else:
				Data.request_set_economy_field.rpc_id(1, cn, "money", money - cost_val)
				Data.request_set_population_field.rpc_id(1, cn, "approval", new_approval)
			Data.show_popup("Approval +" + str(gain) + "%")
			display()
		)
		approve_row.add_child(btn)
	vbox.add_child(approve_row)
	add_separator()

	add_label("💰 Economy", 20, Color.WHITE)
	add_separator()
	add_label("Type: " + str(eco.type), 14, Color.WHITE)
	add_label("Money: " + fmt_money(float(eco.money)) + "$", 14, Color.GREEN)
	add_label("Avg Salary: " + str(eco.avg_salary) + "$", 14, Color.WHITE)
	add_separator()

	add_label("📊 Budgets & Taxes", 16, Color.WHITE)
	add_separator()
	add_spin("Tax Rate", "tax_rate", eco.tax_rate, 0, 90, "%", Color.YELLOW,
		tax_effect(str(eco.tax_rate).to_float()))
	add_spin("Military Budget", "military_budget", eco.military_budget, 0, 50, "%", Color.ORANGE_RED, "")
	add_spin("Infrastructure Budget", "infrastructure_budget", eco.infrastructure_budget, 0, 50, "%", Color.YELLOW, "")
	add_spin("Social Budget", "social_bugdet", eco.social_bugdet, 0, 50, "%", Color.LIGHT_BLUE,
		social_effect(str(eco.social_bugdet).to_float()))

func get_approval_trend() -> String:
	if Data.player_country == null: return ""
	var eco = Data.player_country.economy
	var res = Data.player_country.resources
	var delta = -1

	var food = res.get("food"); if food == null: food = 0
	var energy = res.get("energy"); if energy == null: energy = 0
	var oil = res.get("oil"); if oil == null: oil = 0

	if food <= 0: delta -= 8
	elif food < 300: delta -= 4
	elif food < 800: delta -= 1
	elif food > 5000: delta += 1

	if energy <= 0: delta -= 5
	elif energy < 300: delta -= 2
	if oil <= 0: delta -= 3
	elif oil < 200: delta -= 1

	var tax = str(eco.tax_rate).to_float()
	if tax > 70: delta -= 3
	elif tax > 50: delta -= 1
	elif tax < 20: delta += 1

	var social = str(eco.social_bugdet).to_float()
	if social > 25: delta += 1
	elif social < 10: delta -= 2

	var money = float(eco.money)
	if money > 500000000: delta += 2
	elif money > 100000000: delta += 1
	elif money < 10000000: delta -= 2

	for w in Data.wars:
		if w["status"] != "active": continue
		if w["attacker"] == Data.player_country.name or w["defender"] == Data.player_country.name:
			delta -= 3
			break

	if delta > 0: return "(▲+" + str(delta) + "/turn)"
	elif delta < 0: return "(▼" + str(delta) + "/turn)"
	return "(→ stable)"

func tax_effect(tax: float) -> String:
	if tax > 70: return "⚠ -3 approval/turn"
	elif tax > 50: return "⚠ -1 approval/turn"
	elif tax < 20: return "✅ +1 approval/turn"
	return ""

func social_effect(social: float) -> String:
	if social > 25: return "✅ +1 approval/turn"
	elif social < 10: return "⚠ -2 approval/turn"
	return ""

func add_spin(label_text: String, field: String, current_val, min_val: int, max_val: int, suffix: String, color: Color, hint: String):
	var col = VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var row = HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var lbl = Label.new()
	lbl.text = label_text + ":"
	lbl.custom_minimum_size = Vector2(180, 0)
	lbl.modulate = color
	lbl.add_theme_font_size_override("font_size", 13)
	row.add_child(lbl)

	var spin = SpinBox.new()
	spin.min_value = min_val
	spin.max_value = max_val
	spin.step = 1
	spin.value = str(current_val).to_float()
	spin.suffix = suffix
	spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spin)

	var apply_btn = Button.new()
	apply_btn.text = "Apply"
	apply_btn.custom_minimum_size = Vector2(60, 0)
	apply_btn.pressed.connect(func():
		var new_val = int(spin.value)
		var country_name = Data.player_country.name
		if multiplayer.is_server():
			Data.apply_economy_field.rpc(country_name, field, new_val)
		else:
			Data.request_set_economy_field.rpc_id(1, country_name, field, new_val)
		Data.show_popup(label_text + " set to " + str(new_val) + suffix)
		display()
	)
	row.add_child(apply_btn)
	col.add_child(row)

	if hint != "":
		var hint_lbl = Label.new()
		hint_lbl.text = "  " + hint
		hint_lbl.add_theme_font_size_override("font_size", 11)
		hint_lbl.modulate = Color.GRAY
		col.add_child(hint_lbl)

	vbox.add_child(col)

func add_label(text: String, size: int, color: Color):
	var lbl = Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", size)
	lbl.modulate = color
	vbox.add_child(lbl)

func add_separator():
	vbox.add_child(HSeparator.new())

func fmt(n: int) -> String:
	if n >= 1000000:
		return str(snapped(n / 1000000.0, 0.1)).replace(".0", "") + "M"
	elif n >= 1000:
		return str(snapped(n / 1000.0, 0.1)).replace(".0", "") + "k"
	return str(n)

func fmt_money(n: float) -> String:
	if n >= 1000000000:
		return str(snapped(n / 1000000000.0, 0.01)).replace(".0", "") + "B"
	elif n >= 1000000:
		return str(snapped(n / 1000000.0, 0.1)).replace(".0", "") + "M"
	elif n >= 1000:
		return str(snapped(n / 1000.0, 0.1)).replace(".0", "") + "k"
	return str(int(n))

func approval_color(approval: int) -> Color:
	if approval >= 70: return Color.GREEN
	if approval >= 40: return Color.YELLOW
	return Color.RED

func _on_population_close_button_down() -> void:
	pop_panel.global_position = Vector2(0, 0)
	pop_panel.hide()
