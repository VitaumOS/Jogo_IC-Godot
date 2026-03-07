extends Control

signal resposta(valor: bool)

@onready var label_mensagem = $PopUp/Placa/VBox/Control2/Mensagem
@onready var btn_sim = $PopUp/Placa/VBox/Control/HBoxBtn/BtnSim
@onready var btn_nao = $PopUp/Placa/VBox/Control/HBoxBtn/BtnNao
@onready var btn_ok = $PopUp/Placa/VBox/Control/HBoxBtn/BtnOk

func _ready():
	btn_sim.pressed.connect(_on_btn_sim_pressed)
	btn_nao.pressed.connect(_on_btn_nao_pressed)
	btn_ok.pressed.connect(_on_btn_ok_pressed)
	visible = false

## Função para apenas exibir uma mensagem com botão OK
func mostrar_mensagem(texto: String):
	label_mensagem.text = texto
	btn_sim.visible = false
	btn_nao.visible = false
	btn_ok.visible = true
	_abrir()

## Função para confirmação (Sim ou Não)
func mostrar_confirmacao(texto: String):
	label_mensagem.text = texto
	btn_sim.visible = true
	btn_nao.visible = true
	btn_ok.visible = false
	_abrir()

func _abrir():
	visible = true
	var tween = create_tween()
	$PopUp/Placa.scale = Vector2.ZERO
	tween.tween_property($PopUp/Placa, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK)

func _on_btn_sim_pressed():
	resposta.emit(true)
	queue_free()
	
func _on_btn_nao_pressed():
	resposta.emit(false)
	queue_free()

func _on_btn_ok_pressed():
	resposta.emit(true)
	queue_free()
