extends Node

@onready var contract_panel : Panel = $"../"
@onready var vbox : VBoxContainer = $"../ScrollContainer/VBoxContainer"

var all_resources = ["money", "oil", "metal", "coal", "gas", "uranium", "food", "energy", "wood", "gold", "rare_earth", "digital", "soldier", "tank", "armored_vehicle", "aircraft", "destroyer", "submarine", "aircraft_carrier", "cyber_power", "missile"]

var selected_country = ""
var from_resource = "money"
var to_resource = "money"

func _ready():
	contract_panel.visibility_changed.connect(func():
		if contract_panel.visible:
			display_contracts()
	)
	Data.contracts_updated.connect(func():
		if contract_panel.visible:
			display_contracts()
	)

func display_contracts():
	if Data.player_country == null:
		return

	for child in vbox.get_children():
		child.queue_free()

	var player_name = Data.player_country.name

	var create_title = Label.new()
	create_title.text = "New Contract Proposal"
	create_title.add_theme_font_size_override("font_size", 16)
	create_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(create_title)

	var country_row = HBoxContainer.new()
	var country_lbl = Label.new()
	country_lbl.text = "Target:"
	country_lbl.custom_minimum_size = Vector2(100, 0)
	country_row.add_child(country_lbl)
	var country_option = OptionButton.new()
	for c in Data.country_list.keys():
		if c != player_name:
			country_option.add_item(c)
	if country_option.item_count > 0:
		selected_country = country_option.get_item_text(0)
	country_option.item_selected.connect(func(idx): selected_country = country_option.get_item_text(idx))
	country_row.add_child(country_option)
	vbox.add_child(country_row)

	var give_row = HBoxContainer.new()
	var give_lbl = Label.new()
	give_lbl.text = "I give:"
	give_lbl.custom_minimum_size = Vector2(100, 0)
	give_row.add_child(give_lbl)
	var give_option = OptionButton.new()
	for res in all_resources:
		give_option.add_item(res)
	give_option.item_selected.connect(func(idx): from_resource = all_resources[idx])
	give_row.add_child(give_option)
	var give_spin = SpinBox.new()
	give_spin.min_value = 1
	give_spin.max_value = 999999
	give_spin.value = 100
	give_spin.custom_minimum_size = Vector2(100, 0)
	give_row.add_child(give_spin)
	vbox.add_child(give_row)

	var recv_row = HBoxContainer.new()
	var recv_lbl = Label.new()
	recv_lbl.text = "I receive:"
	recv_lbl.custom_minimum_size = Vector2(100, 0)
	recv_row.add_child(recv_lbl)
	var recv_option = OptionButton.new()
	for res in all_resources:
		recv_option.add_item(res)
	recv_option.item_selected.connect(func(idx): to_resource = all_resources[idx])
	recv_row.add_child(recv_option)
	var recv_spin = SpinBox.new()
	recv_spin.min_value = 1
	recv_spin.max_value = 999999
	recv_spin.value = 100
	recv_spin.custom_minimum_size = Vector2(100, 0)
	recv_row.add_child(recv_spin)
	vbox.add_child(recv_row)

	var dur_row = HBoxContainer.new()
	var dur_lbl = Label.new()
	dur_lbl.text = "Duration:"
	dur_lbl.custom_minimum_size = Vector2(100, 0)
	dur_row.add_child(dur_lbl)
	var dur_spin = SpinBox.new()
	dur_spin.min_value = 1
	dur_spin.max_value = 50
	dur_spin.value = 5
	dur_row.add_child(dur_spin)
	var dur_lbl2 = Label.new()
	dur_lbl2.text = " turns"
	dur_row.add_child(dur_lbl2)
	vbox.add_child(dur_row)

	var send_btn = Button.new()
	send_btn.text = "Send Proposal"
	send_btn.pressed.connect(func():
		on_send_contract(int(give_spin.value), int(recv_spin.value), int(dur_spin.value))
	)
	vbox.add_child(send_btn)

	vbox.add_child(HSeparator.new())

	var active_title = Label.new()
	active_title.text = "Active Contracts"
	active_title.add_theme_font_size_override("font_size", 16)
	active_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(active_title)

	var found_active = false
	for i in range(Data.contracts.size()):
		var c = Data.contracts[i]
		if c["status"] != "active":
			continue
		if c["from_country"] != player_name and c["to_country"] != player_name:
			continue
		found_active = true
		vbox.add_child(make_contract_row(c, player_name))

	if not found_active:
		var lbl = Label.new()
		lbl.text = "No active contracts."
		vbox.add_child(lbl)

	vbox.add_child(HSeparator.new())

	var pending_title = Label.new()
	pending_title.text = "Pending Proposals"
	pending_title.add_theme_font_size_override("font_size", 16)
	pending_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(pending_title)

	var found_pending = false
	for i in range(Data.contracts.size()):
		var c = Data.contracts[i]
		if c["status"] != "pending":
			continue
		if c["from_country"] != player_name and c["to_country"] != player_name:
			continue
		found_pending = true
		vbox.add_child(make_contract_row(c, player_name))

	if not found_pending:
		var lbl = Label.new()
		lbl.text = "No pending proposals."
		vbox.add_child(lbl)

func make_contract_row(c: Dictionary, player_name: String) -> HBoxContainer:
	var row = HBoxContainer.new()

	var info = Label.new()
	info.text = c["from_country"] + " gives " + str(c["from_quantity"]) + " " + c["from_resource"] + \
		" ↔ " + c["to_country"] + " gives " + str(c["to_quantity"]) + " " + c["to_resource"] + \
		" | " + str(c["turns_remaining"]) + "/" + str(c["duration_turns"]) + " turns"
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_font_size_override("font_size", 11)
	row.add_child(info)

	var contract_id = c["contract_id"]

	if c["status"] == "pending" and c["to_country"] == player_name:
		var accept_btn = Button.new()
		accept_btn.text = "Accept"
		accept_btn.pressed.connect(func(): on_accept_contract(contract_id))
		row.add_child(accept_btn)

		var refuse_btn = Button.new()
		refuse_btn.text = "Refuse"
		refuse_btn.pressed.connect(func(): on_refuse_contract(contract_id))
		row.add_child(refuse_btn)

	if c["status"] == "active":
		var cancel_btn = Button.new()
		cancel_btn.text = "Cancel"
		cancel_btn.pressed.connect(func(): on_cancel_contract(contract_id))
		row.add_child(cancel_btn)

	return row

func find_contract_index(contract_id: String) -> int:
	for i in range(Data.contracts.size()):
		if Data.contracts[i]["contract_id"] == contract_id:
			return i
	return -1

func on_send_contract(from_qty: int, to_qty: int, duration: int):
	if selected_country == "":
		Data.show_popup("Select a country first!")
		return

	var new_id = str(Time.get_ticks_msec()) + "_" + Data.player_country.name
	var new_contract = {
		"contract_id": new_id,
		"from_country": Data.player_country.name,
		"to_country": selected_country,
		"from_resource": from_resource,
		"from_quantity": from_qty,
		"to_resource": to_resource,
		"to_quantity": to_qty,
		"duration_turns": duration,
		"turns_remaining": duration,
		"status": "pending",
	}

	var contracts_copy = Data.contracts.duplicate(true)
	contracts_copy.append(new_contract)

	if multiplayer.is_server():
		Data.request_sync_contracts(contracts_copy)
	else:
		Data.request_sync_contracts.rpc_id(1, contracts_copy)

	Data.show_popup("Proposal sent to " + selected_country + "!")
	display_contracts()

func on_accept_contract(contract_id: String):
	var index = find_contract_index(contract_id)
	if index == -1:
		return
	var contracts_copy = Data.contracts.duplicate(true)
	contracts_copy[index]["status"] = "active"
	if multiplayer.is_server():
		Data.request_sync_contracts(contracts_copy)
	else:
		Data.request_sync_contracts.rpc_id(1, contracts_copy)
	Data.show_popup("Contract accepted!")
	display_contracts()

func on_refuse_contract(contract_id: String):
	var index = find_contract_index(contract_id)
	if index == -1:
		return
	var contracts_copy = Data.contracts.duplicate(true)
	contracts_copy[index]["status"] = "cancelled"
	if multiplayer.is_server():
		Data.request_sync_contracts(contracts_copy)
	else:
		Data.request_sync_contracts.rpc_id(1, contracts_copy)
	Data.show_popup("Contract refused.")
	display_contracts()

func on_cancel_contract(contract_id: String):
	var index = find_contract_index(contract_id)
	if index == -1:
		return
	var contracts_copy = Data.contracts.duplicate(true)
	contracts_copy[index]["status"] = "cancelled"
	if multiplayer.is_server():
		Data.request_sync_contracts(contracts_copy)
	else:
		Data.request_sync_contracts.rpc_id(1, contracts_copy)
	Data.show_popup("Contract cancelled.")
	display_contracts()
 

func _on_contracts_close_button_down() -> void:
	var screen_size = get_viewport().get_visible_rect().size
	contract_panel.global_position = Vector2(0, (screen_size.y - contract_panel.size.y) / 2)
	contract_panel.hide()
