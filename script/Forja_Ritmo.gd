extends Node2D

@export var cena_peca_ritmo: PackedScene

@onready var container_armas = $ArmasContainer
@onready var area_alvo = $AreaAlvo
@onready var feedback_label = $FeedbackLabel
@onready var esteira = $Esteira
@onready var cont = $Contador

var velocidade_base = 350.0
var velocidade_atual = 0.0
var espacamento_base = 320.0

var armas_na_fila = []
var acertos = 0
var total_pecas = 0
var teclas = ["W", "A", "S", "D"]

func _ready():
	var lista_nomes = Global.armas_na_esteira_atual
	total_pecas = lista_nomes.size()
	_atualiza_contador()
	
	# Dificuldade progressiva baseada no dia
	var multiplicador = 1.0 + (Global.dia_atual - 1) * 0.20
	velocidade_atual = velocidade_base * multiplicador
	var espacamento_dia = espacamento_base / (1.0 + (Global.dia_atual - 1) * 0.1)

	if total_pecas == 0:
		get_tree().change_scene_to_file("res://scene/Cena_1.tscn")
		return

	for i in range(total_pecas):
		var container_peca = cena_peca_ritmo.instantiate()
		
		# Sprite da Arma
		var sprite_arma = container_peca.get_node("Arma")
		var filtro = Global.pecas_disponiveis.filter(func(p): return p.nome == lista_nomes[i])
		if not filtro.is_empty():
			sprite_arma.texture = load(filtro[0].caminho_textura)
		
		var lbl = container_peca.get_node("AreaLetra").get_node("Letra")
		var tecla_sorteada = teclas[randi() % teclas.size()]
		lbl.text = tecla_sorteada

		container_peca.get_node("AreaLetra").set_meta("tecla", tecla_sorteada)
		var arma_posy = $ArmasContainer/PecaRitmo.position
		container_peca.position = Vector2(1000 + (i * espacamento_dia), arma_posy.y)
		container_armas.add_child(container_peca)
		armas_na_fila.append(container_peca)

func _process(delta):
	for peca in armas_na_fila:
		peca.position.x -= velocidade_atual * delta
		if peca.position.x < area_alvo.position.x - 150:
			_remover_arma(peca)

func _input(event):
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		var tecla_pressionada = OS.get_keycode_string(event.get_keycode_with_modifiers())
		if tecla_pressionada in teclas:
			_checar_batida(tecla_pressionada)

func _checar_batida(tecla):
	var areas_no_alvo = area_alvo.get_overlapping_areas()

	for area_letra in areas_no_alvo:
		var peca_container = area_letra.get_parent()
		if peca_container in armas_na_fila:
			if area_letra.get_meta("tecla") == tecla:
				acertos += 1
				feedback_label.text = "PERFEITO!"
				feedback_label.modulate = Color.GREEN
				_efeito_fade_e_remover(peca_container, true)
				break
			else:
				feedback_label.text = "ERROU!"
				feedback_label.modulate = Color.RED
				_efeito_fade_e_remover(peca_container, false)
				break

func _efeito_fade_e_remover(peca, sucesso):
	armas_na_fila.erase(peca)
	if sucesso: _atualiza_contador()
	
	var tween = create_tween()
	tween.set_parallel(true) # Faz o fade e o movimento ao mesmo tempo
	tween.tween_property(peca, "modulate:a", 0.0, 0.2) # Alpha vai para 0 em 0.2s
	tween.tween_property(peca, "scale", Vector2(1.5, 1.5), 0.2) # Aumenta um pouco
	
	tween.finished.connect(func(): 
		peca.queue_free()
		if armas_na_fila.size() == 0:
			_finalizar_ritmo()
	)

func _remover_arma(peca):
	if peca in armas_na_fila:
		armas_na_fila.erase(peca)
		peca.queue_free()
		if armas_na_fila.size() == 0:
			_finalizar_ritmo()

func _atualiza_contador():
	cont.text = ("%d/%d" %[acertos, total_pecas])

func _finalizar_ritmo():
	Global.ultimo_desempenho_ritmo = float(acertos) / total_pecas if total_pecas > 0 else 0.0
	get_tree().change_scene_to_file("res://scene/Cena_1.tscn")
