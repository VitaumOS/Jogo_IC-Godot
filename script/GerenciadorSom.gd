extends Node

var audio_player: AudioStreamPlayer
var som_clique = preload("res://sounds/Wood_button.wav")

func _ready():
	process_mode = PROCESS_MODE_ALWAYS
	audio_player = AudioStreamPlayer.new()
	add_child(audio_player)
	get_tree().node_added.connect(_on_node_added)

func _on_node_added(node: Node):
	if node is BaseButton:
		node.pressed.connect(_on_button_pressed)

func _on_button_pressed():
	audio_player.stream = som_clique
	audio_player.play()
