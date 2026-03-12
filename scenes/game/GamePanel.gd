extends Panel

#@onready var hbox : HBoxContainer = $"../HBoxContainer"

var hauteur_par_ligne = 25

var dragging = false
var offset = Vector2()

#func _ready():
#	ajuster_taille_panel()

#func ajuster_taille_panel():
#	size.y = hbox.hauteur * hauteur_par_ligne

func _process(_delta):
	#ajuster_taille_panel()
	
	var screen_size = get_viewport_rect().size
	var panel_size = size 

	position.x = clamp(position.x, 0, screen_size.x - panel_size.x)
	position.y = clamp(position.y, 0, screen_size.y - panel_size.y)

func _gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				dragging = true
				offset = get_global_mouse_position() - global_position
				move_to_front()
			else:
				dragging = false
	if event is InputEventMouseMotion and dragging:
		global_position = get_global_mouse_position() - offset

func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		hide()
