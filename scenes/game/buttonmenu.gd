extends HBoxContainer

@onready var map_node : Node2D = $"../.."
@onready var economy_panel : Panel = $"../Economy"
@onready var army_panel : Panel = $"../Army"
@onready var infra_panel : Panel = $"../Infrastructure"
@onready var resources_panel : Panel = $"../Resources"
@onready var country_panel : Panel = $"../Country"
@onready var terrain_panel : Panel = $"../Terrain"



func _process(_delta):
	if Data.player_country == null:
		hide()
		return
	if map_node.last_country_clicked == Data.player_country.name:
		show()
	else:
		hide()
			
func _on_economy_button_down() -> void:
	hide()
	economy_panel.show()
	pass


func _on_army_button_down() -> void:
	hide()
	army_panel.show()
	pass


func _on_infrastructure_button_down() -> void:
	hide()
	infra_panel.show()
	pass


func _on_ressources_button_down() -> void:
	hide()
	resources_panel.show()
	pass


func _on_country_button_down() -> void:
	hide()
	country_panel.show()
	pass


func _on_terrain_button_down() -> void:
	hide()
	terrain_panel.show()
	pass
