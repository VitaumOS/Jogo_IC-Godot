extends Control

const CENA_PRINCIPAL = "res://scene/Cena_1.tscn"

func _ready():
	get_tree().paused = false
	$MenuBotoes/BtnJogar.grab_focus()
	_animar_entrada()

func _animar_entrada():
	$LogoJogo.modulate.a = 0
	var tween = create_tween()
	tween.tween_property($LogoJogo, "modulate:a", 1.0, 1.5).set_trans(Tween.TRANS_SINE)

func _on_btn_jogar_pressed():
	Global.dia_atual = 1
	Global.cena_main = true
	Global.contratos_concluidos.clear()
	get_tree().change_scene_to_file(CENA_PRINCIPAL)

func _on_btn_opcoes_pressed():
	print("Abrindo Opções...")

func _on_btn_sair_pressed():
	get_tree().quit()
