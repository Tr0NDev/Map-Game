extends Node
@onready var diplomacy_panel : Panel = $"../"
@onready var scroll : ScrollContainer = $"../ScrollContainer"
@onready var vbox : VBoxContainer = $"../ScrollContainer/VBoxContainer"
@onready var title_label : Label = $"../Title"

var relations = {}

func _ready():
	scroll.custom_minimum_size = Vector2(0, 300)
	load_relations()
	
	
func _process(_delta):
	if Data.player_country != null and relations.size() > 0:
		if title_label.text == "":
			display_relations()
		if Data.relations.size() > 0 and Data.relations != relations:
			relations = Data.relations
			display_relations()

func load_relations():
	var file = FileAccess.open("res://countrydata/relations.json", FileAccess.READ)
	if file == null:
		print("Erreur ouverture relations.json")
		return
	var json_text = file.get_as_text()
	file.close()
	var data = JSON.parse_string(json_text)
	if typeof(data) == TYPE_DICTIONARY:
		relations = data["relations"]
		Data.relations = relations

func display_relations():
	for child in vbox.get_children():
		child.queue_free()

	var player_name = Data.player_country.name
	if not relations.has(player_name):
		return

	title_label.text = "Diplomacy - " + player_name
	var player_relations = relations[player_name]

	for country_name in player_relations:
		var row = HBoxContainer.new()

		var name_label = Label.new()
		name_label.text = country_name
		name_label.custom_minimum_size = Vector2(120, 0)
		row.add_child(name_label)

		var relation_val = player_relations[country_name]
		var relation_label = Label.new()
		relation_label.text = str(relation_val) + "/100"
		relation_label.custom_minimum_size = Vector2(60, 0)
		relation_label.modulate = get_relation_color(relation_val)
		row.add_child(relation_label)

		if relation_val < 100:
			var improve_btn = Button.new()
			improve_btn.text = "+Rel (10M$)"
			improve_btn.add_theme_font_size_override("font_size", 10)
			improve_btn.pressed.connect(on_improve_relations.bind(country_name))
			row.add_child(improve_btn)

		var defame_btn = Button.new()
		defame_btn.text = "Defame (5M$)"
		defame_btn.add_theme_font_size_override("font_size", 10)
		defame_btn.modulate = Color(1, 0.5, 0.5)
		defame_btn.pressed.connect(on_defame.bind(country_name))
		row.add_child(defame_btn)

		var tariff_lbl = Label.new()
		tariff_lbl.text = "Tariff %:"
		tariff_lbl.add_theme_font_size_override("font_size", 10)
		row.add_child(tariff_lbl)

		var tariff_spin = SpinBox.new()
		tariff_spin.min_value = 0
		tariff_spin.max_value = 200
		tariff_spin.step = 1
		tariff_spin.suffix = "%"
		tariff_spin.custom_minimum_size = Vector2(80, 0)
		var current_tariff = 0.0
		if Data.tariffs.has(player_name) and Data.tariffs[player_name].has(country_name):
			current_tariff = Data.tariffs[player_name][country_name]
		tariff_spin.value = current_tariff
		tariff_spin.value_changed.connect(func(val):
			if multiplayer.is_server():
				Data.apply_tariff.rpc(player_name, country_name, val)
			else:
				Data.request_set_tariff.rpc_id(1, player_name, country_name, val)
		)
		row.add_child(tariff_spin)

		vbox.add_child(row)

func on_improve_relations(country_name: String):
	if Data.player_country == null:
		return
	var money = float(Data.player_country.economy.money)
	if money < 10000000:
		Data.show_popup("Not enough money!\nNeed 10M$")
		return
	var player_name = Data.player_country.name
	var current_val = relations[player_name][country_name]
	if current_val >= 100:
		Data.show_popup("Relations already maxed!")
		return
	var gain = max(1, int(10 * (1.0 - current_val / 100.0)))
	var new_val = min(100, current_val + gain)
	var new_money = money - 10000000
	if multiplayer.is_server():
		Data.apply_economy_field.rpc(player_name, "money", new_money)
		Data.modify_relation(player_name, country_name, gain)
	else:
		Data.request_set_economy_field.rpc_id(1, player_name, "money", new_money)
		Data.request_modify_relation.rpc_id(1, player_name, country_name, gain)
	Data.show_popup("Relations with " + country_name + " improved!\n+" + str(gain) + " → " + str(new_val) + "/100\n-10M$")
	display_relations()

func on_defame(target_country: String):
	if Data.player_country == null:
		return
	var money = float(Data.player_country.economy.money)
	if money < 5000000:
		Data.show_popup("Not enough money!\nNeed 5M$")
		return

	var player_name = Data.player_country.name
	var new_money = money - 5000000
	if multiplayer.is_server():
		Data.apply_economy_field.rpc(player_name, "money", new_money)
	else:
		Data.request_set_economy_field.rpc_id(1, player_name, "money", new_money)

	if randf() < 0.25:
		var loss = randi_range(3, 8)
		if multiplayer.is_server():
			for other in relations:
				if other != player_name and relations[other].has(player_name):
					Data.modify_relation(other, player_name, -loss)
		else:
			Data.request_defame.rpc_id(1, player_name, target_country, true)
		Data.show_popup("Defamation failed!\nYour reputation suffered with everyone.\n-" + str(loss) + " relations")
	else:
		var loss = randi_range(3, 10)
		if multiplayer.is_server():
			for other in relations:
				if other != target_country and relations[other].has(target_country):
					Data.modify_relation(other, target_country, -loss)
		else:
			Data.request_defame.rpc_id(1, player_name, target_country, false)
		Data.show_popup("Defamation succeeded!\n" + target_country + " lost reputation everywhere.\n-" + str(loss) + " relations")

	display_relations()

func get_relation_color(val: int) -> Color:
	if val >= 80:
		return Color.GREEN
	elif val >= 60:
		return Color.YELLOW
	elif val >= 40:
		return Color.ORANGE
	else:
		return Color.RED

func _on_diplomacy_close_button_down() -> void:
	var screen_size = get_viewport().get_visible_rect().size
	diplomacy_panel.global_position = Vector2(0, (screen_size.y - diplomacy_panel.size.y) / 2)
	diplomacy_panel.hide()
