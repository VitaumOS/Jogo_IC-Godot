extends Control

# Preload da cena principal (onde o jogo começa)
const CENA_PRINCIPAL = "res://scene/Cena_1.tscn"

func _ready():
	# Garante que o jogo não comece pausado
	get_tree().paused = false
	
	# Foco inicial no botão jogar para suporte a controle/teclado
	$MenuBotoes/BtnJogar.grab_focus()
	
	# Animação de entrada do Logo (opcional)
	_animar_entrada()

func _animar_entrada():
	$LogoJogo.modulate.a = 0
	var tween = create_tween()
	tween.tween_property($LogoJogo, "modulate:a", 1.0, 1.5).set_trans(Tween.TRANS_SINE)

# --- Conexões de Sinais ---

func _on_btn_jogar_pressed():
	# Antes de ir para a cena, podemos resetar os dados globais
	Global.dia_atual = 1
	Global.dinheiro = 500
	Global.contratos_concluidos.clear()
	
	get_tree().change_scene_to_file(CENA_PRINCIPAL)

func _on_btn_opcoes_pressed():
	# Aqui você poderia instanciar seu Popup de opções
	print("Abrindo Opções...")

func _on_btn_sair_pressed():
	get_tree().quit()
