extends CanvasLayer

signal resposta(valor: bool)

@onready var label_mensagem = $Control2/Mensagem
@onready var btn_sim = $Control/HBoxBtn/BtnSim
@onready var btn_nao = $Control/HBoxBtn/BtnNao
@onready var btn_ok = $Control/HBoxBtn/BtnOk

func _ready():
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
	get_tree().paused = true
	
	var tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS) # Garante que a animação rode no pause
	$Placa.scale = Vector2.ZERO
	tween.tween_property($Placa, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK)

func _fechar_e_retornar():
	# 1. Verificamos se o nó ainda está na árvore antes de acessar o tree
	if is_inside_tree():
		get_tree().paused = false 
	
	visible = false

func _on_btn_sim_pressed():
	resposta.emit(true)
	_fechar_e_retornar()

func _on_btn_nao_pressed():
	resposta.emit(false)
	_fechar_e_retornar()

func _on_btn_ok_pressed():
	resposta.emit(true)
	_fechar_e_retornar()
