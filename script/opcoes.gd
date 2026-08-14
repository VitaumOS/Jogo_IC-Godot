extends Control

@onready var check_mute = $PainelCentral/MarginContainer/VBoxContainer/HBoxSom/CheckMute
@onready var option_velocidade = $PainelCentral/MarginContainer/VBoxContainer/HBoxVelocidade/OptionVelocidade
@onready var btn_voltar = $PainelCentral/MarginContainer/VBoxContainer/Node2D/BtnVoltar

func _ready() -> void:
	_configurar_opcoes_ui()
	_carregar_valores_salvos()
	
	# Conexão de sinais via código (opcional se já conectou pelo Editor)
	check_mute.toggled.connect(_on_check_mute_toggled)
	option_velocidade.item_selected.connect(_on_option_velocidade_item_selected)
	btn_voltar.pressed.connect(_on_btn_voltar_pressed)

func _configurar_opcoes_ui() -> void:
	option_velocidade.clear()
	option_velocidade.add_item("Lenta", Global.VelocidadeTexto.LENTA)
	option_velocidade.add_item("Média", Global.VelocidadeTexto.MEDIA)
	option_velocidade.add_item("Instantânea", Global.VelocidadeTexto.INSTANTANEA)

func _carregar_valores_salvos() -> void:
	check_mute.button_pressed = Global.som_mutado
	option_velocidade.select(Global.velocidade_dialogo)

func _on_check_mute_toggled(toggled_on: bool) -> void:
	Global.definir_mute_som(toggled_on)

func _on_option_velocidade_item_selected(index: int) -> void:
	Global.velocidade_dialogo = index as Global.VelocidadeTexto

func _on_btn_voltar_pressed() -> void:
	get_tree().change_scene_to_file("res://scene/TelaInicial.tscn")
