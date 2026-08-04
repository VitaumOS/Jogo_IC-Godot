extends Node2D

@export var cena_peca_ritmo: PackedScene

@onready var container_armas = $ArmasContainer
@onready var area_alvo = $AreaAlvo
@onready var feedback_label = $FeedbackLabel
@onready var esteira = $Esteira
@onready var cont = $Contador

const VELOCIDADE_BASE = 350.0
const ESPACAMENTO_BASE = 320.0
const TECLAS = ["Up", "Left", "Down", "Right"]
const SIMBOLOS_SETAS = {
	"Up": "↑",
	"Left": "←",
	"Down": "↓",
	"Right": "→"
}

const OFFSET_Y_SEGUNDA_ESTEIRA = 80.0

var velocidade_atual = 0.0
var armas_na_fila = []
var acertos = 0
var total_pecas = 0
var modo_duas_esteiras = false
var em_tutorial: bool = false

# --- VARIÁVEIS DE ÁUDIO ---
var audio_player: AudioStreamPlayer
var som_acerto = preload("res://sounds/blacksmith-hammering_01.wav") 
var som_erro = preload("res://sounds/blacksmith-hammering_01.wav")   

func _ready():
	audio_player = AudioStreamPlayer.new()
	add_child(audio_player)
	
	var lista_nomes = Global.armas_na_esteira_atual
	total_pecas = lista_nomes.size()
	_atualiza_contador()

	modo_duas_esteiras = total_pecas > 30
	_configurar_dificuldade()
	
	if modo_duas_esteiras:
		_duplicar_esteira_fundo()
		
	_inicializar_esteiras(lista_nomes)
	if !Global.finalizou_tutorial_forja:
		_checar_tutorial_forja()

func _checar_tutorial_forja():
	em_tutorial = true
	Global._verificar_gatilho_tutorial("primeira_forja")
	
	var node_dialogo = get_node("/root/Dialogo")
	await node_dialogo.dialogo_encerrado		
	em_tutorial = false
	Global.finalizou_tutorial_forja = true

func _configurar_dificuldade():
	var multiplicador = 1.0 + (Global.dia_atual - 1) * 0.02
	velocidade_atual = VELOCIDADE_BASE * multiplicador

func _duplicar_esteira_fundo():
	var nova_esteira = esteira.duplicate()
	nova_esteira.position.y += OFFSET_Y_SEGUNDA_ESTEIRA
	var pai = esteira.get_parent()
	pai.add_child(nova_esteira)
	pai.move_child(nova_esteira, esteira.get_index() + 1)

func _inicializar_esteiras(lista_nomes: Array):
	var arma_posy = $ArmasContainer/PecaRitmo.position
	var espacamento_dia = ESPACAMENTO_BASE / (1.0 + (Global.dia_atual - 1) * 0.1)

	for i in range(total_pecas):
		var container_peca = cena_peca_ritmo.instantiate()
		_configurar_sprite_arma(container_peca, lista_nomes[i])
		
		var par = (i % 2 == 0) or not modo_duas_esteiras
		var indice_coluna = i / 2 if modo_duas_esteiras else i
		var pos_y = arma_posy.y if par else (arma_posy.y + OFFSET_Y_SEGUNDA_ESTEIRA)
		
		_configurar_input_peca(container_peca, par)
		container_peca.position = Vector2(1000 + (indice_coluna * espacamento_dia), pos_y)
		
		container_armas.add_child(container_peca)
		armas_na_fila.append(container_peca)

func _configurar_sprite_arma(container: Node2D, nome_arma: String):
	var sprite_arma = container.get_node("Arma")
	var filtro = Global.pecas_disponiveis.filter(func(p): return p.nome == nome_arma)
	if not filtro.is_empty():
		sprite_arma.texture = load(filtro[0].caminho_textura)

func _configurar_input_peca(container: Node2D, linha_principal: bool):
	var lbl = container.get_node("AreaLetra/Letra")
	var area_letra = container.get_node("AreaLetra")
	
	if linha_principal:
		var tecla_sorteada = TECLAS[randi() % TECLAS.size()]
		lbl.text = SIMBOLOS_SETAS.get(tecla_sorteada, tecla_sorteada)
		area_letra.set_meta("tecla", tecla_sorteada)
	else:
		lbl.text = ""
		area_letra.set_meta("tecla", "NENHUMA")
		if esteira:
			container.modulate = esteira.modulate

func _process(delta):
	if em_tutorial: return
	
	for peca in armas_na_fila:
		peca.position.x -= velocidade_atual * delta
		if peca.position.x < area_alvo.position.x - 150:
			_remover_par_por_limite(peca)

func _input(event):
	if em_tutorial: return
	
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		var tecla_pressionada = OS.get_keycode_string(event.get_keycode_with_modifiers())
		if tecla_pressionada in TECLAS:
			_checar_batida(tecla_pressionada)

func _checar_batida(tecla: String):
	var areas_no_alvo = area_alvo.get_overlapping_areas()
	areas_no_alvo.sort_custom(func(a, b): return a.global_position.x < b.global_position.x)
	
	for area_letra in areas_no_alvo:
		var peca_container = area_letra.get_parent()
		if not peca_container in armas_na_fila: 
			continue
			
		var tecla_meta = area_letra.get_meta("tecla")
		if tecla_meta == "NENHUMA": 
			continue
			
		if tecla_meta == tecla:
			_processar_resultado(peca_container, true)
		else:
			_processar_resultado(peca_container, false)
		break

func _processar_resultado(peca_principal: Node2D, sucesso: bool):
	if sucesso:
		acertos += 2 if modo_duas_esteiras else 1
		_atualizar_feedback("PERFEITO!", Color.GREEN)
		# Toca som de acerto
		audio_player.stream = som_acerto
		audio_player.play()
	else:
		_atualizar_feedback("ERROU!", Color.RED)
		# Toca som de erro
		audio_player.stream = som_erro
		audio_player.play()
		
	if modo_duas_esteiras:
		_remover_par_de_baixo_associado(peca_principal)
	_efeito_fade_e_remover(peca_principal, sucesso)

func _remover_par_de_baixo_associado(peca_principal: Node2D):
	var idx = armas_na_fila.find(peca_principal)
	if idx != -1 and idx + 1 < armas_na_fila.size():
		var peca_baixo = armas_na_fila[idx + 1]
		if peca_baixo.get_node("AreaLetra").get_meta("tecla") == "NENHUMA":
			_efeito_fade_e_remover(peca_baixo, false)

func _remover_par_por_limite(peca: Node2D):
	var tecla_meta = peca.get_node("AreaLetra").get_meta("tecla")
	if modo_duas_esteiras and tecla_meta != "NENHUMA":
		_remover_par_de_baixo_associado(peca)
		
	armas_na_fila.erase(peca)
	peca.queue_free()
	_verificar_fim_de_jogo()

func _efeito_fade_e_remover(peca: Node2D, incrementar_ui: bool):
	armas_na_fila.erase(peca)
	if incrementar_ui: 
		_atualiza_contador()
	
	var tween = create_tween().set_parallel(true)
	tween.tween_property(peca, "modulate:a", 0.0, 0.2)
	tween.tween_property(peca, "scale", Vector2(1.5, 1.5), 0.2)
	tween.finished.connect(func():
		peca.queue_free()
		_verificar_fim_de_jogo()
	)

func _atualizar_feedback(texto: String, cor: Color):
	feedback_label.text = texto
	feedback_label.modulate = cor

func _atualiza_contador():
	cont.text = "%d/%d" % [acertos, total_pecas]

func _verificar_fim_de_jogo():
	if armas_na_fila.is_empty():
		Global.ultimo_desempenho_ritmo = float(acertos) / total_pecas if total_pecas > 0 else 0.0
		get_tree().change_scene_to_file("res://scene/Cena_1.tscn")
