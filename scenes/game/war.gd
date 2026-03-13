extends Node

@onready var war_panel : Panel = $"../"
@onready var vbox : VBoxContainer = $"../ScrollContainer/Vbox"

func _ready():
	war_panel.visibility_changed.connect(func():
		if war_panel.visible:
			display_wars()
	)
	Data.wars_updated.connect(func():
		if war_panel.visible:
			display_wars()
	)
	Data.peace_updated.connect(func():
		if war_panel.visible:
			display_wars()
	)
	Data.eliminated.connect(func():
		war_panel.hide()
		Data.show_popup("💀 You have been eliminated!")
	)

func display_wars():
	for child in vbox.get_children():
		child.queue_free()

	if Data.player_country == null:
		return

	var player_name = Data.player_country.name

	var declare_btn = Button.new()
	declare_btn.text = "⚔ Declare War"
	declare_btn.modulate = Color.RED
	declare_btn.custom_minimum_size = Vector2(0, 40)
	declare_btn.pressed.connect(open_declare_war_menu)
	vbox.add_child(declare_btn)

	vbox.add_child(HSeparator.new())

	var has_proposals = false
	for p in Data.peace_proposals:
		if p["to"] != player_name and p["from"] != player_name:
			continue
		if p["status"] != "pending":
			continue
		has_proposals = true
		var prop_row = HBoxContainer.new()
		var prop_lbl = Label.new()
		prop_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		prop_lbl.modulate = Color.LIGHT_BLUE

		if p["to"] == player_name:
			var type_str = {"classic": "🤝", "invasion": "⚔", "contract": "📜"}.get(p.get("peace_type", "classic"), "🕊")
			prop_lbl.text = type_str + " " + p["from"] + " proposes: " + p.get("peace_type", "classic").capitalize()
			var accept_btn = Button.new()
			accept_btn.text = "Accept"
			accept_btn.modulate = Color.GREEN
			accept_btn.pressed.connect(func():
				if multiplayer.is_server():
					Data.request_accept_peace(p["from"], p["to"])
				else:
					Data.request_accept_peace.rpc_id(1, p["from"], p["to"])
			)
			var refuse_btn = Button.new()
			refuse_btn.text = "Refuse"
			refuse_btn.modulate = Color.RED
			refuse_btn.pressed.connect(func():
				if multiplayer.is_server():
					Data.request_refuse_peace(p["from"], p["to"])
				else:
					Data.request_refuse_peace.rpc_id(1, p["from"], p["to"])
			)
			prop_row.add_child(prop_lbl)
			prop_row.add_child(accept_btn)
			prop_row.add_child(refuse_btn)
		else:
			prop_lbl.text = "🕊 Peace proposal pending → " + p["to"]
			prop_row.add_child(prop_lbl)

		vbox.add_child(prop_row)
		vbox.add_child(HSeparator.new())

	var my_wars = []
	for war in Data.wars:
		if war["attacker"] == player_name or war["defender"] == player_name:
			my_wars.append(war)

	if my_wars.is_empty() and not has_proposals:
		var lbl = Label.new()
		lbl.text = "No active wars."
		vbox.add_child(lbl)
		return

	for war in my_wars:
		var row = HBoxContainer.new()
		var status_color = Color.RED if war["status"] == "active" else Color.GRAY
		var info = Label.new()
		info.text = "⚔ " + war["attacker"] + " vs " + war["defender"] + "  |  " + war["status"].to_upper()
		info.modulate = status_color
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info)
		var detail_btn = Button.new()
		detail_btn.text = "Details"
		detail_btn.pressed.connect(func(): open_war_detail(war))
		row.add_child(detail_btn)
		vbox.add_child(row)
		vbox.add_child(HSeparator.new())


func open_declare_war_menu():
	var canvas = CanvasLayer.new()
	get_tree().root.add_child(canvas)

	var panel = Panel.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color("#1a0000f0")
	style.border_color = Color("#cc0000")
	style.set_border_width_all(2)
	panel.add_theme_stylebox_override("panel", style)
	panel.custom_minimum_size = Vector2(520, 580)
	canvas.add_child(panel)

	var main_vbox = VBoxContainer.new()
	main_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 16)
	panel.add_child(main_vbox)

	var title = Label.new()
	title.text = "⚔ Declare War"
	title.add_theme_font_size_override("font_size", 22)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.modulate = Color.RED
	main_vbox.add_child(title)
	main_vbox.add_child(HSeparator.new())

	var target_row = HBoxContainer.new()
	var target_lbl = Label.new()
	target_lbl.text = "Target:"
	target_lbl.custom_minimum_size = Vector2(100, 0)
	target_row.add_child(target_lbl)
	var target_option = OptionButton.new()
	target_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var player_name = Data.player_country.name
	for c in Data.country_list.keys():
		if c != player_name:
			target_option.add_item(c)
	target_row.add_child(target_option)
	main_vbox.add_child(target_row)
	main_vbox.add_child(HSeparator.new())

	var troops_lbl = Label.new()
	troops_lbl.text = "Select troops to send:"
	troops_lbl.add_theme_font_size_override("font_size", 14)
	main_vbox.add_child(troops_lbl)

	var unit_types = {
		"soldier": "Soldiers",
		"tank": "Tanks",
		"armored_vehicle": "Armored Vehicles",
		"aircraft": "Aircraft",
		"destroyer": "Destroyers",
		"submarine": "Submarines",
		"aircraft_carrier": "Carriers",
	}

	var spinboxes = {}
	var army = Data.player_country.army

	for unit in unit_types:
		var available = army.get(unit)
		if available == null:
			available = 0
		if available <= 0:
			continue

		var row = HBoxContainer.new()
		var name_lbl = Label.new()
		name_lbl.text = unit_types[unit]
		name_lbl.custom_minimum_size = Vector2(160, 0)
		row.add_child(name_lbl)

		var avail_lbl = Label.new()
		avail_lbl.text = "(" + str(available) + " avail)"
		avail_lbl.custom_minimum_size = Vector2(100, 0)
		avail_lbl.modulate = Color.GRAY
		avail_lbl.add_theme_font_size_override("font_size", 11)
		row.add_child(avail_lbl)

		var spin = SpinBox.new()
		spin.min_value = 0
		spin.max_value = available
		spin.step = 1
		spin.value = 0
		spin.custom_minimum_size = Vector2(100, 0)
		row.add_child(spin)
		spinboxes[unit] = spin

		main_vbox.add_child(row)

	main_vbox.add_child(HSeparator.new())

	var btn_row = HBoxContainer.new()

	var cancel_btn = Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cancel_btn.pressed.connect(func(): canvas.call_deferred("queue_free"))
	btn_row.add_child(cancel_btn)

	var confirm_btn = Button.new()
	confirm_btn.text = "⚔ DECLARE WAR"
	confirm_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	confirm_btn.modulate = Color.RED
	confirm_btn.pressed.connect(func():
		var target = target_option.get_item_text(target_option.selected)
		var troops = {}
		for unit in spinboxes:
			var val = int(spinboxes[unit].value)
			if val > 0:
				troops[unit] = val
		if troops.is_empty():
			Data.show_popup("Select at least one unit!")
			return
		confirm_declare_war(target, troops)
		canvas.call_deferred("queue_free")
	)
	btn_row.add_child(confirm_btn)
	main_vbox.add_child(btn_row)

	await get_tree().process_frame
	var screen_size = get_viewport().get_visible_rect().size
	panel.position = Vector2((screen_size.x - panel.size.x) / 2, (screen_size.y - panel.size.y) / 2)

func confirm_declare_war(target: String, troops: Dictionary):
	var player_name = Data.player_country.name

	for unit in troops:
		var current = Data.player_country.army.get(unit)
		if current == null: current = 0
		var new_val = max(0, current - troops[unit])
		if multiplayer.is_server():
			Data.apply_army_field.rpc(player_name, unit, new_val)
		else:
			Data.request_set_army_field.rpc_id(1, player_name, unit, new_val)

	if multiplayer.is_server():
		Data.declare_war(player_name, target, troops)
	else:
		Data.request_declare_war.rpc_id(1, player_name, target, troops)

	Data.show_popup("War declared against " + target + "!\nTroops deployed.")
	display_wars()

func open_war_detail(war: Dictionary):
	var canvas = CanvasLayer.new()
	get_tree().root.add_child(canvas)

	var panel = Panel.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color("#1a0000e6")
	style.border_color = Color("#cc0000")
	style.set_border_width_all(2)
	panel.add_theme_stylebox_override("panel", style)
	panel.custom_minimum_size = Vector2(520, 650)
	canvas.add_child(panel)

	var scroll = ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 10)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)

	var main_vbox = VBoxContainer.new()
	main_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(main_vbox)

	var title = Label.new()
	title.text = "⚔ WAR: " + war["attacker"] + " vs " + war["defender"]
	title.add_theme_font_size_override("font_size", 22)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.modulate = Color.RED
	main_vbox.add_child(title)
	main_vbox.add_child(HSeparator.new())

	var status_lbl = Label.new()
	status_lbl.text = "Status: " + war["status"].to_upper()
	status_lbl.modulate = Color.RED if war["status"] == "active" else Color.GRAY
	main_vbox.add_child(status_lbl)

	var turn_lbl = Label.new()
	turn_lbl.text = "Started turn: " + str(war.get("start_turn", "?"))
	main_vbox.add_child(turn_lbl)
	main_vbox.add_child(HSeparator.new())

	var troops_title = Label.new()
	troops_title.text = "Deployed troops:"
	troops_title.add_theme_font_size_override("font_size", 14)
	main_vbox.add_child(troops_title)

	var troops_hbox = HBoxContainer.new()
	var att_vbox = VBoxContainer.new()
	att_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var att_title = Label.new()
	att_title.text = war["attacker"]
	att_title.add_theme_font_size_override("font_size", 13)
	att_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	att_vbox.add_child(att_title)
	for unit in war.get("attacker_troops", {}):
		var lbl = Label.new()
		lbl.text = unit + ": " + str(war["attacker_troops"][unit])
		att_vbox.add_child(lbl)
	troops_hbox.add_child(att_vbox)
	troops_hbox.add_child(VSeparator.new())
	var def_vbox = VBoxContainer.new()
	def_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var def_title = Label.new()
	def_title.text = war["defender"]
	def_title.add_theme_font_size_override("font_size", 13)
	def_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	def_vbox.add_child(def_title)
	for unit in war.get("defender_troops", {}):
		var lbl = Label.new()
		lbl.text = unit + ": " + str(war["defender_troops"][unit])
		def_vbox.add_child(lbl)
	troops_hbox.add_child(def_vbox)
	main_vbox.add_child(troops_hbox)

	main_vbox.add_child(HSeparator.new())

	var player_name_local = Data.player_country.name
	var is_attacker = war["attacker"] == player_name_local
	var is_defender = war["defender"] == player_name_local

	var reinforce_title = Label.new()
	reinforce_title.text = "Send Reinforcements:"
	reinforce_title.add_theme_font_size_override("font_size", 14)
	main_vbox.add_child(reinforce_title)

	var unit_types = {
		"soldier": "Soldiers",
		"tank": "Tanks",
		"armored_vehicle": "Armored Veh.",
		"aircraft": "Aircraft",
		"destroyer": "Destroyers",
		"submarine": "Submarines",
		"aircraft_carrier": "Carriers",
	}

	var reinforce_spinboxes = {}
	var army = Data.player_country.army

	if (is_attacker or is_defender) and war["status"] == "active":
		for unit in unit_types:
			var available = army.get(unit)
			if available == null: available = 0
			if available <= 0:
				continue
			var rrow = HBoxContainer.new()
			var name_lbl = Label.new()
			name_lbl.text = unit_types[unit]
			name_lbl.custom_minimum_size = Vector2(140, 0)
			rrow.add_child(name_lbl)
			var avail_lbl = Label.new()
			avail_lbl.text = "(" + str(available) + ")"
			avail_lbl.modulate = Color.GRAY
			avail_lbl.add_theme_font_size_override("font_size", 11)
			avail_lbl.custom_minimum_size = Vector2(70, 0)
			rrow.add_child(avail_lbl)
			var spin = SpinBox.new()
			spin.min_value = 0
			spin.max_value = available
			spin.step = 1
			spin.value = 0
			spin.custom_minimum_size = Vector2(90, 0)
			rrow.add_child(spin)
			reinforce_spinboxes[unit] = spin
			main_vbox.add_child(rrow)

		var send_btn = Button.new()
		send_btn.text = "Send Reinforcements"
		send_btn.modulate = Color.YELLOW
		send_btn.pressed.connect(func():
			var troops = {}
			for unit in reinforce_spinboxes:
				var val = int(reinforce_spinboxes[unit].value)
				if val > 0:
					troops[unit] = val
			if troops.is_empty():
				Data.show_popup("Select at least one unit!")
				return
			send_reinforcements(war, troops)
			canvas.call_deferred("queue_free")
		)
		main_vbox.add_child(send_btn)
	else:
		var no_lbl = Label.new()
		no_lbl.text = "You are not involved in this war."
		no_lbl.modulate = Color.GRAY
		main_vbox.add_child(no_lbl)

	main_vbox.add_child(HSeparator.new())

	var losses_title = Label.new()
	losses_title.text = "Losses:"
	losses_title.add_theme_font_size_override("font_size", 14)
	main_vbox.add_child(losses_title)

	var losses_hbox = HBoxContainer.new()
	var att_loss_vbox = VBoxContainer.new()
	att_loss_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for unit in war.get("attacker_losses", {}):
		var lbl = Label.new()
		lbl.text = "-" + str(war["attacker_losses"][unit]) + " " + unit
		lbl.modulate = Color.ORANGE_RED
		att_loss_vbox.add_child(lbl)
	losses_hbox.add_child(att_loss_vbox)
	losses_hbox.add_child(VSeparator.new())
	var def_loss_vbox = VBoxContainer.new()
	def_loss_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for unit in war.get("defender_losses", {}):
		var lbl = Label.new()
		lbl.text = "-" + str(war["defender_losses"][unit]) + " " + unit
		lbl.modulate = Color.ORANGE_RED
		def_loss_vbox.add_child(lbl)
	losses_hbox.add_child(def_loss_vbox)
	main_vbox.add_child(losses_hbox)

	main_vbox.add_child(HSeparator.new())
	
	if war["status"] == "active" and (is_attacker or is_defender):
		var strike_btn = Button.new()
		strike_btn.text = "🚀 Launch Strike"
		strike_btn.modulate = Color.ORANGE_RED
		strike_btn.pressed.connect(func(): open_strike_menu(war))
		main_vbox.add_child(strike_btn)

	if war["status"] == "active" and (is_attacker or is_defender):
		var peace_btn = Button.new()
		peace_btn.text = "🕊 Propose Peace"
		peace_btn.modulate = Color.LIGHT_BLUE
		peace_btn.pressed.connect(func(): open_peace_menu(war, canvas))
		main_vbox.add_child(peace_btn)

	var ok_btn = Button.new()
	ok_btn.text = "Close"
	ok_btn.custom_minimum_size = Vector2(100, 40)
	main_vbox.add_child(ok_btn)

	await get_tree().process_frame
	var screen_size = get_viewport().get_visible_rect().size
	panel.position = Vector2((screen_size.x - panel.size.x) / 2, 20)
	ok_btn.pressed.connect(func(): canvas.call_deferred("queue_free"))



func open_strike_menu(war: Dictionary):
	var canvas = CanvasLayer.new()
	get_tree().root.add_child(canvas)

	var panel = Panel.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color("#1a0000f0")
	style.border_color = Color("#cc0000")
	style.set_border_width_all(2)
	panel.add_theme_stylebox_override("panel", style)
	panel.custom_minimum_size = Vector2(480, 420)
	canvas.add_child(panel)

	var main_vbox = VBoxContainer.new()
	main_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 16)
	panel.add_child(main_vbox)

	var title = Label.new()
	title.text = "🚀 Launch Strike"
	title.add_theme_font_size_override("font_size", 20)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.modulate = Color.ORANGE_RED
	main_vbox.add_child(title)
	main_vbox.add_child(HSeparator.new())

	var player_name = Data.player_country.name
	var army = Data.player_country.army

	var m_count = army.get("missile")
	if m_count == null: m_count = 0

	var missiles_lbl = Label.new()
	missiles_lbl.text = "Available missiles: " + str(int(m_count))
	missiles_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(missiles_lbl)
	main_vbox.add_child(HSeparator.new())

	var qty_row = HBoxContainer.new()
	var qty_lbl = Label.new()
	qty_lbl.text = "Quantity:"
	qty_lbl.custom_minimum_size = Vector2(130, 0)
	qty_row.add_child(qty_lbl)
	var qty_spin = SpinBox.new()
	qty_spin.min_value = 1
	qty_spin.max_value = max(1, m_count)
	qty_spin.value = 1
	qty_spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	qty_row.add_child(qty_spin)
	main_vbox.add_child(qty_row)

	main_vbox.add_child(HSeparator.new())

	var target_lbl = Label.new()
	target_lbl.text = "Target:"
	target_lbl.add_theme_font_size_override("font_size", 14)
	main_vbox.add_child(target_lbl)

	var target_types = {
		"soldier": "👥 Soldiers",
		"tank": "🛡 Tanks",
		"aircraft": "✈ Aircraft",
		"infrastructure": "🏭 Infrastructure",
		"resources": "📦 Resources",
		"population": "🏘 Population",
	}

	var target_option = OptionButton.new()
	target_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for key in target_types:
		target_option.add_item(target_types[key])
	main_vbox.add_child(target_option)

	var target_keys = target_types.keys()

	main_vbox.add_child(HSeparator.new())

	var btn_row = HBoxContainer.new()
	var cancel_btn = Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cancel_btn.pressed.connect(func(): canvas.call_deferred("queue_free"))
	btn_row.add_child(cancel_btn)

	var launch_btn = Button.new()
	launch_btn.text = "🚀 LAUNCH"
	launch_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	launch_btn.modulate = Color.ORANGE_RED
	launch_btn.pressed.connect(func():
		var qty = int(qty_spin.value)
		var target_type = target_keys[target_option.selected]
		var defender = war["defender"] if war["attacker"] == player_name else war["attacker"]

		var stock = army.get("missile")
		if stock == null: stock = 0
		if qty > stock:
			Data.show_popup("Not enough missiles!\nAvailable: " + str(int(stock)))
			return

		if multiplayer.is_server():
			Data.request_strike(player_name, defender, "missile", qty, target_type)
		else:
			Data.request_strike.rpc_id(1, player_name, defender, "missile", qty, target_type)

		Data.show_popup("🚀 Strike launched!\n" + str(qty) + " missile(s)\nTarget: " + target_type)
		canvas.call_deferred("queue_free")
	)
	btn_row.add_child(launch_btn)
	main_vbox.add_child(btn_row)

	await get_tree().process_frame
	var screen_size = get_viewport().get_visible_rect().size
	panel.position = Vector2((screen_size.x - panel.size.x) / 2, (screen_size.y - panel.size.y) / 2)


func send_reinforcements(war: Dictionary, troops: Dictionary):
	var player_name = Data.player_country.name

	for unit in troops:
		var current = Data.player_country.army.get(unit)
		if current == null: current = 0
		var new_val = max(0, current - troops[unit])
		if multiplayer.is_server():
			Data.apply_army_field.rpc(player_name, unit, new_val)
		else:
			Data.request_set_army_field.rpc_id(1, player_name, unit, new_val)

	if multiplayer.is_server():
		Data.add_war_troops(player_name, war["attacker"], war["defender"], troops)
	else:
		Data.add_war_troops.rpc_id(1, player_name, war["attacker"], war["defender"], troops)

	Data.show_popup("Reinforcements sent!")
	display_wars()

func propose_peace(war: Dictionary, canvas: CanvasLayer):
	var player_name = Data.player_country.name
	var other = war["defender"] if war["attacker"] == player_name else war["attacker"]

	var c2 = CanvasLayer.new()
	get_tree().root.add_child(c2)

	var panel = Panel.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color("#1a0000f0")
	style.border_color = Color("#cc0000")
	style.set_border_width_all(2)
	panel.add_theme_stylebox_override("panel", style)
	panel.custom_minimum_size = Vector2(400, 300)
	c2.add_child(panel)

	vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 16)
	panel.add_child(vbox)

	var title = Label.new()
	title.text = "🕊 Peace Options with " + other
	title.add_theme_font_size_override("font_size", 18)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	vbox.add_child(HSeparator.new())

	var classic_btn = Button.new()
	classic_btn.text = "🕊 Propose Classic Peace"
	classic_btn.modulate = Color.LIGHT_BLUE
	classic_btn.pressed.connect(func():
		var proposal = {"from": player_name, "to": other, "status": "pending", "peace_type": "classic", "terms": {}}
		if multiplayer.is_server():
			Data.peace_proposals.append(proposal)
			Data.sync_peace.rpc(Data.peace_proposals)
			Data.peace_updated.emit()
		else:
			Data.requestpropose_peace.rpc_id(1, player_name, other)
		Data.show_popup("Classic peace proposal sent to " + other + "!")
		c2.call_deferred("queue_free")
		canvas.call_deferred("queue_free")
	)
	vbox.add_child(classic_btn)

	vbox.add_child(HSeparator.new())

	var surrender_btn = Button.new()
	surrender_btn.text = "🏳 Surrender to " + other
	surrender_btn.modulate = Color.ORANGE_RED
	surrender_btn.pressed.connect(func():
		var proposal = {"from": other, "to": player_name, "status": "pending", "peace_type": "surrender", "terms": {}}
		if multiplayer.is_server():
			Data.peace_proposals.append(proposal)
			Data.sync_peace.rpc(Data.peace_proposals)
			Data.peace_updated.emit()
			var pid = Data._get_pid(other)
			if pid == -1:
				Data.request_accept_peace(other, player_name)
		else:
			Data.requestpropose_peace.rpc_id(1, other, player_name)
		Data.show_popup("You offered surrender to " + other + ".\nAwaiting response...")
		c2.call_deferred("queue_free")
		canvas.call_deferred("queue_free")
	)
	vbox.add_child(surrender_btn)

	var cancel_btn = Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.pressed.connect(func(): c2.call_deferred("queue_free"))
	vbox.add_child(cancel_btn)

	await get_tree().process_frame
	var screen_size = get_viewport().get_visible_rect().size
	panel.position = Vector2((screen_size.x - panel.size.x) / 2, (screen_size.y - panel.size.y) / 2)

func open_peace_menu(war: Dictionary, parent_canvas: CanvasLayer):
	var canvas = CanvasLayer.new()
	get_tree().root.add_child(canvas)

	var panel = Panel.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color("#001a1af0")
	style.border_color = Color("#00aaaa")
	style.set_border_width_all(2)
	panel.add_theme_stylebox_override("panel", style)
	panel.custom_minimum_size = Vector2(500, 520)
	canvas.add_child(panel)

	var main_vbox = VBoxContainer.new()
	main_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 16)
	panel.add_child(main_vbox)

	var player_name = Data.player_country.name
	var enemy_name = war["defender"] if war["attacker"] == player_name else war["attacker"]

	var title = Label.new()
	title.text = "🕊 Peace Terms → " + enemy_name
	title.add_theme_font_size_override("font_size", 20)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.modulate = Color.LIGHT_BLUE
	main_vbox.add_child(title)
	main_vbox.add_child(HSeparator.new())

	var classic_lbl = Label.new()
	classic_lbl.text = "🤝 Classic Peace"
	classic_lbl.add_theme_font_size_override("font_size", 14)
	main_vbox.add_child(classic_lbl)

	var classic_desc = Label.new()
	classic_desc.text = "Both sides stop fighting, relations +10."
	classic_desc.modulate = Color.GRAY
	classic_desc.add_theme_font_size_override("font_size", 11)
	main_vbox.add_child(classic_desc)

	var classic_btn = Button.new()
	classic_btn.text = "Propose Classic Peace"
	classic_btn.modulate = Color.LIGHT_BLUE
	classic_btn.pressed.connect(func():
		send_peace_proposal(player_name, enemy_name, "classic", {})
		canvas.call_deferred("queue_free")
		parent_canvas.call_deferred("queue_free")
	)
	main_vbox.add_child(classic_btn)
	main_vbox.add_child(HSeparator.new())
	
	main_vbox.add_child(HSeparator.new())

	var surrender_lbl = Label.new()
	surrender_lbl.text = "🏳 Demand Surrender"
	surrender_lbl.add_theme_font_size_override("font_size", 14)
	surrender_lbl.modulate = Color.RED
	main_vbox.add_child(surrender_lbl)

	var surrender_desc = Label.new()
	surrender_desc.text = "Demand total surrender — enemy loses everything.\nOnly works if they are weak enough."
	surrender_desc.modulate = Color.GRAY
	surrender_desc.add_theme_font_size_override("font_size", 11)
	main_vbox.add_child(surrender_desc)

	var surrender_btn = Button.new()
	surrender_btn.text = "💀 Demand Surrender"
	surrender_btn.modulate = Color.RED
	surrender_btn.pressed.connect(func():
		send_peace_proposal(player_name, enemy_name, "surrender", {})
		canvas.call_deferred("queue_free")
		parent_canvas.call_deferred("queue_free")
	)
	main_vbox.add_child(surrender_btn)

	main_vbox.add_child(HSeparator.new())

	var invasion_lbl = Label.new()
	invasion_lbl.text = "⚔ Forced Annexation"
	invasion_lbl.add_theme_font_size_override("font_size", 14)
	invasion_lbl.modulate = Color.ORANGE_RED
	main_vbox.add_child(invasion_lbl)

	var invasion_desc = Label.new()
	invasion_desc.text = "Demand % of enemy resources. They can accept or refuse."
	invasion_desc.modulate = Color.GRAY
	invasion_desc.add_theme_font_size_override("font_size", 11)
	main_vbox.add_child(invasion_desc)

	var invasion_row = HBoxContainer.new()
	var invasion_pct_lbl = Label.new()
	invasion_pct_lbl.text = "% to take:"
	invasion_pct_lbl.custom_minimum_size = Vector2(100, 0)
	invasion_row.add_child(invasion_pct_lbl)
	var invasion_spin = SpinBox.new()
	invasion_spin.min_value = 5
	invasion_spin.max_value = 80
	invasion_spin.step = 5
	invasion_spin.value = 20
	invasion_spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	invasion_row.add_child(invasion_spin)
	main_vbox.add_child(invasion_row)

	var invasion_btn = Button.new()
	invasion_btn.text = "Demand Annexation"
	invasion_btn.modulate = Color.ORANGE_RED
	invasion_btn.pressed.connect(func():
		send_peace_proposal(player_name, enemy_name, "invasion", {"percent": int(invasion_spin.value)})
		canvas.call_deferred("queue_free")
		parent_canvas.call_deferred("queue_free")
	)
	main_vbox.add_child(invasion_btn)
	main_vbox.add_child(HSeparator.new())

	var contract_lbl = Label.new()
	contract_lbl.text = "📜 Forced Contract"
	contract_lbl.add_theme_font_size_override("font_size", 14)
	contract_lbl.modulate = Color.YELLOW
	main_vbox.add_child(contract_lbl)

	var contract_desc = Label.new()
	contract_desc.text = "Force a resource trade contract for N turns."
	contract_desc.modulate = Color.GRAY
	contract_desc.add_theme_font_size_override("font_size", 11)
	main_vbox.add_child(contract_desc)

	var resources = ["oil", "metal", "coal", "food", "energy", "wood", "gold", "rare_earth", "digital", "uranium", "gas"]

	var c_row1 = HBoxContainer.new()
	var c_res_lbl = Label.new()
	c_res_lbl.text = "They give:"
	c_res_lbl.custom_minimum_size = Vector2(100, 0)
	c_row1.add_child(c_res_lbl)
	var c_res_option = OptionButton.new()
	c_res_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for r in resources: c_res_option.add_item(r)
	c_row1.add_child(c_res_option)
	var c_qty_spin = SpinBox.new()
	c_qty_spin.min_value = 1
	c_qty_spin.max_value = 10000
	c_qty_spin.value = 100
	c_qty_spin.custom_minimum_size = Vector2(90, 0)
	c_row1.add_child(c_qty_spin)
	main_vbox.add_child(c_row1)

	var c_row2 = HBoxContainer.new()
	var c_give_lbl = Label.new()
	c_give_lbl.text = "You give:"
	c_give_lbl.custom_minimum_size = Vector2(100, 0)
	c_row2.add_child(c_give_lbl)
	var c_give_option = OptionButton.new()
	c_give_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for r in resources: c_give_option.add_item(r)
	c_row2.add_child(c_give_option)
	var c_give_spin = SpinBox.new()
	c_give_spin.min_value = 0
	c_give_spin.max_value = 10000
	c_give_spin.value = 0
	c_give_spin.custom_minimum_size = Vector2(90, 0)
	c_row2.add_child(c_give_spin)
	main_vbox.add_child(c_row2)

	var c_turn_row = HBoxContainer.new()
	var c_turn_lbl = Label.new()
	c_turn_lbl.text = "Duration (turns):"
	c_turn_lbl.custom_minimum_size = Vector2(130, 0)
	c_turn_row.add_child(c_turn_lbl)
	var c_turn_spin = SpinBox.new()
	c_turn_spin.min_value = 1
	c_turn_spin.max_value = 20
	c_turn_spin.value = 5
	c_turn_spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	c_turn_row.add_child(c_turn_spin)
	main_vbox.add_child(c_turn_row)

	var contract_btn = Button.new()
	contract_btn.text = "Impose Contract"
	contract_btn.modulate = Color.YELLOW
	contract_btn.pressed.connect(func():
		send_peace_proposal(player_name, enemy_name, "contract", {
			"from_resource": resources[c_give_option.selected],
			"from_quantity": int(c_give_spin.value),
			"to_resource": resources[c_res_option.selected],
			"to_quantity": int(c_qty_spin.value),
			"duration_turns": int(c_turn_spin.value),
		})
		canvas.call_deferred("queue_free")
		parent_canvas.call_deferred("queue_free")
	)
	main_vbox.add_child(contract_btn)
	main_vbox.add_child(HSeparator.new())

	var cancel_btn = Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.pressed.connect(func(): canvas.call_deferred("queue_free"))
	main_vbox.add_child(cancel_btn)

	await get_tree().process_frame
	var screen_size = get_viewport().get_visible_rect().size
	panel.position = Vector2((screen_size.x - panel.size.x) / 2, (screen_size.y - panel.size.y) / 2)


func send_peace_proposal(from: String, to: String, peace_type: String, terms: Dictionary):
	if multiplayer.is_server():
		Data.request_propose_peace_terms(from, to, peace_type, terms)
	else:
		Data.request_propose_peace_terms.rpc_id(1, from, to, peace_type, terms)
	Data.show_popup("Peace proposal sent to " + to + "!")


func _on_war_close_button_down() -> void:
	war_panel.global_position = Vector2(0, 0)
	war_panel.hide()
