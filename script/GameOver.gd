extends Control

@onready var titulo_faliu = $TituloFaliu 
@onready var btn_voltar = $HB/BtnVoltar
@onready var btn_recomecar_dia = $HB/BtnRecomecarDia
@onready var popup = $PopUp

func _ready():
	titulo_faliu.modulate.a = 0
	
	btn_voltar.visible = false
	btn_voltar.disabled = true
	
	if btn_recomecar_dia:
		btn_recomecar_dia.visible = false
		btn_recomecar_dia.disabled = true
	
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
	sistema_dialogo.iniciar_dialogo(fala_derrota)
	sistema_dialogo.dialogo_encerrado.connect(_mostrar_botao_final, CONNECT_ONE_SHOT)


func _mostrar_botao_final():
	var tween = create_tween().set_parallel(true)
	
	btn_voltar.visible = true
	btn_voltar.disabled = false
	btn_voltar.modulate.a = 0
	tween.tween_property(btn_voltar, "modulate:a", 1.0, 0.5)
	
	if btn_recomecar_dia:
		btn_recomecar_dia.visible = true
		btn_recomecar_dia.disabled = false
		btn_recomecar_dia.modulate.a = 0
		tween.tween_property(btn_recomecar_dia, "modulate:a", 1.0, 0.5)

func _on_btn_recomecar_dia_pressed():
	Global.desistir_e_reiniciar_dia()

func _on_btn_voltar_pressed():

	popup.mostrar_confirmacao("Atenção: Todo o progresso salvo na sessão será perdido! Deseja voltar ao Menu Inicial?")
	var confirma = await popup.resposta
	if confirma:
		Global.resetar_jogo()
		get_tree().change_scene_to_file("res://scene/Telainicial.tscn")
