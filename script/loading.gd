extends Control

@onready var label_processando = $Label

var _pontos: int = 1
var _timer: Timer

func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	_timer = Timer.new()
	_timer.wait_time = 1.0
	_timer.autostart = true
	_timer.timeout.connect(_atualizar_texto)
	add_child(_timer)
	_atualizar_texto()

func _atualizar_texto() -> void:
	var texto = "Processando"
	for i in range(_pontos):
		texto += "."
	if label_processando:
		label_processando.text = texto
	
	_pontos += 1
	if _pontos > 3:
		_pontos = 1
