extends Node
@onready var market_panel : Panel = $"../"
@onready var hbox : HBoxContainer = $"../HBoxContainer"
@onready var country_info : Label = $"../Country_Info"
@onready var sell_amount : SpinBox = $"../SellAmount"
@onready var sell_price : SpinBox = $"../SellPrice"
@onready var sell_btn : Button = $"../Sell"
@onready var offers_vbox : VBoxContainer = $"../ScrollContainer/OffersVBox"
@onready var anonymous_check : CheckBox = $"../Anonymous"

var resources = ["Oil", "Metal", "Coal", "Gas", "Uranium", "Food", "Energy", "Wood", "Gold", "Rare Earth", "Digital"]
var selected_resource = ""
var market_offers = []


func _ready():
	sell_amount.min_value = 1
	sell_amount.max_value = 999999
	sell_amount.step = 1
	sell_amount.value = 1

	sell_price.min_value = 1
	sell_price.max_value = 999999
	sell_price.step = 1
	sell_price.value = 10

	for resource_name in resources:
		var btn = Button.new()
		btn.text = resource_name
		btn.pressed.connect(on_resource_pressed.bind(resource_name))
		hbox.add_child(btn)

	sell_btn.pressed.connect(on_sell)
	load_market()

func load_market():
	Data.market_offers.clear()
	var file = FileAccess.open("res://globaldata/market.csv", FileAccess.READ)
	if file == null:
		print("Erreur ouverture market.csv")
		return
	file.get_line()
	while not file.eof_reached():
		var line = file.get_line().strip_edges()
		if line == "":
			continue
		var parts = line.split(",")
		if parts.size() < 6:
			continue
		Data.market_offers.append({
			"offer_id": parts[0].strip_edges(),
			"country": parts[1].strip_edges(),
			"resource": parts[2].strip_edges(),
			"quantity": int(parts[3].strip_edges()),
			"price_per_unit": float(parts[4].strip_edges()),
			"country_name": parts[5].strip_edges(),
		})
	file.close()

func display_offers(resource_name: String):
	for child in offers_vbox.get_children():
		child.queue_free()

	var key = resource_name.to_lower().replace(" ", "_")
	var found = false
	var player_name = Data.player_country.name

	var filtered = []
	for i in range(Data.market_offers.size()):
		var offer = Data.market_offers[i]
		if offer["resource"].to_lower().replace(" ", "_") != key:
			continue
		if offer["quantity"] <= 0:
			continue
		filtered.append({"index": i, "offer": offer})

	filtered.sort_custom(func(a, b): return a["offer"]["price_per_unit"] < b["offer"]["price_per_unit"])

	for entry in filtered:
		var i = entry["index"]
		var offer = entry["offer"]
		found = true

		var row = HBoxContainer.new()
		var seller_label = Label.new()
		seller_label.text = offer["country_name"]
		seller_label.custom_minimum_size = Vector2(120, 0)
		row.add_child(seller_label)

		var qty_label = Label.new()
		qty_label.text = str(offer["quantity"]) + " units"
		qty_label.custom_minimum_size = Vector2(80, 0)
		row.add_child(qty_label)

		var tariff = Data.get_tariff(player_name, offer["country"])
		var base_price = offer["price_per_unit"]
		var final_price = base_price * (1.0 + tariff / 100.0)

		var price_label = Label.new()
		if tariff > 0:
			price_label.text = fmt(final_price) + "$/u (+"+str(int(tariff))+"%)"
			price_label.modulate = Color(1, 0.7, 0.3)
		else:
			price_label.text = fmt(final_price) + "$/u"
		price_label.custom_minimum_size = Vector2(110, 0)
		row.add_child(price_label)

		var buy_spinbox = SpinBox.new()
		buy_spinbox.min_value = 1
		buy_spinbox.max_value = offer["quantity"]
		buy_spinbox.step = 1
		buy_spinbox.value = 1
		buy_spinbox.custom_minimum_size = Vector2(80, 0)
		row.add_child(buy_spinbox)

		if offer["country"] == player_name:
			var own_label = Label.new()
			own_label.text = "(your offer)"
			row.add_child(own_label)

			var cancel_btn = Button.new()
			cancel_btn.text = "Cancel"
			cancel_btn.pressed.connect(on_cancel_offer.bind(i))
			row.add_child(cancel_btn)
		else:
			var buy_btn = Button.new()
			buy_btn.text = "Buy"
			buy_btn.pressed.connect(on_buy_offer.bind(i, buy_spinbox, final_price))
			row.add_child(buy_btn)

		offers_vbox.add_child(row)

	if not found:
		var lbl = Label.new()
		lbl.text = "No offers for " + resource_name
		offers_vbox.add_child(lbl)



func on_cancel_offer(offer_index: int):
	var offer = Data.market_offers[offer_index]
	var key = offer["resource"].to_lower().replace(" ", "_")
	var quantity = offer["quantity"]
	
	var current = Data.player_country.resources.get(key)
	if current == null:
		current = 0
	apply_resources(Data.player_country.name, key, current + quantity)
	
	Data.market_offers.remove_at(offer_index)
	sync_market()
	
	Data.show_popup("Offer cancelled\n+" + str(quantity) + " " + offer["resource"] + " returned")
	refresh()

func on_resource_pressed(resource_name: String):
	selected_resource = resource_name
	var res = Data.player_country.resources
	var key = resource_name.to_lower().replace(" ", "_")
	var amount = res.get(key)
	country_info.text = resource_name + ": " + str(amount if amount != null else 0) + " units"
	display_offers(resource_name)

func on_sell():
	if selected_resource == "":
		Data.show_popup("Select a resource first!")
		return
	var amount = int(sell_amount.value)
	var price = float(sell_price.value)
	var key = selected_resource.to_lower().replace(" ", "_")
	var current = Data.player_country.resources.get(key)
	if current == null or current < amount:
		Data.show_popup("Not enough " + selected_resource + "!")
		return

	var new_stock = current - amount
	apply_resources(Data.player_country.name, key, new_stock)

	var display_name = "Unknown" if anonymous_check.button_pressed else Data.player_country.name

	Data.market_offers.append({
		"offer_id": str(Data.market_offers.size() + 1),
		"country": Data.player_country.name, 
		"resource": key,
		"quantity": amount,
		"price_per_unit": price,
		"country_name": display_name, 
	})

	sync_market()
	Data.show_popup("Offer posted!\n" + str(amount) + " " + selected_resource + " @ " + fmt(price) + "$/u")
	refresh()

func on_buy_offer(offer_index: int, buy_spinbox: SpinBox, final_price: float):
	var offer = Data.market_offers[offer_index]
	var amount = int(buy_spinbox.value)
	var key = offer["resource"].to_lower().replace(" ", "_")
	var cost = amount * final_price
	var buyer_money = float(Data.player_country.economy.money)

	if buyer_money < cost:
		Data.show_popup("Not enough money!\nNeed " + fmt(cost) + "$")
		return

	var buyer_stock = Data.player_country.resources.get(key)
	if buyer_stock == null:
		buyer_stock = 0
	apply_resources(Data.player_country.name, key, buyer_stock + amount)
	apply_money(Data.player_country.name, buyer_money - cost)

	var base_cost = amount * offer["price_per_unit"]
	var seller_name = offer["country"]
	if Data.country_list.has(seller_name):
		var seller_money = float(Data.country_list[seller_name].economy.money)
		apply_money(seller_name, seller_money + cost)

	var pid = get_player_id(seller_name)
	if pid != -1 and seller_name != Data.player_country.name:
		var msg = Data.player_country.name + " bought " + str(amount) + " " + offer["resource"] + " from you\n+" + fmt(cost) + "$"
		if multiplayer.is_server():
			if pid == 1:
				Data.show_popup(msg)
			else:
				Data.notify_player.rpc_id(pid, msg)
		else:
			Data.request_notify_player.rpc_id(1, seller_name, msg)

	Data.market_offers[offer_index]["quantity"] -= amount
	if Data.market_offers[offer_index]["quantity"] <= 0:
		Data.market_offers.remove_at(offer_index)
	sync_market()

	Data.show_popup("Bought " + str(amount) + " " + offer["resource"] + "\nfrom " + offer["country_name"] + "\n-" + fmt(cost) + "$")
	refresh()

func sync_market():
	if multiplayer.is_server():
		Data.sync_market.rpc(Data.market_offers)
		Data.sync_market(Data.market_offers)
	else:
		Data.request_sync_market.rpc_id(1, Data.market_offers)

func get_player_id(country_name: String) -> int:
	for id in Data.player_countries:
		if Data.player_countries[id] == country_name:
			return id
	return -1

func apply_resources(country_name: String, resource_key: String, new_stock):
	if multiplayer.is_server():
		Data.apply_resources_field.rpc(country_name, resource_key, new_stock)
	else:
		Data.request_set_resources_field.rpc_id(1, country_name, resource_key, new_stock)

func apply_money(country_name: String, new_money: float):
	if multiplayer.is_server():
		Data.apply_economy_field.rpc(country_name, "money", new_money)
	else:
		Data.request_set_economy_field.rpc_id(1, country_name, "money", new_money)

func refresh():
	if selected_resource != "":
		on_resource_pressed(selected_resource)

func fmt(n: float) -> String:
	if n >= 1000000:
		return str(snapped(n / 1000000.0, 0.1)).replace(".0", "") + "M"
	elif n >= 1000:
		return str(snapped(n / 1000.0, 0.1)).replace(".0", "") + "k"
	return str(int(n))

func _on_market_close_button_down() -> void:
	var screen_size = get_viewport().get_visible_rect().size
	market_panel.global_position = Vector2(0, (screen_size.y - market_panel.size.y) / 2)
	market_panel.hide()
