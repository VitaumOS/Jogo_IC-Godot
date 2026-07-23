extends CanvasLayer

signal resposta(valor: bool)

@onready var label_mensagem = $Control2/Mensagem
@onready var label_titulo = $Control2/Titulo
@onready var btn_sim = $Control/HBoxBtn/BtnSim
@onready var btn_nao = $Control/HBoxBtn/BtnNao
@onready var btn_ok = $Control/HBoxBtn/BtnOk

func _ready():
	visible = false

func mostrar_mensagem_erro(texto: String):
	
	label_mensagem.text = texto
	label_titulo.visible = true
	btn_sim.visible = false
	btn_nao.visible = false
	btn_ok.visible = true
	_abrir()

## Função para apenas exibir uma mensagem com botão OK
func mostrar_mensagem(texto: String):
	label_mensagem.text = texto
	label_titulo.visible = false
	btn_sim.visible = false;btn_nao.visible = false;btn_ok.visible = true
	_abrir()

func mostrar_conclusao_contrato():
	label_mensagem.text = "Contrato Concluído! Ganhou: R$%.2f" % Global.recompensa_final
	label_titulo.visible = false
	btn_sim.visible = false;btn_nao.visible = false;btn_ok.visible = true
	_abrir()

## Função para confirmação (Sim ou Não)
func mostrar_confirmacao(texto: String):
	label_mensagem.text = texto
	label_titulo.visible = false
	btn_sim.visible = true;btn_nao.visible = true;btn_ok.visible = false
	_abrir()

func _abrir():
	visible = true
	get_tree().paused = true 
	
	var tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	$Placa.scale = Vector2.ZERO
	tween.tween_property($Placa, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK)

func _fechar_e_retornar():
	visible = false
	get_tree().paused = false

func _on_btn_sim_pressed():
	_fechar_e_retornar()
	resposta.emit(true)

func _on_btn_nao_pressed():
	_fechar_e_retornar()
	resposta.emit(false)

func _on_btn_ok_pressed():
	_fechar_e_retornar()
	resposta.emit(true)
