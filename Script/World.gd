extends Node

@onready var main_menu = $Node3D/CanvasLayer/MainMenu
@onready var adress_entry = $Node3D/CanvasLayer/MainMenu/MarginContainer/VBoxContainer/AdressEntry
@onready var HUD = $Node3D/CanvasLayer/HUD
@onready var health_bar = $Node3D/CanvasLayer/HUD/HealthBar
@onready var score_counter = $Node3D/CanvasLayer/HUD/SValue

const PLAYER = preload("res://scene/player.tscn")

const PORT = 9999
var enet_peer = ENetMultiplayerPeer.new()

func _unhandled_input(event):
	if Input.is_action_just_pressed("quit"):
		get_tree().quit()


func _on_host_button_pressed():
	main_menu.hide()
	HUD.show()
	
	enet_peer.create_server(PORT)
	multiplayer.multiplayer_peer = enet_peer
	multiplayer.peer_connected.connect(add_player)
	multiplayer.peer_disconnected.connect(remove_player)
	
	add_player(multiplayer.get_unique_id())
	
	upnp_setup()

func _on_join_button_pressed():
	main_menu.hide()
	HUD.show()
	
	enet_peer.create_client(adress_entry.text, PORT)
	multiplayer.multiplayer_peer = enet_peer

func add_player(peer_id):
	var player = PLAYER.instantiate()
	player.name = str(peer_id)
	add_child(player)
	if player.is_multiplayer_authority():
		player.health_changed.connect(update_health_bar)
		player.score_changed.connect(update_score_value)

func update_health_bar(health_value):
	health_bar.value = health_value

func update_score_value(score_value):
	score_counter.text = str(score_value)

func _on_multiplayer_spawner_spawned(node):
	if node.is_multiplayer_authority():
		node.health_changed.connect(update_health_bar)
		node.score_changed.connect(update_score_value)

func remove_player(peer_id):
	var player = get_node_or_null(str(peer_id))
	if player:
		player.queue_free()

func upnp_setup():
	var upnp = UPNP.new()
	
	var discover_result = upnp.discover()
	assert(discover_result == UPNP.UPNP_RESULT_SUCCESS,  \
		"UPNP Discover FAILURE ! ERROR %s" % discover_result)
	
	assert(upnp.get_gateway() and upnp.get_gateway().is_valid_gateway(), \
		"UPNP Invalid Gateway !")
	
	var map_result = upnp.add_port_mapping(PORT)
	assert(map_result == UPNP.UPNP_RESULT_SUCCESS, \
		"UPNP Port Mapping Failed ! Error %s" % map_result)
	
	print("SUCCESS ! Join adress : %s" % upnp.query_external_address())
