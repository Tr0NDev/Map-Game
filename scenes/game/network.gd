extends Node

const PORT = 32771
const MAX_PLAYERS = 8

var peer : ENetMultiplayerPeer

signal player_connected(id)
signal player_disconnected(id)

func _ready():
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)

func _on_connected_to_server():
	Data.request_country.rpc_id(1)  

func host_game():
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(PORT, MAX_PLAYERS)
	if error != OK:
		print("Erreur création serveur : ", error)
		return
	multiplayer.multiplayer_peer = peer
	var assigned = "France"
	Data.player_countries[1] = assigned
	Data.player_country = Data.country_list[assigned]
	print("Serveur lancé sur port ", PORT)

func join_game(ip: String):
	peer = ENetMultiplayerPeer.new()
	peer.create_client(ip, PORT)
	multiplayer.multiplayer_peer = peer

func _on_peer_connected(id):
	emit_signal("player_connected", id)

func _on_peer_disconnected(id):
	emit_signal("player_disconnected", id)
	Data.player_countries.erase(id)
