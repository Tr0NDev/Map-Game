extends Label

@onready var map_node : Node2D = $"../.."

func _process(_delta):
	if map_node.last_country_clicked == "":
		text = "Unknown"
	else:
		for country in Data.country_list.values():
			if country.name == map_node.last_country_clicked:
				text = country.name
