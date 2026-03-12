extends Node

var country_list = {}
var terrain_data = {}
var player_country
var player_countries : Dictionary = {}
var my_country : Country
var market_offers = []

var tour = 0

class Population:
	var pop_number : int
	var approval : int

	func _init(data: Dictionary):
		pop_number = data.get("pop_number", 0)
		approval = data.get("approval", 0)


class Army:
	var soldier
	var tank
	var armored_vehicle
	var aircraft
	var destroyer
	var submarine
	var aircraft_carrier
	var cyber_power
	var missile

	func _init(data: Dictionary):
		soldier = data.get("soldier", 0)
		tank = data.get("tank", 0)
		armored_vehicle = data.get("armored_vehicle", 0)
		aircraft = data.get("aircraft", 0)
		destroyer = data.get("destroyer", 0)
		submarine = data.get("submarine", 0)
		aircraft_carrier = data.get("aicraft_carrier", 0)
		cyber_power = data.get("cyber_power", 0)
		missile = data.get("missile", 0)


class Resources:
	var oil
	var metal
	var coal
	var gas
	var uranium
	var food
	var energy
	var wood
	var gold
	var rare_earth
	var digital

	func _init(data: Dictionary):
		for key in data:
			self.set(key, data[key])


class Economy:
	var type
	var money
	var avg_salary
	var tax_rate
	var military_budget
	var infrastructure_budget
	var social_bugdet

	func _init(data: Dictionary):
		type = data.get("type")
		money = data.get("money")
		avg_salary = data.get("avg_salary")
		tax_rate = data.get("tax_rate")
		military_budget = data.get("military_budget")
		infrastructure_budget = data.get("infrastructure_budget")
		social_bugdet = data.get("social_bugdet")


class Infrastructure:
	var oil_refinery
	var metal_foundry
	var coal_mine
	var gas_pipeline
	var nuclear_plant
	var farm
	var power_plant
	var sawmill
	var gold_mine
	var rare_earth_mine
	var data_center

	func _init(data: Dictionary):
		oil_refinery = data.get("oil_refinery")
		metal_foundry = data.get("metal_foundry")
		coal_mine = data.get("coal_mine")
		gas_pipeline = data.get("gas_pipeline")
		nuclear_plant = data.get("nuclear_plant")
		farm = data.get("farm")
		power_plant = data.get("power_plant")
		sawmill = data.get("sawmill")
		gold_mine = data.get("gold_mine")
		rare_earth_mine = data.get("rare_earth_mine")
		data_center = data.get("data_center")


class Terrain:
	var oil
	var view_oil
	var metal
	var view_metal
	var coal
	var view_coal
	var gas
	var view_gas
	var uranium
	var view_uranium
	var food
	var view_food
	var energy
	var view_energy
	var wood
	var view_wood
	var gold
	var view_gold
	var rare_earth
	var view_rare_earth

	func _init(data: Dictionary):
		oil = data.get("oil")
		view_oil = data.get("view_oil")
		metal = data.get("metal")
		view_metal = data.get("view_metal")
		coal = data.get("coal")
		view_coal = data.get("view_coal")
		gas = data.get("gas")
		view_gas = data.get("view_gas")
		uranium = data.get("uranium")
		view_uranium = data.get("view_uranium")
		food = data.get("food")
		view_food = data.get("view_food")
		energy = data.get("energy")
		view_energy = data.get("view_energy")
		wood = data.get("wood")
		view_wood = data.get("view_wood")
		gold = data.get("gold")
		view_gold = data.get("view_gold")
		rare_earth = data.get("rare_earth")
		view_rare_earth = data.get("view_rare_earth")


class Country:
	var name
	var population : Population
	var army : Army
	var resources : Resources
	var economy : Economy
	var infrastructure : Infrastructure
	var terrain : Terrain

	func _init(country_name: String, data: Dictionary):
		name = country_name
		population = Population.new(data["population"])
		army = Army.new(data["army"])
		resources = Resources.new(data["resources"])
		economy = Economy.new(data["economy"])
		infrastructure = Infrastructure.new(data["infrastructure"])
		terrain = Terrain.new(data["terrain"])


func _ready():
	load_countries()
	load_contracts()


func load_countries():
	var file = FileAccess.open("res://countrydata/data.json", FileAccess.READ)
	var json_text = file.get_as_text()
	file.close()

	var data = JSON.parse_string(json_text)

	if typeof(data) != TYPE_DICTIONARY:
		print("Erreur JSON")
		return

	for country_name in data.keys():
		var country = Country.new(country_name, data[country_name])
		country_list[country_name] = country


var available_countries = [
	"France",
	"United Kingdom",
	"Germany",
	"Italy",
	"Spain",
	"Portugal",
	"Norway",
	"Sweden",
	"Switzerland",
	"Belgium",
	"Netherlands",
	"Austria",
    "Denmark"
]


#--------------

func show_popup(message: String):
	var canvas = CanvasLayer.new()
	get_tree().root.add_child(canvas)
	
	var label = Label.new()
	label.text = message
	label.add_theme_font_size_override("font_size", 18)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color("#230107d9")
	panel.add_theme_stylebox_override("panel", style)
	panel.add_child(label)
	canvas.add_child(panel)
	
	await get_tree().process_frame
	var screen_size = get_viewport().get_visible_rect().size
	panel.position = Vector2((screen_size.x - panel.size.x) / 2, 20)
	
	await get_tree().create_timer(2.0).timeout
	canvas.queue_free()

@rpc("authority", "call_local", "reliable")
func show_popup_all(message: String):
	show_popup(message)

@rpc("authority", "reliable")
func notify_player(message: String):
	show_popup(message)
	
@rpc("any_peer", "reliable")
func request_notify_player(country_name: String, message: String):
	var pid = get_pid(country_name)
	if pid == -1:
		return
	if pid == 1:
		show_popup(message)
	else:
		notify_player.rpc_id(pid, message)

func get_pid(country_name: String) -> int:
	for id in player_countries:
		if player_countries[id] == country_name:
			return id
	return -1


@rpc("authority", "call_local", "reliable")
func show_popup_all_persistent(message: String):
	show_popup_two_columns("Production", "Consumption", message, "")

func show_popup_two_columns(title_left: String, title_right: String, left: String, right: String):
	var canvas = CanvasLayer.new()
	get_tree().root.add_child(canvas)
	
	var panel = Panel.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color("#230107d9")
	panel.add_theme_stylebox_override("panel", style)
	panel.custom_minimum_size = Vector2(700, 450)
	canvas.add_child(panel)
	
	var main_vbox = VBoxContainer.new()
	main_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 15)
	panel.add_child(main_vbox)
	
	var title_label = Label.new()
	title_label.text = "Recap turn " + str(tour - 1) + ":"
	title_label.add_theme_font_size_override("font_size", 28)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(title_label)
	
	var sep = HSeparator.new()
	main_vbox.add_child(sep)
	
	var hbox = HBoxContainer.new()
	hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(hbox)
	
	#gauche
	var left_vbox = VBoxContainer.new()
	left_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(left_vbox)
	
	var left_title = Label.new()
	left_title.text = title_left
	left_title.add_theme_font_size_override("font_size", 20)
	left_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	left_vbox.add_child(left_title)
	
	var left_label = Label.new()
	left_label.text = left
	left_label.add_theme_font_size_override("font_size", 14)
	left_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	left_vbox.add_child(left_label)
	
	var vsep = VSeparator.new()
	hbox.add_child(vsep)
	
	#droite
	var right_vbox = VBoxContainer.new()
	right_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(right_vbox)
	
	var right_title = Label.new()
	right_title.text = title_right
	right_title.add_theme_font_size_override("font_size", 20)
	right_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	right_vbox.add_child(right_title)
	
	var right_label = Label.new()
	right_label.text = right
	right_label.add_theme_font_size_override("font_size", 14)
	right_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	right_vbox.add_child(right_label)

	var ok_btn = Button.new()
	ok_btn.text = "OK"
	ok_btn.custom_minimum_size = Vector2(100, 40)
	main_vbox.add_child(ok_btn)
	
	await get_tree().process_frame
	var screen_size = get_viewport().get_visible_rect().size
	panel.position = Vector2((screen_size.x - panel.size.x) / 2, (screen_size.y - panel.size.y) / 2)
	ok_btn.pressed.connect(func(): canvas.call_deferred("queue_free"))
	
	
func show_popup_single_column(title: String, content: String):
	var canvas = CanvasLayer.new()
	get_tree().root.add_child(canvas)
	
	var panel = Panel.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color("#230107d9")
	panel.add_theme_stylebox_override("panel", style)
	panel.custom_minimum_size = Vector2(400, 300)
	canvas.add_child(panel)
	
	var main_vbox = VBoxContainer.new()
	main_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 15)
	panel.add_child(main_vbox)
	
	var title_label = Label.new()
	title_label.text = title
	title_label.add_theme_font_size_override("font_size", 24)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(title_label)
	
	var sep = HSeparator.new()
	main_vbox.add_child(sep)
	
	var content_label = Label.new()
	content_label.text = content
	content_label.add_theme_font_size_override("font_size", 14)
	content_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	main_vbox.add_child(content_label)
	
	var ok_btn = Button.new()
	ok_btn.text = "OK"
	ok_btn.custom_minimum_size = Vector2(100, 40)
	main_vbox.add_child(ok_btn)
	
	await get_tree().process_frame
	var screen_size = get_viewport().get_visible_rect().size
	panel.position = Vector2((screen_size.x - panel.size.x) / 2, (screen_size.y - panel.size.y) / 2)
	ok_btn.pressed.connect(func(): canvas.call_deferred("queue_free"))

@rpc("authority", "call_local", "reliable")
func show_recap(production: String, consumption: String):
	show_popup_two_columns("Production", "Consumption", production, consumption)
#--------------

@rpc("any_peer", "reliable")
func request_country():
	if not multiplayer.is_server():
		return
	var sender_id = multiplayer.get_remote_sender_id()
	if available_countries.is_empty():
		return
	available_countries.shuffle()
	var assigned = available_countries.pop_front()
	player_countries[sender_id] = assigned
	sync_player_countries.rpc(player_countries)
	confirm_country.rpc_id(sender_id, assigned)

@rpc("authority", "call_local", "reliable")
func sync_player_countries(countries: Dictionary):
	player_countries = countries

@rpc("authority", "reliable")
func confirm_country(country_name: String):
	my_country = country_list[country_name]
	player_country = my_country


#---------------


var ready_turn = []

@rpc("any_peer", "reliable")
func toggle_ready(country_name: String):
	if not multiplayer.is_server():
		return
	var sender_id = multiplayer.get_remote_sender_id()
	if sender_id == 0 or player_countries.get(sender_id) == country_name:
		if country_name in ready_turn:
			ready_turn.erase(country_name)
		else:
			ready_turn.append(country_name)
		sync_ready_turn.rpc(ready_turn)

@rpc("authority", "call_local", "reliable")
func sync_ready_turn(list: Array):
	ready_turn = list

func clear_ready_turn():
	tour += 1
	ready_turn.clear()
	sync_ready_turn.rpc(ready_turn)
	sync_ready_turn(ready_turn)
	sync_tour.rpc(tour)

@rpc("authority", "call_local", "reliable")
func sync_tour(new_tour: int):
	tour = new_tour

#---------------



@rpc("any_peer", "reliable")
func request_set_economy_field(country_name: String, field: String, value):
	if not multiplayer.is_server():
		return
	apply_economy_field.rpc(country_name, field, value)

@rpc("authority", "call_local", "reliable")
func apply_economy_field(country_name: String, field: String, value):
	country_list[country_name].economy.set(field, value)

@rpc("any_peer", "reliable")
func request_set_terrain_field(country_name: String, field: String, value):
	if not multiplayer.is_server():
		return
	var sender_id = multiplayer.get_remote_sender_id()
	if sender_id == 0 or player_countries.get(sender_id) == country_name:
		apply_terrain_field.rpc(country_name, field, value)

@rpc("authority", "call_local", "reliable")
func apply_terrain_field(country_name: String, field: String, value):
	country_list[country_name].terrain.set(field, value)
	

@rpc("any_peer", "reliable")
func request_set_resources_field(country_name: String, field: String, value):
	if not multiplayer.is_server():
		return
	var sender_id = multiplayer.get_remote_sender_id()
	if sender_id == 0 or player_countries.get(sender_id) == country_name:
		apply_resources_field.rpc(country_name, field, value)

@rpc("authority", "call_local", "reliable")
func apply_resources_field(country_name: String, field: String, value):
	country_list[country_name].resources.set(field, value)



@rpc("any_peer", "reliable")
func request_set_infra_field(country_name: String, field: String, value):
	if not multiplayer.is_server():
		return
	var sender_id = multiplayer.get_remote_sender_id()
	if sender_id == 0 or player_countries.get(sender_id) == country_name:
		apply_infra_field.rpc(country_name, field, value)

@rpc("authority", "call_local", "reliable")
func apply_infra_field(country_name: String, field: String, value):
	country_list[country_name].infrastructure.set(field, value)




@rpc("any_peer", "reliable")
func request_sync_market(offers: Array):
	if not multiplayer.is_server():
		return
	market_offers = offers
	sync_market.rpc(market_offers)

@rpc("authority", "call_local", "reliable")
func sync_market(offers: Array):
	market_offers = offers
	
	
var contracts = []


func load_contracts():
	contracts.clear()
	var file = FileAccess.open("res://globaldata/contract.csv", FileAccess.READ)
	if file == null:
		return
	file.get_line()
	while not file.eof_reached():
		var line = file.get_line().strip_edges()
		if line == "":
			continue
		var parts = line.split(",")
		if parts.size() < 10:
			continue
		contracts.append({
			"contract_id": parts[0].strip_edges(),
			"from_country": parts[1].strip_edges(),
			"to_country": parts[2].strip_edges(),
			"from_resource": parts[3].strip_edges(),
			"from_quantity": int(parts[4].strip_edges()),
			"to_resource": parts[5].strip_edges(),
			"to_quantity": int(parts[6].strip_edges()),
			"duration_turns": int(parts[7].strip_edges()),
			"turns_remaining": int(parts[8].strip_edges()),
			"status": parts[9].strip_edges(),
		})
	file.close()

signal contracts_updated

@rpc("any_peer", "reliable")
func request_sync_contracts(new_contracts: Array):
	if not multiplayer.is_server():
		return
	print("player_countries au moment du sync: ", player_countries)
	for new_c in new_contracts:
		var old_c = null
		for c in contracts:
			if c["contract_id"] == new_c["contract_id"]:
				old_c = c
				break
		
		if old_c == null:
			print("nouveau contrat, status: ", new_c["status"], " to: ", new_c["to_country"])
			if new_c["status"] == "pending":
				notify_country(new_c["to_country"], "New contract proposal from " + new_c["from_country"] + "!\nCheck your contracts.")
		
		elif old_c["status"] != new_c["status"]:
			if new_c["status"] == "active":
				notify_country(new_c["from_country"], "Contract accepted by " + new_c["to_country"] + "!")
			elif new_c["status"] == "cancelled" or new_c["status"] == "expired":
				notify_country(new_c["from_country"], "Contract with " + new_c["to_country"] + " was cancelled.")
				notify_country(new_c["to_country"], "Contract with " + new_c["from_country"] + " was cancelled.")
	
	contracts = new_contracts
	sync_contracts.rpc(contracts)

func notify_country(country_name: String, message: String):
	print("notify_country: ", country_name, " | player_countries: ", player_countries)
	var pid = get_pid(country_name)
	print("pid found: ", pid)
	if pid == -1:
		return
	if pid == 1:
		show_popup(message)
	else:
		notify_player.rpc_id(pid, message)

@rpc("authority", "call_local", "reliable")
func sync_contracts(c: Array):
	contracts = c
	contracts_updated.emit()


var relations = {}

func load_relations():
	var file = FileAccess.open("res://countrydata/relations.json", FileAccess.READ)
	if file == null:
		return
	var json_text = file.get_as_text()
	file.close()
	var data = JSON.parse_string(json_text)
	if typeof(data) == TYPE_DICTIONARY:
		relations = data["relations"]

@rpc("authority", "call_local", "reliable")
func sync_relations(r: Dictionary):
	relations = r

func modify_relation(country_a: String, country_b: String, delta: int):
	if not relations.has(country_a) or not relations.has(country_b):
		return
	if relations[country_a].has(country_b):
		relations[country_a][country_b] = clamp(relations[country_a][country_b] + delta, 0, 100)
	if relations[country_b].has(country_a):
		relations[country_b][country_a] = clamp(relations[country_b][country_a] + delta, 0, 100)
	sync_relations.rpc(relations)

func modify_relation_no_sync(country_a: String, country_b: String, delta: int):
	if not relations.has(country_a) or not relations.has(country_b):
		return
	if relations[country_a].has(country_b):
		relations[country_a][country_b] = clamp(relations[country_a][country_b] + delta, 0, 100)
	if relations[country_b].has(country_a):
		relations[country_b][country_a] = clamp(relations[country_b][country_a] + delta, 0, 100)



@rpc("any_peer", "reliable")
func request_set_army_field(country_name: String, field: String, value):
	if not multiplayer.is_server():
		return
	var sender_id = multiplayer.get_remote_sender_id()
	if sender_id == 0 or player_countries.get(sender_id) == country_name:
		apply_army_field.rpc(country_name, field, value)

@rpc("authority", "call_local", "reliable")
func apply_army_field(country_name: String, field: String, value):
	country_list[country_name].army.set(field, value)


@rpc("any_peer", "reliable")
func request_defame(sender: String, target: String, failed: bool):
	if not multiplayer.is_server():
		return
	var loss = randi_range(3, 10)
	if failed:
		for other in relations:
			if other != sender and relations[other].has(sender):
				modify_relation(other, sender, -loss)
	else:
		for other in relations:
			if other != target and relations[other].has(target):
				modify_relation(other, target, -loss)



var tariffs = {}

@rpc("any_peer", "reliable")
func request_set_tariff(from_country: String, target_country: String, value: float):
	if not multiplayer.is_server():
		return
	var sender_id = multiplayer.get_remote_sender_id()
	if sender_id == 0 or player_countries.get(sender_id) == from_country:
		apply_tariff.rpc(from_country, target_country, value)

@rpc("authority", "call_local", "reliable")
func apply_tariff(from_country: String, target_country: String, value: float):
	if not tariffs.has(from_country):
		tariffs[from_country] = {}
	tariffs[from_country][target_country] = value

func get_tariff(seller_country: String, buyer_country: String) -> float:
	if tariffs.has(buyer_country) and tariffs[buyer_country].has(seller_country):
		return tariffs[buyer_country][seller_country]
	return 0.0





var wars: Array = []
signal wars_updated

func declare_war(attacker: String, defender: String, troops: Dictionary):
	for w in wars:
		if (w["attacker"] == attacker and w["defender"] == defender) or \
		   (w["attacker"] == defender and w["defender"] == attacker):
			show_popup("War already ongoing!")
			return
	wars.append({
		"attacker": attacker,
		"defender": defender,
		"status": "active",
		"start_turn": tour,
		"attacker_troops": troops,
		"defender_troops": {},
		"attacker_losses": {},
		"defender_losses": {},
	})
	sync_wars.rpc(wars)
	wars_updated.emit()
	request_notify_player(defender, attacker + " declared war on you!")

	if not relations.has(attacker) or not relations.has(defender):
		return

	for other in relations:
		if other == attacker or other == defender:
			continue
		if not relations[other].has(attacker) or not relations[other].has(defender):
			continue

		var opinion_of_defender = relations[other].get(defender, 50)
		var opinion_of_attacker = relations[other].get(attacker, 50)

		if opinion_of_defender >= 60:
			relations[other][attacker] = clamp(relations[other][attacker] - randi_range(3, 8), 0, 100)
			relations[attacker][other] = clamp(relations[attacker][other] - randi_range(3, 8), 0, 100)
			relations[other][defender] = clamp(relations[other][defender] + randi_range(1, 4), 0, 100)
			relations[defender][other] = clamp(relations[defender][other] + randi_range(1, 4), 0, 100)

		elif opinion_of_defender <= 35:
			relations[other][attacker] = clamp(relations[other][attacker] + randi_range(3, 8), 0, 100)
			relations[attacker][other] = clamp(relations[attacker][other] + randi_range(3, 8), 0, 100)
			relations[other][defender] = clamp(relations[other][defender] - randi_range(1, 4), 0, 100)
			relations[defender][other] = clamp(relations[defender][other] - randi_range(1, 4), 0, 100)

		if opinion_of_attacker <= 35:
			relations[other][defender] = clamp(relations[other][defender] + randi_range(2, 6), 0, 100)
			relations[defender][other] = clamp(relations[defender][other] + randi_range(2, 6), 0, 100)
			relations[other][attacker] = clamp(relations[other][attacker] - randi_range(1, 3), 0, 100)
			relations[attacker][other] = clamp(relations[attacker][other] - randi_range(1, 3), 0, 100)

	sync_relations.rpc(relations)

@rpc("any_peer", "reliable")
func request_declare_war(attacker: String, defender: String, troops: Dictionary):
	if not multiplayer.is_server():
		return
	var sender_id = multiplayer.get_remote_sender_id()
	if sender_id != 0 and player_countries.get(sender_id) != attacker:
		return
	declare_war(attacker, defender, troops)

@rpc("authority", "call_local", "reliable")
func sync_wars(w: Array):
	wars = w
	wars_updated.emit()


var peace_proposals: Array = []
signal peace_updated

@rpc("any_peer", "reliable")
func request_propose_peace_terms(from: String, to: String, peace_type: String, terms: Dictionary):
	if not multiplayer.is_server():
		return
	for p in peace_proposals:
		if (p["from"] == from and p["to"] == to) or (p["from"] == to and p["to"] == from):
			return
	peace_proposals.append({
		"from": from, "to": to,
		"status": "pending",
		"peace_type": peace_type,
		"terms": terms,
	})
	sync_peace.rpc(peace_proposals)
	peace_updated.emit()
	var pid = get_pid(to)
	var type_str = {"classic": "🤝 Classic Peace", "invasion": "⚔ Annexation", "contract": "📜 Forced Contract"}.get(peace_type, "Peace")
	var msg = from + " proposes: " + type_str + "\nCheck your war panel!"
	if pid == 1: show_popup(msg)
	elif pid != -1: notify_player.rpc_id(pid, msg)

@rpc("any_peer", "reliable")
func request_accept_peace(from_country: String, to_country: String):
	if not multiplayer.is_server():
		return
	var proposal = null
	for p in peace_proposals:
		if p["from"] == from_country and p["to"] == to_country and p["status"] == "pending":
			proposal = p
			break
	if proposal == null:
		return

	var peace_type = proposal.get("peace_type", "classic")
	var terms = proposal.get("terms", {})

	match peace_type:
		"classic":
			end_war(from_country, to_country)
			modify_relation(from_country, to_country, 10)
			modify_relation(to_country, from_country, 10)

		"surrender":
			var unit_strength = {"soldier": 1, "tank": 50, "armored_vehicle": 20,
				"aircraft": 80, "destroyer": 100, "submarine": 120, "aircraft_carrier": 200}
			var loser_deployed = 0.0
			for w in wars:
				if (w["attacker"] == to_country or w["defender"] == to_country) and w["status"] == "active":
					var key = "attacker_troops" if w["attacker"] == to_country else "defender_troops"
					for unit in w.get(key, {}):
						loser_deployed += w[key][unit] * unit_strength.get(unit, 1)
			var winner_deployed = 0.0
			for w in wars:
				if (w["attacker"] == from_country or w["defender"] == from_country) and w["status"] == "active":
					var key = "attacker_troops" if w["attacker"] == from_country else "defender_troops"
					for unit in w.get(key, {}):
						winner_deployed += w[key][unit] * unit_strength.get(unit, 1)
			if loser_deployed > winner_deployed * 0.6:
				peace_proposals = peace_proposals.filter(func(p): return not (p["from"] == from_country and p["to"] == to_country))
				sync_peace.rpc(peace_proposals)
				peace_updated.emit()
				request_notify_player(from_country, to_country + " refused your surrender demand — they are still strong!")
				request_notify_player(to_country, from_country + " tried to force your surrender, but you are strong enough to resist!")
				return
			apply_surrender(to_country, from_country)
			
		"invasion":
			var pct = terms.get("percent", 20) / 100.0
			var victim = country_list.get(to_country)
			var winner = country_list.get(from_country)
			if victim and winner:
				var res_list = ["oil", "metal", "coal", "food", "energy", "gold"]
				for res in res_list:
					var stock = victim.resources.get(res)
					if stock == null: stock = 0
					var take = int(stock * pct)
					if take <= 0: continue
					apply_resources_field.rpc(to_country, res, stock - take)
					var w_stock = winner.resources.get(res)
					if w_stock == null: w_stock = 0
					apply_resources_field.rpc(from_country, res, w_stock + take)
			end_war(from_country, to_country)
			modify_relation(to_country, from_country, -20)

		"contract":
			var contract_id = str(Time.get_ticks_msec())
			contracts.append({
				"contract_id": contract_id,
				"from_country": from_country,
				"to_country": to_country,
				"from_resource": terms.get("from_resource", "money"),
				"from_quantity": terms.get("from_quantity", 0),
				"to_resource": terms.get("to_resource", "oil"),
				"to_quantity": terms.get("to_quantity", 100),
				"duration_turns": terms.get("duration_turns", 5),
				"turns_remaining": terms.get("duration_turns", 5),
				"status": "active",
				"forced": true,
			})
			sync_contracts.rpc(contracts)
			contracts_updated.emit()
			end_war(from_country, to_country)
			modify_relation(to_country, from_country, -10)

	peace_proposals = peace_proposals.filter(func(p): return not (p["from"] == from_country and p["to"] == to_country))
	sync_peace.rpc(peace_proposals)
	peace_updated.emit()

	var pid_from = get_pid(from_country)
	var pid_to = get_pid(to_country)
	var msg_from = to_country + " accepted your peace proposal!"
	var msg_to = "You accepted peace with " + from_country + "."
	if pid_from == 1: show_popup(msg_from)
	elif pid_from != -1: notify_player.rpc_id(pid_from, msg_from)
	if pid_to == 1: show_popup(msg_to)
	elif pid_to != -1: notify_player.rpc_id(pid_to, msg_to)

func end_war(country_a: String, country_b: String):
	for i in range(wars.size() - 1, -1, -1):
		if (wars[i]["attacker"] == country_a and wars[i]["defender"] == country_b) or \
		   (wars[i]["attacker"] == country_b and wars[i]["defender"] == country_a):
			wars.remove_at(i)
	sync_wars.rpc(wars)
	wars_updated.emit()

@rpc("any_peer", "reliable")
func request_refuse_peace(from_country: String, to_country: String):
	if not multiplayer.is_server():
		return
	for i in range(peace_proposals.size() - 1, -1, -1):
		var p = peace_proposals[i]
		if p["from"] == from_country and p["to"] == to_country:
			peace_proposals.remove_at(i)
	sync_peace.rpc(peace_proposals)
	request_notify_player(from_country, to_country + " refused your peace proposal.")

@rpc("authority", "call_local", "reliable")
func sync_peace(p: Array):
	peace_proposals = p
	peace_updated.emit()


@rpc("any_peer", "reliable")
func add_war_troops(country_name: String, attacker: String, defender: String, troops: Dictionary):
	if not multiplayer.is_server():
		return
	var sender_id = multiplayer.get_remote_sender_id()
	if sender_id != 0 and player_countries.get(sender_id) != country_name:
		return
	for i in range(wars.size()):
		var w = wars[i]
		if w["attacker"] != attacker or w["defender"] != defender:
			continue
		var key = "attacker_troops" if country_name == attacker else "defender_troops"
		for unit in troops:
			if wars[i][key].has(unit):
				wars[i][key][unit] += troops[unit]
			else:
				wars[i][key][unit] = troops[unit]
		break
	sync_wars.rpc(wars)

@rpc("any_peer", "reliable")
func request_strike(attacker: String, defender: String, missile_type: String, qty: int, target_type: String):
	if not multiplayer.is_server():
		return
	var sender_id = multiplayer.get_remote_sender_id()
	if sender_id != 0 and player_countries.get(sender_id) != attacker:
		return
	apply_strike(attacker, defender, missile_type, qty, target_type)

func apply_strike(attacker: String, defender: String, missile_type: String, qty: int, target_type: String):
	if not country_list.has(defender):
		return
	var country = country_list[defender]

	var att_country = country_list[attacker]
	var current_missiles = att_country.army.get(missile_type)
	if current_missiles == null: current_missiles = 0
	apply_army_field.rpc(attacker, missile_type, max(0, current_missiles - qty))

	var damage_multiplier = 5
	var base_damage = qty * damage_multiplier
	var damage_report = ""

	match target_type:
		"soldier":
			var dmg = base_damage * 100
			var current = country.army.get("soldier")
			if current == null: current = 0
			var actual = min(dmg, current)
			apply_army_field.rpc(defender, "soldier", max(0, current - dmg))
			damage_report = "💀 Soldiers destroyed: " + str(int(actual))
		"tank":
			var dmg = base_damage
			var current = country.army.get("tank")
			if current == null: current = 0
			var actual = min(dmg, current)
			apply_army_field.rpc(defender, "tank", max(0, current - dmg))
			damage_report = "🛡 Tanks destroyed: " + str(int(actual))
		"aircraft":
			var dmg = base_damage / 2
			var current = country.army.get("aircraft")
			if current == null: current = 0
			var actual = min(dmg, current)
			apply_army_field.rpc(defender, "aircraft", max(0, current - dmg))
			damage_report = "✈ Aircraft destroyed: " + str(int(actual))
		"infrastructure":
			var infra_keys = ["oil_refinery", "metal_foundry", "coal_mine", "power_plant", "farm", "data_center"]
			var destroyed = {}
			for _i in range(qty):
				var target_infra = infra_keys[randi() % infra_keys.size()]
				var current = country.infrastructure.get(target_infra)
				if current == null: current = 0
				if current > 0:
					apply_infra_field.rpc(defender, target_infra, current - 1)
					if not destroyed.has(target_infra): destroyed[target_infra] = 0
					destroyed[target_infra] += 1
			for k in destroyed:
				damage_report += "🏭 " + k + " destroyed: " + str(destroyed[k]) + "\n"
			if damage_report == "": damage_report = "🏭 No infrastructure hit"
		"resources":
			var res_keys = ["oil", "metal", "coal", "food", "energy"]
			for res in res_keys:
				var dmg = base_damage * 10
				var current = country.resources.get(res)
				if current == null: current = 0
				var actual = min(dmg, current)
				apply_resources_field.rpc(defender, res, max(0, current - dmg))
				damage_report += "📦 " + res + " lost: " + str(int(actual)) + "\n"
		"population":
			var dmg = base_damage * 1000
			var current_pop = country.population.pop_number
			var actual = min(dmg, current_pop)
			apply_population_field.rpc(defender, "pop_number", max(0, current_pop - dmg))
			damage_report = "🏘 Population killed: " + str(int(actual))

	modify_relation(defender, attacker, -5)

	var att_pid = get_pid(attacker)
	var att_msg = "🚀 Strike on " + defender + "\nTarget: " + target_type + "\n" + damage_report
	if att_pid == 1:
		show_popup(att_msg)
	elif att_pid != -1:
		notify_player.rpc_id(att_pid, att_msg)

	var def_pid = get_pid(defender)
	var def_msg = "💥 " + attacker + " struck your " + target_type + "!\n" + damage_report
	if def_pid == 1:
		show_popup(def_msg)
	elif def_pid != -1:
		notify_player.rpc_id(def_pid, def_msg)

	sync_wars.rpc(wars)
	
@rpc("any_peer", "reliable")
func request_set_population_field(country_name: String, field: String, value):
	if not multiplayer.is_server():
		return
	var sender_id = multiplayer.get_remote_sender_id()
	if sender_id == 0 or player_countries.get(sender_id) == country_name:
		apply_population_field.rpc(country_name, field, value)

@rpc("authority", "call_local", "reliable")
func apply_population_field(country_name: String, field: String, value):
	country_list[country_name].population.set(field, value)
	
	
signal country_surrendered(loser, winner)

var annexed_countries: Dictionary = {}

func apply_surrender(loser: String, winner: String):
	if not country_list.has(loser) or not country_list.has(winner):
		return
	var loser_country = country_list[loser]
	var winner_country = country_list[winner]

	var res_fields = ["oil", "metal", "coal", "food", "energy", "wood", "gold", "rare_earth", "digital", "gas", "uranium"]
	for res in res_fields:
		var loser_stock = loser_country.resources.get(res)
		if loser_stock == null: loser_stock = 0
		var winner_stock = winner_country.resources.get(res)
		if winner_stock == null: winner_stock = 0
		apply_resources_field.rpc(winner, res, winner_stock + loser_stock)
		apply_resources_field.rpc(loser, res, 0)

	var loser_money = float(loser_country.economy.money)
	var winner_money = float(winner_country.economy.money)
	apply_economy_field.rpc(winner, "money", winner_money + loser_money)
	apply_economy_field.rpc(loser, "money", 0)

	var infra_fields = ["farm", "sawmill", "coal_mine", "power_plant", "metal_foundry",
		"gas_pipeline", "oil_refinery", "data_center", "gold_mine", "rare_earth_mine", "nuclear_plant"]
	for infra in infra_fields:
		var loser_infra = loser_country.infrastructure.get(infra)
		if loser_infra == null: loser_infra = 0
		var winner_infra = winner_country.infrastructure.get(infra)
		if winner_infra == null: winner_infra = 0
		apply_infra_field.rpc(winner, infra, winner_infra + loser_infra)
		apply_infra_field.rpc(loser, infra, 0)

	var army_fields = ["soldier", "tank", "armored_vehicle", "aircraft", "destroyer",
		"submarine", "aircraft_carrier", "cyber_power", "missile"]
	for unit in army_fields:
		var loser_units = loser_country.army.get(unit)
		if loser_units == null: loser_units = 0
		var winner_units = winner_country.army.get(unit)
		if winner_units == null: winner_units = 0
		apply_army_field.rpc(winner, unit, winner_units + loser_units)
		apply_army_field.rpc(loser, unit, 0)

	var loser_pop = loser_country.population.pop_number
	var winner_pop = winner_country.population.pop_number
	apply_population_field.rpc(winner, "pop_number", winner_pop + loser_pop)
	apply_population_field.rpc(loser, "pop_number", 0)

	var terrain_fields = ["oil", "metal", "coal", "gas", "uranium", "food", "energy", "wood", "gold", "rare_earth"]
	for t in terrain_fields:
		var loser_val = loser_country.terrain.get(t)
		if loser_val == null: loser_val = 0
		var winner_val = winner_country.terrain.get(t)
		if winner_val == null: winner_val = 0
		apply_terrain_field.rpc(winner, t, winner_val + loser_val)
		apply_terrain_field.rpc(loser, t, 0)

	annexed_countries[loser] = winner
	sync_annexed_dict.rpc(annexed_countries)

	for other in relations:
		if other == winner or other == loser:
			continue
		modify_relation_no_sync(other, winner, randi_range(2, 8))
	sync_relations.rpc(relations)

	end_war(loser, winner)

	if loser in available_countries:
		available_countries.erase(loser)

	sync_annexed.rpc(loser, winner)

	var pid_loser = get_pid(loser)
	var pid_winner = get_pid(winner)
	if pid_winner == 1:
		show_popup("🏆 " + loser + " surrendered!\nYou gained their entire country!")
	elif pid_winner != -1:
		notify_player.rpc_id(pid_winner, "🏆 " + loser + " surrendered!\nYou gained their entire country!")

	if pid_loser != -1:
		player_countries.erase(pid_loser)
		sync_player_countries.rpc(player_countries)
		if pid_loser == 1:
			sync_player_eliminated.rpc_id(1)
		else:
			sync_player_eliminated.rpc_id(pid_loser)

	country_surrendered.emit(loser, winner)
	sync_wars.rpc(wars)
	wars_updated.emit()
	
@rpc("authority", "call_local", "reliable")
func sync_annexed_dict(d: Dictionary):
	annexed_countries = d

@rpc("authority", "reliable")
func sync_player_eliminated():
	player_country = null
	my_country = null
	eliminated.emit()
	var canvas = CanvasLayer.new()
	get_tree().root.add_child(canvas)
	var panel = Panel.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color("#000000ee")
	panel.add_theme_stylebox_override("panel", style)
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(panel)
	var lbl = Label.new()
	lbl.text = "💀 YOU HAVE BEEN ELIMINATED\nYour country has been annexed."
	lbl.add_theme_font_size_override("font_size", 32)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lbl.modulate = Color.RED
	panel.add_child(lbl)

signal eliminated

@rpc("authority", "call_local", "reliable")
func sync_annexed(loser: String, winner: String):
	if country_list.has(loser):
		country_list[loser].name = loser + " (annexed by " + winner + ")"
	if loser in available_countries:
		available_countries.erase(loser)
	if player_country != null and player_country.name == winner:
		pass
	country_surrendered.emit(loser, winner)
