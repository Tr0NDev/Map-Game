extends Node

var country_list = {}
var terrain_data = {}
var player_country

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

	func _init(data: Dictionary):
		soldier = data.get("soldier", 0)
		tank = data.get("tank", 0)
		armored_vehicle = data.get("armored_vehicle", 0)
		aircraft = data.get("aircraft", 0)
		destroyer = data.get("destroyer", 0)
		submarine = data.get("submarine", 0)
		aircraft_carrier = data.get("aicraft_carrier", 0)
		cyber_power = data.get("cyber_power", 0)


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
	var factory
	var railways
	var ports
	var airports

	func _init(data: Dictionary):
		factory = data.get("factory")
		railways = data.get("railways")
		ports = data.get("ports")
		airports = data.get("airports")


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


var player_countries : Dictionary = {}
var my_country : Country

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
	print("player_countries sync : ", player_countries)

@rpc("authority", "reliable")
func confirm_country(country_name: String):
	my_country = country_list[country_name]
	player_country = my_country
	print("Ton pays : ", country_name)
	print("player_countries : ", player_countries)

func _country_taken(country_name: String) -> bool:
	return country_name in player_countries.values()







@rpc("any_peer", "reliable")
func request_set_economy_field(country_name: String, field: String, value):
	if not multiplayer.is_server():
		return
	var sender_id = multiplayer.get_remote_sender_id()
	if sender_id == 0 or player_countries.get(sender_id) == country_name:
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
