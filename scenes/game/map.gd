extends Node2D

@onready var map_sprite : Sprite2D = $Map
@onready var faded_map_sprite : Sprite2D = $Faded_Map
@onready var camera : Camera2D = $Camera2D


var color_to_country : Dictionary = {}
const COLOR_TOLERANCE := 0.05

var dragging := false
var last_mouse_pos := Vector2.ZERO

const DRAG_SPEED := 1.0
const ZOOM_SPEED := 0.1
const MIN_ZOOM := 0.3
const MAX_ZOOM := 5.0

@export var last_country_clicked : String = ""

func _ready():
	load_country_file("res://mapdata/countries.txt")
	make_white_transparent()
	make_faded_white_transparent()


func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		detect_country()

	if event is InputEventMouseButton:

		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_camera(-ZOOM_SPEED)

		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_camera(ZOOM_SPEED)

		if event.button_index == MOUSE_BUTTON_RIGHT:
			dragging = event.pressed
			last_mouse_pos = event.position

	if event is InputEventMouseMotion and dragging:

		var delta = event.position - last_mouse_pos

		var speed = DRAG_SPEED / camera.zoom.x

		camera.position -= delta * speed

		last_mouse_pos = event.position


func zoom_camera(amount: float):
	var new_zoom = camera.zoom + Vector2(amount, amount)

	new_zoom.x = clamp(new_zoom.x, MIN_ZOOM, MAX_ZOOM)
	new_zoom.y = clamp(new_zoom.y, MIN_ZOOM, MAX_ZOOM)

	camera.zoom = new_zoom

func detect_country():
	if map_sprite.texture == null:
		return

	var texture = map_sprite.texture
	var image = texture.get_image()
	var tex_size = texture.get_size()

	var mouse_pos = camera.get_global_mouse_position()

	var local_pos = map_sprite.to_local(mouse_pos)

	local_pos += tex_size / 2

	if local_pos.x < 0 or local_pos.y < 0 or local_pos.x >= tex_size.x or local_pos.y >= tex_size.y:
		print("Pas sur la map")
		return

	local_pos = local_pos.floor()

	var pixel_color = image.get_pixelv(local_pos)
	pixel_color.a = 1.0


	var country = find_country_by_color(pixel_color)

	if country != "":
		last_country_clicked = country
	else:
		last_country_clicked = ""
		print("Couleur inconnue : %.4f,%.4f,%.4f" % [pixel_color.r, pixel_color.g, pixel_color.b])


func find_country_by_color(pixel_color: Color) -> String:
	for color in color_to_country.keys():
		if abs(pixel_color.r - color.r) < COLOR_TOLERANCE and \
		abs(pixel_color.g - color.g) < COLOR_TOLERANCE and \
		abs(pixel_color.b - color.b) < COLOR_TOLERANCE:
			return color_to_country[color]

	return ""


func load_country_file(path: String):
	if not FileAccess.file_exists(path):
		print("Fichier introuvable : ", path)
		return

	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		print("Erreur ouverture : ", FileAccess.get_open_error())
		return
		
	while not file.eof_reached():
		var line = file.get_line().strip_edges()

		if line == "":
			continue

		var parts = line.split("=")

		if parts.size() != 2:
			continue

		var country = parts[0].strip_edges()
		var rgb = parts[1].strip_edges().split(",")

		var color = Color(
			float(rgb[0]),
			float(rgb[1]),
			float(rgb[2]),
			1.0
		)

		color_to_country[color] = country

	file.close()


func make_white_transparent():
	if map_sprite.texture == null:
		return

	var texture = map_sprite.texture
	var image = texture.get_image()

	var threshold := 0.6863

	for x in range(image.get_width()):
		for y in range(image.get_height()):
			var c = image.get_pixel(x, y)

			if c.r >= threshold and c.g >= threshold and c.b >= threshold:
				c.a = 0.0
				image.set_pixel(x, y, c)

	var new_texture = ImageTexture.create_from_image(image)
	map_sprite.texture = new_texture
	
	
func make_faded_white_transparent():
	if faded_map_sprite.texture == null:
		return
	var image = faded_map_sprite.texture.get_image()
	image.convert(Image.FORMAT_RGBA8)
	for x in range(image.get_width()):
		for y in range(image.get_height()):
			var c = image.get_pixel(x, y)
			if c.r >= 0.9 and c.g >= 0.9 and c.b >= 0.9:
				image.set_pixel(x, y, Color(c.r, c.g, c.b, 0.0))
	faded_map_sprite.texture = ImageTexture.create_from_image(image)
