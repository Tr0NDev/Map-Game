extends Node

var infra_production = {
	"oil_refinery": {"resource": "oil", "amount": 50},
	"metal_foundry": {"resource": "metal", "amount": 120},
	"coal_mine": {"resource": "coal", "amount": 80},
	"gas_pipeline": {"resource": "gas", "amount": 40},
	"nuclear_plant": {"resource": "uranium", "amount": 10},
	"farm": {"resource": "food", "amount": 500},
	"power_plant": {"resource": "energy", "amount": 300},
	"sawmill": {"resource": "wood", "amount": 150},
	"gold_mine": {"resource": "gold", "amount": 5},
	"rare_earth_mine": {"resource": "rare_earth", "amount": 8},
	"data_center": {"resource": "digital", "amount": 200},
}

var consumption_rates = {
	"food": {"per_pop": 1.0 / 7000.0},
	"energy": {"per_pop": 1.0 / 100000.0},
	"gas": {"per_pop": 1.0 / 100000.0},
	"oil": {"per_pop": 1.0 / 10000000.0},
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

func calcul_income(country):
	var eco = country.economy
	var pop = country.population.pop_number
	var money = float(eco.money)

	var tax_income = pop * float(eco.avg_salary) * (float(eco.tax_rate) / 100.0) / 12.0

	var res = country.resources
	var trade_bonus = 0.0
	var export_values = {
		"oil": 500, "gas": 200, "gold": 1000, "digital": 300,
		"rare_earth": 800, "uranium": 400, "metal": 100, "coal": 50
	}
	for r in export_values:
		var stock = res.get(r)
		if stock == null: stock = 0
		if stock > 5000:
			trade_bonus += (stock - 5000) * export_values[r] * 0.0001

	var military_cost = money * (float(eco.military_budget) / 1000.0) * 0.1
	var infra_cost    = money * (float(eco.infrastructure_budget) / 1000.0) * 0.05

	var gross = tax_income + trade_bonus - military_cost - infra_cost

	var tax_rate = float(eco.tax_rate) / 100.0
	var net = gross * (1.0 - tax_rate * 0.3)

	net = net / 2000.0
	var new_money = max(0, money + net)
	Data.apply_economy_field.rpc(country.name, "money", new_money)


func calcul_population(country):
	var pop = country.population.pop_number
	if pop <= 0:
		return

	var res = country.resources
	var food = res.get("food"); if food == null: food = 0
	var energy = res.get("energy"); if energy == null: energy = 0

	var growth_rate = 0.001

	if food > 2000: growth_rate += 0.0005
	if energy > 1000: growth_rate += 0.0003

	if food <= 0: growth_rate = -0.002
	elif food < 500: growth_rate -= 0.001

	var approval = country.population.approval
	if approval > 70: growth_rate += 0.0002
	elif approval < 30: growth_rate -= 0.0003

	var growth = int(pop * growth_rate)
	if growth == 0 and growth_rate > 0:
		growth = 1

	var new_pop = max(0, pop + growth)
	Data.apply_population_field.rpc(country.name, "pop_number", new_pop)
	
	
func calcul_consumption(country) -> String:
	var pop = country.population.pop_number
	var army = country.army
	var recap = "Consumption:\n"

	var pop_consumption = {
		"food": int(pop * consumption_rates["food"]["per_pop"]),
		"energy": int(pop * consumption_rates["energy"]["per_pop"]),
		"gas": int(pop * consumption_rates["gas"]["per_pop"]),
		"oil": int(pop * consumption_rates["oil"]["per_pop"]),
	}

	for resource in pop_consumption:
		var amount = pop_consumption[resource]
		if amount <= 0:
			continue
		var current = country.resources.get(resource)
		if current == null:
			current = 0
		var new_value = max(0, current - amount)
		Data.apply_resources_field.rpc(country.name, resource, new_value)
		recap += "  -" + format_number(float(amount)) + " " + resource + " (population)\n"

	var army_fields = ["soldier", "tank", "armored_vehicle", "aircraft", "destroyer", "submarine", "aircraft_carrier", "cyber_power"]
	var military_totals = {}

	for unit in army_fields:
		var count = army.get(unit)
		if count == null or count == 0:
			continue
		if not military_consumption.has(unit):
			continue
		for resource in military_consumption[unit]:
			var amount = int(count * military_consumption[unit][resource])
			if not military_totals.has(resource):
				military_totals[resource] = 0
			military_totals[resource] += amount

	for resource in military_totals:
		var amount = military_totals[resource]
		if amount <= 0:
			continue
		var current = country.resources.get(resource)
		if current == null:
			current = 0
		var new_value = max(0, current - amount)
		Data.apply_resources_field.rpc(country.name, resource, new_value)
		recap += "  -" + format_number(float(amount)) + " " + resource + " (military)\n"

	return recap

func calcul_resources(country) -> String:
	var infra = country.infrastructure
	var recap = "Production:\n"

	for infra_name in infra_production:
		var count = infra.get(infra_name)
		if count == null or count == 0:
			continue
		var resource = infra_production[infra_name]["resource"]
		var amount_per_infra = infra_production[infra_name]["amount"]
		var gain = count * amount_per_infra

		var current = country.resources.get(resource)
		if current == null:
			current = 0
		var new_value = current + gain

		Data.apply_resources_field.rpc(country.name, resource, new_value)
		recap += "  +" + format_number(float(gain)) + " " + resource + "\n"

	return recap

func next_turn():
	if not multiplayer.is_server():
		return
	for country_name in Data.country_list:
		var country = Data.country_list[country_name]
		if country.population.pop_number == 0:
			continue
		calcul_resources(country)
		calcul_consumption(country)
		calcul_income(country)
		calcul_population(country)
		calcul_approval(country)
	apply_contracts()
	process_wars()
	run_bot_turn()
	
func calcul_approval(country):
	var pop = country.population
	var eco = country.economy
	var res = country.resources
	var approval = pop.approval
	var delta = 0

	delta -= 1

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
		if w["attacker"] == country.name or w["defender"] == country.name:
			delta -= 3
			break

	if delta >= 0 and approval < 50:
		delta += 1

	var new_approval = clamp(approval + delta, 0, 100)
	Data.apply_population_field.rpc(country.name, "approval", new_approval)

func get_player_id(country_name: String) -> int:
	for id in Data.player_countries:
		if Data.player_countries[id] == country_name:
			return id
	return 1

func get_consumption_recap(country_name: String) -> String:
	var country = Data.country_list[country_name]
	var pop = country.population.pop_number
	var army = country.army
	var recap = ""

	var pop_consumption = {
		"food": int(pop * consumption_rates["food"]["per_pop"]),
		"energy": int(pop * consumption_rates["energy"]["per_pop"]),
		"gas": int(pop * consumption_rates["gas"]["per_pop"]),
		"oil": int(pop * consumption_rates["oil"]["per_pop"]),
	}
	for resource in pop_consumption:
		var amount = pop_consumption[resource]
		if amount > 0:
			recap += "-" + format_number(float(amount)) + " " + resource + " (pop)\n"

	var army_fields = ["soldier", "tank", "armored_vehicle", "aircraft", "destroyer", "submarine", "aircraft_carrier", "cyber_power"]
	var military_totals = {}
	for unit in army_fields:
		var count = army.get(unit)
		if count == null or count == 0:
			continue
		if not military_consumption.has(unit):
			continue
		for resource in military_consumption[unit]:
			var amount = int(count * military_consumption[unit][resource])
			if not military_totals.has(resource):
				military_totals[resource] = 0
			military_totals[resource] += amount
	for resource in military_totals:
		recap += "-" + format_number(float(military_totals[resource])) + " " + resource + " (military)\n"

	for c in Data.contracts:
		if c["status"] != "active":
			continue
		if c["from_country"] == country_name:
			recap += "-" + format_number(float(c["from_quantity"])) + " " + c["from_resource"] + " (contract → " + c["to_country"] + ")\n"
		if c["to_country"] == country_name:
			recap += "-" + format_number(float(c["to_quantity"])) + " " + c["to_resource"] + " (contract → " + c["from_country"] + ")\n"

	return recap if recap != "" else "No consumption this turn."

func get_production_recap(country_name: String) -> String:
	var country = Data.country_list[country_name]
	var infra = country.infrastructure
	var recap = ""
	for infra_name in infra_production:
		var count = infra.get(infra_name)
		if count == null or count == 0:
			continue
		var gain = count * infra_production[infra_name]["amount"]
		recap += "+" + format_number(float(gain)) + " " + infra_production[infra_name]["resource"] + "\n"

	for c in Data.contracts:
		if c["status"] != "active":
			continue
		if c["to_country"] == country_name:
			recap += "+" + format_number(float(c["from_quantity"])) + " " + c["from_resource"] + " (contract ← " + c["from_country"] + ")\n"
		if c["from_country"] == country_name:
			recap += "+" + format_number(float(c["to_quantity"])) + " " + c["to_resource"] + " (contract ← " + c["to_country"] + ")\n"

	return recap if recap != "" else "No production this turn."

func apply_contracts():
	print("contract")
	if not multiplayer.is_server():
		return
	for i in range(Data.contracts.size()):
		var c = Data.contracts[i]
		if c["status"] != "active":
			continue

		apply_contract_resource(c["from_country"], c["from_resource"], -c["from_quantity"])
		apply_contract_resource(c["to_country"], c["from_resource"], c["from_quantity"])
		apply_contract_resource(c["to_country"], c["to_resource"], -c["to_quantity"])
		apply_contract_resource(c["from_country"], c["to_resource"], c["to_quantity"])

		print(Data.contracts[i]["turns_remaining"])
		Data.contracts[i]["turns_remaining"] -= 1
		if Data.contracts[i]["turns_remaining"] <= 0:
			Data.contracts[i]["status"] = "expired"

	Data.sync_contracts.rpc(Data.contracts)

func apply_contract_resource(country_name: String, resource: String, delta: int):
	if not Data.country_list.has(country_name):
		return
	var country = Data.country_list[country_name]
	if resource == "money":
		var current = float(country.economy.money)
		Data.apply_economy_field.rpc(country_name, "money", current + delta)
	else:
		var current = country.resources.get(resource)
		if current == null:
			current = 0
		Data.apply_resources_field.rpc(country_name, resource, current + delta)

func format_number(n: float) -> String:
	if n >= 1000000:
		var val = n / 1000000.0
		return str(snapped(val, 0.1)).replace(".0", "") + "M"
	elif n >= 1000:
		var val = n / 1000.0
		return str(snapped(val, 0.1)).replace(".0", "") + "k"
	return str(int(n))


func run_bot_turn():
	if not multiplayer.is_server():
		return
	for country_name in Data.country_list:
		if Data.player_countries.values().has(country_name):
			continue
		var country = Data.country_list[country_name]
		if country.population.pop_number <= 0:
			continue
		bot_market_sell(country)
		bot_market_buy(country)
		bot_propose_contracts(country)
		bot_accept_contracts(country)
		bot_build(country)
		bot_recruit(country)
		bot_war(country)
		bot_reinforce(country)
		bot_strike(country)     
		bot_propose_peace(country)
		bot_accept_peace(country)


func bot_evaluate_economy(country) -> String:
	var money = float(country.economy.money)
	if money > 500000000: return "rich"
	if money > 100000000: return "stable"
	return "poor"

func bot_military_strength(country) -> float:
	var unit_strength = {"soldier": 1, "tank": 50, "armored_vehicle": 20,
		"aircraft": 80, "destroyer": 100, "submarine": 120, "aircraft_carrier": 200}
	var strength = 0.0
	for unit in unit_strength:
		var count = country.army.get(unit)
		if count == null: count = 0
		strength += count * unit_strength[unit]
	return strength

func bot_market_sell(country):
	var econ = bot_evaluate_economy(country)
	var sellable = ["oil", "metal", "coal", "gas", "uranium", "food", "energy", "wood", "gold", "rare_earth", "digital"]
	var base_prices = {
		"oil": 50, "metal": 40, "coal": 20, "gas": 35,
		"uranium": 200, "food": 10, "energy": 15, "wood": 8,
		"gold": 500, "rare_earth": 300, "digital": 100
	}
	var strategic_minimums = {
		"oil": 800, "metal": 600, "food": 1000, "energy": 500,
		"coal": 400, "uranium": 200, "gold": 50, "rare_earth": 100,
		"digital": 300, "gas": 300, "wood": 400
	}
	for res in sellable:
		var stock = country.resources.get(res)
		if stock == null or stock <= 0:
			continue
		var minimum = strategic_minimums.get(res, 500)
		if econ == "poor": minimum = int(minimum * 0.5)
		elif econ == "rich": minimum = int(minimum * 1.5)
		if stock <= minimum:
			continue
		var surplus = stock - minimum
		var qty = int(surplus * randf_range(0.15, 0.35))
		if qty <= 0:
			continue
		var price_mult = randf_range(0.9, 1.3)
		if econ == "rich": price_mult += 0.1
		var price = base_prices.get(res, 20) * price_mult
		Data.apply_resources_field.rpc(country.name, res, stock - qty)
		Data.market_offers.append({
			"offer_id": str(Time.get_ticks_msec()) + "_" + country.name + "_" + res,
			"country": country.name,
			"resource": res,
			"quantity": qty,
			"price_per_unit": price,
			"country_name": country.name,
		})
	Data.sync_market.rpc(Data.market_offers)
	Data.sync_market(Data.market_offers)


func bot_market_buy(country):
	var econ = bot_evaluate_economy(country)
	if econ == "poor":
		return  
	var needs = {
		"food": 800, "energy": 600, "oil": 500,
		"metal": 400, "coal": 300
	}
	if econ == "rich":
		for k in needs: needs[k] = int(needs[k] * 1.5)
	for res in needs:
		var stock = country.resources.get(res)
		if stock == null: stock = 0
		if stock >= needs[res]:
			continue
		var money = float(country.economy.money)
		var max_spend = money * 0.1
		if max_spend < 10000:
			continue
		var best_index = -1
		var best_price = INF
		for i in range(Data.market_offers.size()):
			var offer_mak = Data.market_offers[i]
			var tariff_mak = Data.get_tariff(offer_mak["country"], country.name)
			var final_price_mak = offer_mak["price_per_unit"] * (1.0 + tariff_mak / 100.0)
			if offer_mak["resource"] != res:
				continue
			if offer_mak["country"] == country.name:
				continue
			if offer_mak["quantity"] <= 0: 
				continue
			if final_price_mak < best_price:
				best_price = final_price_mak
				best_index = i
		if best_index == -1:
			continue
		var offer = Data.market_offers[best_index]
		var tariff = Data.get_tariff(offer["country"], country.name)
		var final_price = offer["price_per_unit"] * (1.0 + tariff / 100.0)
		var base_prices = {"oil": 50, "metal": 40, "coal": 20, "food": 10, "energy": 15}
		var base = base_prices.get(res, 30)
		if final_price > base * 2.5:
			continue
		var affordable_qty = int(min(offer["quantity"], max_spend / final_price))
		if affordable_qty <= 0: continue
		var qty = int(min(affordable_qty, needs[res] - stock))
		if qty <= 0: continue
		var cost = qty * final_price
		Data.apply_resources_field.rpc(country.name, res, stock + qty)
		Data.apply_economy_field.rpc(country.name, "money", money - cost)
		var seller_name = offer["country"]
		if Data.country_list.has(seller_name):
			var seller_money = float(Data.country_list[seller_name].economy.money)
			Data.apply_economy_field.rpc(seller_name, "money", seller_money + cost)
			var pid = get_bot_player_id(seller_name)
			if pid == 1:
				Data.show_popup(country.name + " bought " + str(qty) + " " + res + " from you\n+" + fmt_bot(cost) + "$")
			elif pid != -1:
				Data.notify_player.rpc_id(pid, country.name + " bought " + str(qty) + " " + res + " from you\n+" + fmt_bot(cost) + "$")
		Data.market_offers[best_index]["quantity"] -= qty
		if Data.market_offers[best_index]["quantity"] <= 0:
			Data.market_offers.remove_at(best_index)
	Data.sync_market.rpc(Data.market_offers)
	Data.sync_market(Data.market_offers)

func bot_propose_contracts(country):
	if randf() > 0.15:
		return
	var econ = bot_evaluate_economy(country)
	if econ == "poor":
		return
	var surplus_res = ""
	var surplus_amt = 0
	var strategic_minimums = {"oil": 800, "metal": 600, "food": 1000, "energy": 500, "coal": 400, "digital": 300}
	for res in strategic_minimums:
		var stock = country.resources.get(res)
		if stock == null: stock = 0
		var surplus = stock - strategic_minimums[res]
		if surplus > surplus_amt:
			surplus_amt = surplus
			surplus_res = res
	if surplus_res == "" or surplus_amt < 200:
		return
	var target_country = ""
	var target_need = 0
	for other_name in Data.country_list:
		if other_name == country.name: continue
		if Data.country_list[other_name].population.pop_number <= 0: continue
		var other = Data.country_list[other_name]
		var other_stock = other.resources.get(surplus_res)
		if other_stock == null: other_stock = 0
		var need = strategic_minimums.get(surplus_res, 500) - other_stock
		if need > target_need:
			target_need = need
			target_country = other_name
	if target_country == "":
		return
	for c in Data.contracts:
		if c["status"] == "active" or c["status"] == "pending":
			if (c["from_country"] == country.name and c["to_country"] == target_country) or \
			   (c["from_country"] == target_country and c["to_country"] == country.name):
				return
	var qty_offer = int(min(surplus_amt * 0.3, 300))
	var base_prices = {"oil": 50, "metal": 40, "coal": 20, "food": 10, "energy": 15, "digital": 100}
	var price = base_prices.get(surplus_res, 30)
	var money_ask = int(qty_offer * price * 0.8)
	var contract_id = str(Time.get_ticks_msec()) + "_bot_" + country.name
	var new_contract = {
		"contract_id": contract_id,
		"from_country": country.name,
		"to_country": target_country,
		"from_resource": surplus_res,
		"from_quantity": qty_offer,
		"to_resource": "money",
		"to_quantity": money_ask,
		"duration_turns": randi_range(3, 8),
		"turns_remaining": randi_range(3, 8),
		"status": "pending",
	}
	new_contract["turns_remaining"] = new_contract["duration_turns"]
	var contracts_copy = Data.contracts.duplicate(true)
	contracts_copy.append(new_contract)
	Data.request_sync_contracts(contracts_copy)



func bot_accept_contracts(country):
	var contracts_copy = Data.contracts.duplicate(true)
	var changed = false
	for i in range(contracts_copy.size()):
		var c = contracts_copy[i]
		if c["status"] != "pending": continue
		if c["to_country"] != country.name: continue

		var score = bot_evaluate_contract(country, c)
		if randf() < score:
			contracts_copy[i]["status"] = "active"
			Data.modify_relation(c["from_country"], country.name, 5)
			changed = true
		elif randf() < 0.1:
			contracts_copy[i]["status"] = "cancelled"
			Data.modify_relation(c["from_country"], country.name, -3)
			changed = true
	if changed:
		Data.request_sync_contracts(contracts_copy)

func bot_evaluate_contract(country, contract) -> float:
	var receive_res = contract["from_resource"]
	var receive_qty = int(contract["from_quantity"])
	var give_res    = contract["to_resource"]
	var give_qty    = int(contract["to_quantity"])
	var duration    = int(contract["duration_turns"])

	var res_values = {
	"oil": 50, "metal": 40, "coal": 20, "food": 10, "energy": 15,
	"wood": 8, "gold": 500, "rare_earth": 300, "digital": 100,
	"uranium": 200, "gas": 35, "money": 1,
	"soldier": 50000, "tank": 5000000, "armored_vehicle": 2000000,
	"aircraft": 20000000, "destroyer": 80000000, "submarine": 100000000,
	"aircraft_carrier": 500000000, "cyber_power": 50000000, "missile": 5000000
	}

	var receive_value = receive_qty * res_values.get(receive_res, 10) * duration
	var give_value    = give_qty    * res_values.get(give_res,    10) * duration

	if give_res == "money":
		var total_cost = give_qty * duration
		if float(country.economy.money) < total_cost * 1.2:
			return 0.05
	else:
		var stock = country.resources.get(give_res)
		if stock == null: stock = 0
		if stock < give_qty * duration:
			return 0.05

	var need_bonus = 0.0
	var receive_stock = country.resources.get(receive_res)
	if receive_res == "money":
		receive_stock = float(country.economy.money)
	if receive_stock == null: receive_stock = 0
	if receive_stock < 500:
		need_bonus = 0.35

	if give_value == 0:
		return 0.95

	var ratio = receive_value / float(give_value)

	if ratio >= 1.5: return min(0.95, 0.85 + need_bonus)
	if ratio >= 1.0: return min(0.90, 0.65 + need_bonus)
	if ratio >= 0.7: return min(0.70, 0.40 + need_bonus)
	if ratio >= 0.5: return min(0.40, 0.15 + need_bonus)
	return max(0.05, need_bonus - 0.1)


func bot_build(country):
	var money = float(country.economy.money)
	var econ = bot_evaluate_economy(country)
	var min_money = 50000000
	if econ == "poor": min_money = 20000000
	if money < min_money: return

	var build_priorities = []
	var res = country.resources

	var food = res.get("food"); if food == null: food = 0
	var energy = res.get("energy"); if energy == null: energy = 0
	var oil = res.get("oil"); if oil == null: oil = 0
	var metal = res.get("metal"); if metal == null: metal = 0
	var coal = res.get("coal"); if coal == null: coal = 0
	var digital = res.get("digital"); if digital == null: digital = 0

	if food < 500: build_priorities.append("farm")
	if food < 300: build_priorities.append("farm")
	if energy < 300: build_priorities.append("power_plant")
	if oil < 300: build_priorities.append("oil_refinery")
	if metal < 300: build_priorities.append("metal_foundry")
	if coal < 200: build_priorities.append("coal_mine")

	if econ == "rich":
		if digital < 500: build_priorities.append("data_center")
		build_priorities.append("gold_mine")
		build_priorities.append("rare_earth_mine")
	elif econ == "stable":
		build_priorities.append("sawmill")
		build_priorities.append("coal_mine")

	var all_infra = ["farm", "sawmill", "coal_mine", "power_plant", "metal_foundry", "oil_refinery"]
	build_priorities.append(all_infra[randi() % all_infra.size()])

	var build_costs = {
		"farm": {"wood": 500, "money": 10000000},
		"sawmill": {"metal": 200, "money": 25000000},
		"coal_mine": {"metal": 300, "money": 40000000},
		"power_plant": {"metal": 500, "coal": 200, "money": 60000000},
		"metal_foundry": {"metal": 800, "coal": 400, "money": 80000000},
		"oil_refinery": {"metal": 1000, "oil": 500, "money": 200000000},
		"data_center": {"metal": 500, "rare_earth": 100, "digital": 200, "money": 300000000},
		"gold_mine": {"metal": 400, "money": 400000000},
		"rare_earth_mine": {"metal": 600, "money": 600000000},
	}

	for build_key in build_priorities:
		if not build_costs.has(build_key): continue
		var costs = build_costs[build_key]
		var can_build = true
		for resource in costs:
			var cost_val = costs[resource]
			if resource == "money":
				if float(country.economy.money) < cost_val: can_build = false; break
			else:
				var stock = country.resources.get(resource)
				if stock == null or stock < cost_val: can_build = false; break
		if not can_build: continue
		for resource in costs:
			var cost_val = costs[resource]
			if resource == "money":
				Data.apply_economy_field.rpc(country.name, "money", float(country.economy.money) - cost_val)
			else:
				var stock = country.resources.get(resource)
				Data.apply_resources_field.rpc(country.name, resource, stock - cost_val)
		var current_infra = country.infrastructure.get(build_key)
		if current_infra == null: current_infra = 0
		Data.apply_infra_field.rpc(country.name, build_key, current_infra + 1)
		break

func bot_recruit(country):
	var econ = bot_evaluate_economy(country)
	if econ == "poor": 
		return
	var strength = bot_military_strength(country)
	if strength > 50000: 
		return

	var money = float(country.economy.money)
	var food = country.resources.get("food")
	if food == null: 
		food = 0

	if food > 500 and money > 10000000:
		var recruit_cost_per = 50000
		var max_recruit = int(min(money * 0.05 / recruit_cost_per, food * 0.1))
		max_recruit = min(max_recruit, 5000)
		if max_recruit > 100:
			var current = country.army.get("soldier")
			if current == null: current = 0
			Data.apply_army_field.rpc(country.name, "soldier", current + max_recruit)
			Data.apply_economy_field.rpc(country.name, "money", money - max_recruit * recruit_cost_per)
			Data.apply_resources_field.rpc(country.name, "food", food - int(max_recruit * 0.1))

	if econ == "rich":
		var metal = country.resources.get("metal")
		if metal == null: metal = 0
		if metal > 200 and money > 50000000:
			var tank_cost_money = 5000000
			var tank_cost_metal = 50
			var max_tanks = int(min(money * 0.03 / tank_cost_money, metal / tank_cost_metal))
			max_tanks = min(max_tanks, 10)
			if max_tanks > 0:
				var current = country.army.get("tank")
				if current == null: current = 0
				Data.apply_army_field.rpc(country.name, "tank", current + max_tanks)
				Data.apply_economy_field.rpc(country.name, "money", money - max_tanks * tank_cost_money)
				Data.apply_resources_field.rpc(country.name, "metal", metal - max_tanks * tank_cost_metal)


func get_bot_player_id(country_name: String) -> int:
	for id in Data.player_countries:
		if Data.player_countries[id] == country_name:
			return id
	return -1

func fmt_bot(n: float) -> String:
	if n >= 1000000:
		return str(snapped(n / 1000000.0, 0.1)).replace(".0", "") + "M"
	elif n >= 1000:
		return str(snapped(n / 1000.0, 0.1)).replace(".0", "") + "k"
	return str(int(n))


func process_wars():
	if not multiplayer.is_server():
		return
	for i in range(Data.wars.size()):
		var war = Data.wars[i]
		if war["status"] != "active":
			continue
		simulate_battle(i)
	Data.sync_wars.rpc(Data.wars)

func simulate_battle(war_index: int):
	var war = Data.wars[war_index]
	var att_troops = war.get("attacker_troops", {}).duplicate()
	var def_troops = war.get("defender_troops", {}).duplicate()

	if att_troops.is_empty() and def_troops.is_empty():
		return

	var unit_strength = {
		"soldier": 1, "tank": 50, "armored_vehicle": 20,
		"aircraft": 80, "destroyer": 100, "submarine": 120,
		"aircraft_carrier": 200, "cyber_power": 30,
	}

	var att_strength = 0.0
	for unit in att_troops:
		att_strength += att_troops[unit] * unit_strength.get(unit, 1)

	var def_strength = 0.0
	for unit in def_troops:
		def_strength += def_troops[unit] * unit_strength.get(unit, 1)

	if att_strength == 0.0 and def_strength == 0.0:
		return

	var total = att_strength + def_strength
	var att_loss_rate = randf_range(0.03, 0.08) * (def_strength / max(1.0, total))
	var def_loss_rate = randf_range(0.03, 0.08) * (att_strength / max(1.0, total))

	var att_name = war["attacker"]
	var def_name = war["defender"]

	if not Data.wars[war_index].has("attacker_losses") or Data.wars[war_index]["attacker_losses"] == null:
		Data.wars[war_index]["attacker_losses"] = {}
	if not Data.wars[war_index].has("defender_losses") or Data.wars[war_index]["defender_losses"] == null:
		Data.wars[war_index]["defender_losses"] = {}

	var att_loss_report = ""
	var def_loss_report = ""

	for unit in att_troops.keys():
		var losses = int(att_troops[unit] * att_loss_rate)
		if losses <= 0:
			continue
		var new_val = max(0, att_troops[unit] - losses)
		Data.wars[war_index]["attacker_troops"][unit] = new_val
		if not Data.wars[war_index]["attacker_losses"].has(unit):
			Data.wars[war_index]["attacker_losses"][unit] = 0
		Data.wars[war_index]["attacker_losses"][unit] += losses
		att_loss_report += "  -" + str(losses) + " " + unit + "\n"

	for unit in def_troops.keys():
		var losses = int(def_troops[unit] * def_loss_rate)
		if losses <= 0:
			continue
		var new_val = max(0, def_troops[unit] - losses)
		Data.wars[war_index]["defender_troops"][unit] = new_val
		if not Data.wars[war_index]["defender_losses"].has(unit):
			Data.wars[war_index]["defender_losses"][unit] = 0
		Data.wars[war_index]["defender_losses"][unit] += losses
		def_loss_report += "  -" + str(losses) + " " + unit + "\n"

	var att_pid = Data.get_pid(att_name)
	var def_pid = Data.get_pid(def_name)

	var att_msg = "⚔ Battle vs " + def_name + "\nYour losses:\n" + (att_loss_report if att_loss_report != "" else "  None")
	var def_msg = "⚔ Battle vs " + att_name + "\nYour losses:\n" + (def_loss_report if def_loss_report != "" else "  None")

	if att_pid == 1:
		Data.show_popup(att_msg)
	elif att_pid != -1:
		Data.notify_player.rpc_id(att_pid, att_msg)

	if def_pid == 1:
		Data.show_popup(def_msg)
	elif def_pid != -1:
		Data.notify_player.rpc_id(def_pid, def_msg)


func bot_strike(country):
	var missiles = country.army.get("missile")
	if missiles == null or missiles <= 0:
		return

	for w in Data.wars:
		if w["status"] != "active": continue
		if w["attacker"] != country.name and w["defender"] != country.name: continue

		if randf() > 0.30:
			continue

		var enemy_name = w["defender"] if w["attacker"] == country.name else w["attacker"]
		if not Data.country_list.has(enemy_name): continue

		var qty = min(missiles, randi_range(1, 3))

		var target_type = "soldier"

		var enemy_troops_key = "defender_troops" if w["attacker"] == country.name else "attacker_troops"
		var enemy_deployed = 0
		for unit in w.get(enemy_troops_key, {}):
			enemy_deployed += w[enemy_troops_key][unit]

		if enemy_deployed > 5000:
			target_type = "soldier"
		elif enemy_deployed > 1000:
			var choices = ["soldier", "tank", "infrastructure", "resources"]
			target_type = choices[randi() % choices.size()]
		else:
			var choices = ["infrastructure", "resources", "population"]
			target_type = choices[randi() % choices.size()]

		Data._apply_strike(country.name, enemy_name, "missile", qty, target_type)
		break

func bot_war(country):
	for w in Data.wars:
		if (w["attacker"] == country.name or w["defender"] == country.name) and w["status"] == "active":
			return

	var strength = bot_military_strength(country)
	if strength < 8000:
		return

	if bot_evaluate_economy(country) == "poor":
		return

	if randf() > 0.04:
		return

	if not Data.relations.has(country.name):
		return

	var best_target = ""
	var best_score = 0.0

	for other_name in Data.relations[country.name]:
		if other_name == country.name: continue
		if not Data.country_list.has(other_name): continue
		var other = Data.country_list[other_name]
		if other.population.pop_number <= 0: continue

		var rel = Data.relations[country.name][other_name]
		if rel >= 35: continue

		var already_at_war = false
		for w in Data.wars:
			if (w["attacker"] == country.name and w["defender"] == other_name) or \
			   (w["attacker"] == other_name and w["defender"] == country.name):
				already_at_war = true; break
		if already_at_war: continue

		var enemy_strength = bot_military_strength(other)
		if enemy_strength == 0: enemy_strength = 1

		var hostility = (35 - rel)
		var military_ratio = strength / enemy_strength
		if military_ratio < 0.8: continue 

		var score = hostility * min(military_ratio, 3.0)
		if score > best_score:
			best_score = score
			best_target = other_name

	if best_target == "":
		return

	var army = country.army
	var troops = {}
	var unit_types = ["soldier", "tank", "armored_vehicle", "aircraft", "destroyer", "submarine"]
	for unit in unit_types:
		var count = army.get(unit)
		if count == null or count <= 0: continue
		var send = int(count * randf_range(0.25, 0.5))
		if send > 0:
			troops[unit] = send
			Data.apply_army_field.rpc(country.name, unit, count - send)

	if troops.is_empty():
		return

	Data.declare_war(country.name, best_target, troops)

func bot_accept_peace(country):
	for p in Data.peace_proposals.duplicate():
		if p["to"] != country.name: continue
		if p["status"] != "pending": continue

		var peace_type = p.get("peace_type", "classic")
		var terms = p.get("terms", {})

		var my_strength = bot_military_strength(country)
		var enemy_strength = 0.0
		if Data.country_list.has(p["from"]):
			enemy_strength = bot_military_strength(Data.country_list[p["from"]])

		var my_remaining = 0
		for w in Data.wars:
			if w["status"] != "active": continue
			if w["attacker"] != country.name and w["defender"] != country.name: continue
			var my_key = "attacker_troops" if w["attacker"] == country.name else "defender_troops"
			for unit in w.get(my_key, {}):
				my_remaining += w[my_key][unit]

		var rel_val = 50
		if Data.relations.has(country.name) and Data.relations[country.name].has(p["from"]):
			rel_val = Data.relations[country.name][p["from"]]

		var accept_chance = 0.1

		match peace_type:
			"classic":
				if my_remaining < 300: accept_chance = 0.95
				elif my_remaining < 1000: accept_chance = 0.6
				elif my_strength > enemy_strength * 1.2: accept_chance = 0.2
				else: accept_chance = 0.4
			"invasion":
				var pct = terms.get("percent", 20)
				if my_remaining < 200: accept_chance = 0.7
				elif pct <= 10 and my_remaining < 500: accept_chance = 0.4
				else: accept_chance = 0.05
			"surrender":
				if my_strength > enemy_strength * 1.3: accept_chance = 0.9
				else: accept_chance = 0.3

		if randf() < accept_chance:
			Data.request_accept_peace(p["from"], p["to"])

func bot_propose_peace(country):
	for w in Data.wars:
		if w["status"] != "active": continue
		if w["attacker"] != country.name and w["defender"] != country.name: continue

		var my_troops_key = "attacker_troops" if w["attacker"] == country.name else "defender_troops"
		var enemy_name = w["defender"] if w["attacker"] == country.name else w["attacker"]

		var my_remaining = 0
		for unit in w.get(my_troops_key, {}):
			my_remaining += w[my_troops_key][unit]

		var already_proposed = false
		for p in Data.peace_proposals:
			if (p["from"] == country.name and p["to"] == enemy_name) or \
			   (p["from"] == enemy_name and p["to"] == country.name):
				already_proposed = true; break
		if already_proposed: continue

		var turns_at_war = Data.tour - w.get("start_turn", Data.tour)
		var my_strength = bot_military_strength(country)
		var enemy_strength = 0.0
		if Data.country_list.has(enemy_name):
			enemy_strength = bot_military_strength(Data.country_list[enemy_name])

		var propose_chance = 0.03
		if my_remaining < 200: propose_chance = 0.95
		elif my_remaining < 1000: propose_chance = 0.6
		elif my_strength < enemy_strength * 0.5: propose_chance = 0.4
		elif turns_at_war > 8: propose_chance = 0.3
		elif turns_at_war > 5: propose_chance = 0.15

		if randf() < propose_chance:
			var peace_type = "classic"
			var terms = {}
			if my_strength > enemy_strength * 1.5 and my_remaining > 2000:
				peace_type = "invasion"
				terms = {"percent": randi_range(10, 25)}
			elif my_remaining < 500:
				peace_type = "surrender"

			Data.peace_proposals.append({
				"from": country.name, "to": enemy_name,
				"status": "pending",
				"peace_type": peace_type,
				"terms": terms,
			})
			Data.sync_peace.rpc(Data.peace_proposals)
			Data.peace_updated.emit()
			var pid = Data.get_pid(enemy_name)
			var type_labels = {"classic": "🕊 Classic Peace", "invasion": "⚔ Annexation terms", "surrender": "🏳 Surrender"}
			var msg = country.name + " proposes: " + type_labels.get(peace_type, "Peace") + "\nCheck your war panel!"
			if pid == 1: Data.show_popup(msg)
			elif pid != -1: Data.notify_player.rpc_id(pid, msg)


func bot_reinforce(country):
	for w in Data.wars:
		if w["status"] != "active": continue
		if w["attacker"] != country.name and w["defender"] != country.name: continue

		var my_troops_key = "attacker_troops" if w["attacker"] == country.name else "defender_troops"
		var enemy_troops_key = "defender_troops" if w["attacker"] == country.name else "attacker_troops"

		var unit_strength = {"soldier": 1, "tank": 50, "armored_vehicle": 20,
			"aircraft": 80, "destroyer": 100, "submarine": 120, "aircraft_carrier": 200}

		var my_strength = 0.0
		for unit in w.get(my_troops_key, {}):
			my_strength += w[my_troops_key][unit] * unit_strength.get(unit, 1)

		var enemy_strength = 0.0
		for unit in w.get(enemy_troops_key, {}):
			enemy_strength += w[enemy_troops_key][unit] * unit_strength.get(unit, 1)

		var ratio = my_strength / max(1.0, enemy_strength)
		if ratio > 1.3 and randf() > 0.15:
			continue

		var send_rate = 0.15
		if ratio < 0.5: send_rate = 0.4
		elif ratio < 0.8: send_rate = 0.25

		var army = country.army
		var troops = {}
		for unit in ["soldier", "tank", "armored_vehicle", "aircraft", "destroyer", "submarine"]:
			var available = army.get(unit)
			if available == null or available <= 0: continue
			var send = int(available * randf_range(send_rate * 0.7, send_rate * 1.3))
			if send <= 0: continue
			troops[unit] = send
			Data.apply_army_field.rpc(country.name, unit, available - send)

		if troops.is_empty(): continue
		Data.add_war_troops(country.name, w["attacker"], w["defender"], troops)
		break
