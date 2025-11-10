# Piece.gd
class_name PieceScript
extends Node2D

# Sinais
signal peca_removida(script_peca) 

# Referência de Nó
@onready var visual_sprite: Sprite2D = $VisualSprite

# Variáveis 
var arrastando: bool = false
var esta_no_container: bool = false
var deslocamento_arrasto: Vector2 = Vector2.ZERO
var posicao_original: Vector2 

# Propriedades da Peça
var largura_peca: float = 50.0      
var comprimento_peca: float = 50.0  
var caminho_textura: String = ""


# Construtor
func _init(largura: float = 50.0, comprimento: float = 50.0, caminho: String = ""):
	largura_peca = largura
	comprimento_peca = comprimento
	caminho_textura = caminho
	
	set_process(true)

func _ready():
	#Carrega e atribui a textura
	if caminho_textura:
		var textura_carregada = load(caminho_textura)
		visual_sprite.texture = textura_carregada
		
	#Redimensiona o Sprite 
	if visual_sprite.texture:
		var tamanho_textura = visual_sprite.texture.get_size()
		visual_sprite.scale = Vector2(largura_peca / tamanho_textura.x, comprimento_peca / tamanho_textura.y)
	# 3. Centraliza o sprite
	visual_sprite.position = Vector2(largura_peca / 2.0, comprimento_peca / 2.0)


func _input(event: InputEvent):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var posicao_mouse = get_global_mouse_position()
		var retangulo_peca = Rect2(global_position, Vector2(largura_peca, comprimento_peca))
		if retangulo_peca.has_point(posicao_mouse):
			if event.pressed:
				# Início do clique
				if esta_no_container: 
					emit_signal("peca_removida", self) 
					queue_free()
				else:
					# Inicia o arrasto
					arrastando = true 
					deslocamento_arrasto = global_position - posicao_mouse
			elif arrastando:
				# Fim do arrasto: Tenta encaixar
				arrastando = false 
				var no_principal = get_tree().get_first_node_in_group("main_logic")
				if no_principal:
					no_principal._tentar_encaixar_peca(self)
func _process(delta):
	if arrastando:
		global_position = get_global_mouse_position() + deslocamento_arrasto # <--- ACESSO CORRIGIDO
