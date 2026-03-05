extends Node2D

@onready var container_armas = $ArmasContainer
@onready var area_alvo = $AreaAlvo
@onready var feedback_label = $FeedbackLabel
@onready var esteira = $Esteira

var velocidade = 350.0
var armas_na_fila = []
var acertos = 0
var total_pecas = 0
var teclas = ["W", "A", "S", "D"]
var CENTRO_TELA = Vector2(450, 450)

func _ready():
	var lista_nomes = Global.armas_na_esteira_atual
	total_pecas = lista_nomes.size()
	area_alvo.position = Vector2(450, 380)

	
	if total_pecas == 0:
		get_tree().change_scene_to_file("res://scene/Main.tscn")
		return

	for i in range(total_pecas):
		var nome = lista_nomes[i]
		var sprite = Sprite2D.new()
		
		var dados = Global.pecas_disponiveis.filter(func(p): return p.nome == nome)[0]
		sprite.texture = load(dados.caminho_textura)
		
		sprite.position = Vector2(1000 + (i * 300), esteira.position.y+25)
		
		# Configura Tecla WASD
		var tecla_sorteada = teclas[randi() % teclas.size()]
		sprite.set_meta("tecla", tecla_sorteada)
		
		# Texto visual da tecla
		var lbl = Label.new()
		lbl.text = tecla_sorteada
		lbl.position = Vector2(-15, -60)
		sprite.add_child(lbl)
		
		container_armas.add_child(sprite)
		armas_na_fila.append(sprite)

func preparar_esteira(nomes_armas: Array):
	total_pecas = nomes_armas.size()
	
	for i in range(total_pecas):
		var sprite = Sprite2D.new()
		sprite.position = Vector2(950 + (i * 300), CENTRO_TELA.y)
	
		container_armas.add_child(sprite)
		armas_na_fila.append(sprite)

func _process(delta):
	for arma in armas_na_fila:
		arma.position.x -= velocidade * delta
		if arma.position.x < area_alvo.position.x - 100:
			_remover_arma(arma, false)

func _input(event):
	if event is InputEventKey and event.is_pressed():
		var tecla_pressionada = OS.get_keycode_string(event.get_keycode_with_modifiers())
		_checar_batida(tecla_pressionada)

func _checar_batida(tecla):
	for arma in armas_na_fila:
		var dist = abs(arma.position.x - area_alvo.position.x)
		if dist < 60.0:
			if arma.get_meta("tecla") == tecla:
				acertos += 1
				feedback_label.text = "PERFEITO!"
				feedback_label.modulate = Color.GREEN
				_remover_arma(arma, true)
			else:
				feedback_label.text = "ERROU A TECLA!"
				feedback_label.modulate = Color.RED
				_remover_arma(arma, false)
			return

func _remover_arma(arma, sucesso):
	armas_na_fila.erase(arma)
	# Efeito simples de sumir
	var t = create_tween()
	t.tween_property(arma, "modulate:a", 0.0, 0.2)
	t.tween_callback(arma.queue_free)
	
	if armas_na_fila.size() == 0:
		_finalizar_dia_e_voltar()

func _finalizar_dia_e_voltar():
	Global.ultimo_desempenho_ritmo = float(acertos) / total_pecas
	get_tree().change_scene_to_file("res://scene/Cena_1.tscn")
