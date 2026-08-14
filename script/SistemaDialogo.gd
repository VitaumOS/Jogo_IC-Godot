extends CanvasLayer

signal dialogo_iniciado
signal dialogo_encerrado
signal fala_completada(indice: int)

@onready var audio_player: AudioStreamPlayer = $AudioStreamPlayer
@onready var retrato_sprite = $RetratoControl/RetratoSprite
@onready var nome_label = $Control/NomeLabel
@onready var texto_label = $Control/TextoLabel
@onready var seta_passar = $SetaPassar
@onready var background = $Background
@onready var control_classico = $Control
@onready var retrato_control_classico = $RetratoControl
@onready var tela_foco = $TelaFoco

@onready var agrupador_miniatura = $AgrupadorMiniatura
@onready var retrato_sprite_mini = $AgrupadorMiniatura/RetratoSprite_mini
@onready var background_mini = $AgrupadorMiniatura/Background_mini
@onready var control_mini = $AgrupadorMiniatura/Control_mini
@onready var nome_label_mini = $AgrupadorMiniatura/Control_mini/NomeLabel
@onready var texto_label_mini = $AgrupadorMiniatura/Control_mini/TextoLabel

var _lista_falas: Array = []
var _indice_atual: int = 0
var _esta_digitando: bool = false
var _tween_digitacao: Tween

var som_tecla = preload("res://sounds/SFX_RetroSinglev3.wav")

func _ready():
	visible = false
	seta_passar.visible = false
	_esconder_miniaturas()
	process_mode = PROCESS_MODE_ALWAYS

func iniciar_dialogo(falas: Array):
	if falas.is_empty():
		return
		
	_lista_falas = falas.duplicate()
	
	for fala in _lista_falas:
		if fala.has("coordenada") and fala["coordenada"] is Array:
			var arr_coord = fala["coordenada"]
			if arr_coord.size() == 2:
				fala["coordenada"] = Vector2(arr_coord[0], arr_coord[1])
		if fala.has("foco_pos") and fala["foco_pos"] is Array:
			fala["foco_pos"] = Vector2(fala["foco_pos"][0], fala["foco_pos"][1])
		if fala.has("foco_tamanho") and fala["foco_tamanho"] is Array:
			fala["foco_tamanho"] = Vector2(fala["foco_tamanho"][0], fala["foco_tamanho"][1])
				
	_indice_atual = 0
	visible = true
	get_tree().paused = true
	
	dialogo_iniciado.emit()
	_exibir_fala_atual()

func _input(event):
	if visible and (event.is_action_pressed("ui_accept") or (event is InputEventMouseButton and event.pressed)):
		if _esta_digitando:
			_pular_digitacao()
		else:
			_avancar_dialogo()

func _exibir_fala_atual():
	var fala = _lista_falas[_indice_atual]
	var tem_coordenada = fala.has("coordenada") and fala["coordenada"] is Vector2
	seta_passar.visible = false
	
	if fala.has("foco_pos") and fala.has("foco_tamanho"):
		var mat = tela_foco.material as ShaderMaterial
		if mat:
			mat.set_shader_parameter("posicao_foco", fala["foco_pos"])
			mat.set_shader_parameter("tamanho_foco", fala["foco_tamanho"])
		tela_foco.visible = true
	else:
		tela_foco.visible = false

	if tem_coordenada:
		_mostrar_miniaturas()
		control_classico.visible = false
		retrato_control_classico.visible = false
		background.visible = false
		
		agrupador_miniatura.global_position = fala["coordenada"]
		
		nome_label_mini.text = fala.get("nome", "???")
		texto_label_mini.bbcode_text = fala.get("texto", "")
		retrato_sprite_mini.texture = load(fala["retrato"]) if fala["retrato"] is String else fala["retrato"]

		_iniciar_digitacao(texto_label_mini)
	else:
		_esconder_miniaturas()
		control_classico.visible = true
		retrato_control_classico.visible = true
		background.visible = true
		
		nome_label.text = fala.get("nome", "???")
		retrato_sprite.texture = load(fala["retrato"]) if fala["retrato"] is String else fala["retrato"]

		texto_label.bbcode_text = fala.get("texto", "")
		_iniciar_digitacao(texto_label)

func _iniciar_digitacao(label_alvo: RichTextLabel):
	_esta_digitando = true
	texto_label.visible_characters = 0
	texto_label_mini.visible_characters = 0
	
	var total_caracteres = label_alvo.get_total_character_count()
	
	var delay_caractere = Global.get_delay_caractere() if Global.has_method("get_delay_caractere") else 0.03
	
	if delay_caractere <= 0.0:
		label_alvo.visible_characters = total_caracteres
		_on_digitacao_finalizada()
		return

	var duracao = total_caracteres * delay_caractere
	
	_tween_digitacao = create_tween()
	_tween_digitacao.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_tween_digitacao.tween_property(label_alvo, "visible_characters", total_caracteres, duracao)
	_tween_digitacao.finished.connect(_on_digitacao_finalizada)
	
	var caracteres_antigos = 0
	while _esta_digitando:
		var chars_atuais = label_alvo.visible_characters
		if chars_atuais > caracteres_antigos:
			var texto_atual = label_alvo.text
			if chars_atuais <= texto_atual.length():
				var char_atual = texto_atual[chars_atuais - 1]
				if char_atual != " " and char_atual != "\n":
					audio_player.stream = som_tecla
					audio_player.play()
			caracteres_antigos = chars_atuais
		await get_tree().process_frame

func _pular_digitacao():
	if _tween_digitacao and _tween_digitacao.is_running():
		_tween_digitacao.kill()
	
	var fala = _lista_falas[_indice_atual]
	if fala.has("coordenada") and fala["coordenada"] is Vector2:
		texto_label_mini.visible_characters = texto_label_mini.get_total_character_count()
	else:
		texto_label.visible_characters = texto_label.get_total_character_count()
		
	_on_digitacao_finalizada()

func _on_digitacao_finalizada():
	_esta_digitando = false
	seta_passar.visible = true
	fala_completada.emit(_indice_atual)

func _avancar_dialogo():
	_indice_atual += 1
	if _indice_atual < _lista_falas.size():
		_exibir_fala_atual()
	else:
		_encerrar_dialogo()

func _esconder_miniaturas():
	retrato_sprite_mini.visible = false
	background_mini.visible = false
	control_mini.visible = false
	
func _mostrar_miniaturas():
	retrato_sprite_mini.visible = true
	background_mini.visible = true
	control_mini.visible = true

func _encerrar_dialogo():
	visible = false
	_esconder_miniaturas()
	control_classico.visible = true
	retrato_control_classico.visible = true
	get_tree().paused = false
	dialogo_encerrado.emit()
