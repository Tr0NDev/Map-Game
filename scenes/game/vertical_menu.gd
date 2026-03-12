extends VBoxContainer

@onready var market : Panel = $"../Market"
@onready var diplomacy : Panel = $"../Diplomacy"
@onready var contract : Panel = $"../Contract"
@onready var create : Panel = $"../Create"
@onready var war : Panel = $"../War"
@onready var pop : Panel = $"../Population"


func _on_market_button_down() -> void:
	market.show()
	pass


func _on_diplomacy_button_down() -> void:
	diplomacy.show()
	pass


func _on_contract_button_down() -> void:
	contract.show()
	pass


func _on_create_button_down() -> void:
	create.show()
	pass 


func _on_war_button_down() -> void:
	war.show()
	pass


func _on_population_button_down() -> void:
	pop.show()
	pass 
