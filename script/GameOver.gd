extends Control

@onready var titulo_faliu = $TituloFaliu 
@onready var btn_voltar = $BtnVoltar    

func _ready():
	titulo_faliu.modulate.a = 0
	btn_voltar.visible = false
	btn_voltar.disabled = true
	
	_sequencia_game_over()

func _sequencia_game_over():
	create_tween().tween_property(titulo_faliu, "modulate:a", 1.0, 1.5)
	await get_tree().create_timer(3.0).timeout
	
	var fala_derrota = [
		{
			"nome": "Jorge",
			"texto": "[shake rate=20 level=10][color=red]Miau... deu tudo errado![/color][/shake] O Mestre Gato vai me transformar em um tapete quando vir esse saldo de [b]R$ %d[/b]!" % Global.dinheiro,
			"retrato": load("res://Sprite/gatinhos/NekoJorge.png")
		}
	]
	var sistema_dialogo = get_tree().root.find_child("SistemaDialogo", true, false)
	if sistema_dialogo:
		sistema_dialogo.iniciar_dialogo(fala_derrota)
		sistema_dialogo.dialogo_encerrado.connect(_mostrar_botao_final, CONNECT_ONE_SHOT)
	else:
		_mostrar_botao_final()

func _mostrar_botao_final():
	btn_voltar.visible = true
	btn_voltar.disabled = false
	var tween = create_tween()
	btn_voltar.modulate.a = 0
	tween.tween_property(btn_voltar, "modulate:a", 1.0, 0.5)

func _on_btn_voltar_pressed():
	Global.resetar_jogo()
	get_tree().change_scene_to_file("res://scene/Telainicial.tscn")
