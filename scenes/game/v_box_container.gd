extends VBoxContainer


func display_terrain_stats(country):
	print("ok")
	var ter = country.terrain
	
	for child in get_children():
		child.queue_free()
	
	var resources = ["Oil", "Metal", "Coal", "Gas", "Uranium", "Food", "Energy", "Wood", "Gold", "Rare Earth"]
	
	for resource_name in resources:
		print("ok")
		var btn = Button.new()
		btn.text = resource_name
		btn.pressed.connect(_on_resource_pressed.bind(resource_name))
		add_child(btn)

func _on_resource_pressed(resource_name: String):
	print(resource_name)
