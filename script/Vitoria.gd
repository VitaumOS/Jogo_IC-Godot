extends Control

@onready var label_transicao = $CanvasLayer/LabelDia 
@onready var titulo_vitoria = $CanvasLayer/TituloVitoria
@onready var botao_voltar = $Button

func _ready():
	titulo_vitoria.visible = false
	botao_voltar.visible = false
	label_transicao.modulate.a = 0
	_sequencia_final()

func _sequencia_final():
	label_transicao.text = "DIA 8\nO Retorno do Mestre"
	var tween = create_tween()
	tween.tween_property(label_transicao, "modulate:a", 1.0, 1.0)
	await get_tree().create_timer(3.0).timeout
	create_tween().tween_property(label_transicao, "modulate:a", 0.0, 0.5)
	await get_tree().create_timer(0.5).timeout
	
	_dialogo_mestre_gato()

func _dialogo_mestre_gato():
	var falas = [
		{
			"nome": "Mestre Gato",
			"texto": "Jorge! Voltei da minha jornada pelos reinos distantes. Como estão os negócios?",
			"retrato": load("res://Sprite/gatinhos/Ferreiro.png")
		},
		{
			"nome": "Jorge",
			"texto": "Miau! Mestre! Foi uma semana intensa... usei matemática pesada e cortes precisos para manter tudo em ordem!",
			"retrato": load("res://Sprite/gatinhos/NekoJorge.png")
		},
		{
			"nome": "Mestre Gato",
			"texto": "Estou impressionado. Vejo que o saldo está positivo e os contratos foram cumpridos. Você provou ser um verdadeiro mestre da otimização!",
			"retrato": load("res://Sprite/gatinhos/Ferreiro.png")
		}
	]
	
	var sistema = get_tree().root.find_child("SistemaDialogo", true, false)
	if sistema:
		sistema.iniciar_dialogo(falas)
		sistema.dialogo_encerrado.connect(_mostrar_tela_vitoria)
	else:
		_mostrar_tela_vitoria()

func _mostrar_tela_vitoria():
	titulo_vitoria.visible = true
	titulo_vitoria.modulate.a = 0
	var tw = create_tween()
	tw.tween_property(titulo_vitoria, "modulate:a", 1.0, 2.0)
	botao_voltar.visible = true
	botao_voltar.modulate.a = 0
	tw.tween_property(botao_voltar, "modulate:a", 1.0, 2.0)
	
func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scene/telainicial.tscn")
