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
	
	Global._verificar_gatilho_tutorial("dia_final")
	_mostrar_tela_vitoria()

func _mostrar_tela_vitoria():
	titulo_vitoria.visible = true
	titulo_vitoria.modulate.a = 0
	var tw = create_tween()
	tw.tween_property(titulo_vitoria, "modulate:a", 1.0, 2.0)
	botao_voltar.visible = true
	botao_voltar.modulate.a = 0
	tw.tween_property(botao_voltar, "modulate:a", 1.0, 2.0)
	
func _on_button_pressed(): 
	Global.resetar_jogo()
	get_tree().change_scene_to_file("res://scene/Telainicial.tscn")
