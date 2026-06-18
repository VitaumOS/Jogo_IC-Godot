extends CanvasLayer

signal dialogo_iniciado
signal dialogo_encerrado
signal fala_completada(indice: int)

@onready var retrato_sprite = $RetratoControl/RetratoSprite
@onready var nome_label = $Control/NomeLabel
@onready var texto_label = $Control/TextoLabel
@onready var seta_passar = $SetaPassar

# Variáveis de controle
var _lista_falas: Array = []
var _indice_atual: int = 0
var _esta_digitando: bool = false
var _tween_digitacao: Tween

func _ready():

	visible = false
	seta_passar.visible = false
	process_mode = PROCESS_MODE_ALWAYS

## Função principal para iniciar uma sequência de diálogo
func iniciar_dialogo(falas: Array):
	if falas.is_empty():
		return
		
	_lista_falas = falas
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
	nome_label.text = fala.get("nome", "???")
	if fala.has("retrato"):
		retrato_sprite.texture = fala["retrato"]
		retrato_sprite.visible = true
	else:
		retrato_sprite.visible = false

	texto_label.bbcode_text = fala.get("texto", "")
	seta_passar.visible = false
	_iniciar_digitacao()

func _iniciar_digitacao():
	_esta_digitando = true
	texto_label.visible_characters = 0
	
	var total_caracteres = texto_label.get_total_character_count()
	var duracao = total_caracteres * 0.04 # 0.04 segundos por letra
	
	_tween_digitacao = create_tween()
	_tween_digitacao.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_tween_digitacao.tween_property(texto_label, "visible_characters", total_caracteres, duracao)
	_tween_digitacao.finished.connect(_on_digitacao_finalizada)

func _pular_digitacao():
	if _tween_digitacao and _tween_digitacao.is_running():
		_tween_digitacao.kill() 
	
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

func _encerrar_dialogo():
	visible = false
	get_tree().paused = false
	dialogo_encerrado.emit()
