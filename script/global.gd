extends Node

const CUSTO_DIARIO = 200
const DIA_FINAL: int = 7
const DINHEIRO_INICIAL: int = 1500

var tamanho_container: float = 500.0
var dia_atual: int = 1
var dinheiro: int = DINHEIRO_INICIAL
var dinheiro_inicio_do_dia: int = DINHEIRO_INICIAL
var estoque_chapas: int = 0
var estoque_chapas_inicio_do_dia: int = 0 # Salva as chapas do início do dia
var ganhos_do_dia: int = 0
var preco_chapa: int = 100 

enum VelocidadeTexto { LENTA, MEDIA, INSTANTANEA }

var som_mutado: bool = false
var velocidade_dialogo: VelocidadeTexto = VelocidadeTexto.MEDIA

var recompensa_base: float = 0
var recompensa_final: float = 0

var cena_main = false
var cena_loja = false
var cena_contrato = false

var alcancou_metas_contrato: bool = false
var fez_contrato_diario: bool = false
var upgrade_todos_padroes_comprado: bool = false
var finalizou_treino = false 
var finalizou_primeiro_contrato = false
var finalizou_tutorial_primeiro_contrato = false
var finalizou_tutorial_forja = false
var alcancou_primeiro_minimo: bool = false

var chapas_usadas_pelo_jogador: int = 0
var ultimo_desempenho_ritmo: float = -1.0 

var pecas_disponiveis: Array = [
	{"nome": "Adaga", "largura": 53.0, "caminho_textura": "res://Sprite/adaga-novo.png"},
	{"nome": "Espada M", "largura": 87.0, "caminho_textura": "res://Sprite/Esp_Larg-novo.png"},
	{"nome": "Espada G", "largura": 123.0, "caminho_textura": "res://Sprite/Esp_Grande-novo.png"},
	{"nome": "Machado", "largura": 89.0, "caminho_textura": "res://Sprite/machado-novo.png"},
	{"nome": "Maça", "largura": 89.0, "caminho_textura": "res://Sprite/maca.png"},
	{"nome": "Lança", "largura": 143.0, "caminho_textura": "res://Sprite/lanca-novo.png"}
]

var dialogos_vistos_hoje: Dictionary = {}

var contratos_disponiveis: Array = []
var padroes_na_loja: Array = []
var armas_na_esteira_atual: Array = []
var padroes_desbloqueados: Array = []
var contratos_concluidos: Array = []

var contrato_ativo = null

func _ready():
	gerar_conteudo_do_dia()

## Reseta o dia atual devolvendo o dinheiro e chapas iniciais + R$ 500 de bônus
func desistir_e_reiniciar_dia():
	dinheiro = dinheiro_inicio_do_dia + 500
	estoque_chapas = estoque_chapas_inicio_do_dia # Restaura o estoque de chapas do início do dia
	ganhos_do_dia = 0
	contrato_ativo = null
	
	if has_meta("quantidades_padroes_salvas"):
		remove_meta("quantidades_padroes_salvas")
		
	gerar_conteudo_do_dia()
	get_tree().change_scene_to_file("res://scene/Cena_1.tscn")

func resetar_jogo():
	dia_atual = 1; dinheiro = DINHEIRO_INICIAL; dinheiro_inicio_do_dia = DINHEIRO_INICIAL;
	estoque_chapas = 0; estoque_chapas_inicio_do_dia = 0; ganhos_do_dia = 0;
	recompensa_base = 0; recompensa_final = 0;
	cena_main = false; cena_loja = false; cena_contrato = false;
	alcancou_metas_contrato = false
	fez_contrato_diario = false
	upgrade_todos_padroes_comprado = false
	finalizou_treino = false
	finalizou_primeiro_contrato = false
	finalizou_tutorial_primeiro_contrato = false
	finalizou_tutorial_forja = false
	alcancou_primeiro_minimo = false
	chapas_usadas_pelo_jogador = 0
	ultimo_desempenho_ritmo = -1.0
	dialogos_vistos_hoje.clear()
	contratos_disponiveis.clear()
	padroes_na_loja.clear()
	armas_na_esteira_atual.clear()
	padroes_desbloqueados.clear()
	contratos_concluidos.clear()
	contrato_ativo = null
	if has_meta("tutoriais_vistos"):
		remove_meta("tutoriais_vistos")
	gerar_conteudo_do_dia()

var cena_anterior: String = "res://scene/TelaInicial.tscn"

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		var cena_atual = get_tree().current_scene
		
		if cena_atual.name != "res://scene/Forja_Ritmo.tscn":
			if cena_atual.scene_file_path != "res://scene/Opcoes.tscn":
				cena_anterior = cena_atual.scene_file_path
				get_tree().change_scene_to_file("res://scene/Opcoes.tscn")

## Retorna o tempo de atraso (delay) entre cada letra em segundos
func get_delay_caractere() -> float:
	match velocidade_dialogo:
		VelocidadeTexto.LENTA:
			return 0.08
		VelocidadeTexto.MEDIA:
			return 0.03
		VelocidadeTexto.INSTANTANEA:
			return 0.0
		_:
			return 0.03
			
## Alterna o áudio principal do jogo
func definir_mute_som(mutado: bool) -> void:
	som_mutado = mutado
	var bus_index = AudioServer.get_bus_index("Master")
	AudioServer.set_bus_mute(bus_index, mutado)

## Verifica se todos os contratos gerados para o dia atual foram concluídos
func todos_contratos_concluidos() -> bool:
	if contratos_disponiveis.is_empty():
		return true
	for c in contratos_disponiveis:
		if not contratos_concluidos.has(c):
			return false
	return true

## Função adaptada para encontrar e rodar o diálogo na cena atual
func _verificar_gatilho_tutorial(chave_tutorial: String) -> void:
	if not Global.has_meta("tutoriais_vistos"):
		Global.set_meta("tutoriais_vistos", {})
		
	var tutoriais_vistos = Global.get_meta("tutoriais_vistos")
	
	if not tutoriais_vistos.has(chave_tutorial):
		tutoriais_vistos[chave_tutorial] = true 
		Global.set_meta("tutoriais_vistos", tutoriais_vistos)
		
		var todos_dialogos = _carregar_json("res://data_json/dialogos.json")
		
		if todos_dialogos.has(chave_tutorial):
			var falas_do_tutorial = todos_dialogos[chave_tutorial]
			
			if has_node("/root/Dialogo"):
				for fala in falas_do_tutorial:
					if fala.has("retrato") and fala["retrato"] is String:
						fala["retrato"] = load(fala["retrato"])
				Dialogo.iniciar_dialogo(falas_do_tutorial)

func registrar_contrato_concluido(contrato):
	if not contratos_concluidos.has(contrato):
		contratos_concluidos.append(contrato)

func deve_exibir_dialogo_do_dia() -> bool:
	if not dialogos_vistos_hoje.has(dia_atual):
		dialogos_vistos_hoje[dia_atual] = true
		return true
	return false

## Função para consumir a chapa
func usar_chapa_extra():
	if estoque_chapas > 0:
		estoque_chapas -= 1
		return true
	return false
	
## Gera novos contratos e padrões aleatórios
func gerar_conteudo_do_dia():
	contratos_disponiveis.clear()
	contratos_concluidos.clear()
	padroes_na_loja.clear()
	
	# Salva os recursos do início do dia
	dinheiro_inicio_do_dia = dinheiro
	estoque_chapas_inicio_do_dia = estoque_chapas
	
	var dados_contratos = _carregar_json("res://data_json/contratos.json")
	var dados_padroes = _carregar_json("res://data_json/padroes.json")

	var contratos_possiveis = dados_contratos.get("contratos", []).filter(func(c): return c.dia == dia_atual)
	var padroes_possiveis = dados_padroes.get("padroes", []).filter(func(p): return p.dia <= dia_atual)
	
	contratos_possiveis.shuffle()
	for i in contratos_possiveis:
		contratos_disponiveis.append(i)
	padroes_possiveis.shuffle()
	for i in padroes_possiveis:
		padroes_na_loja.append(i)

## Função auxiliar para ler qualquer arquivo JSON
func _carregar_json(caminho: String) -> Dictionary:
	var arquivo = FileAccess.open(caminho, FileAccess.READ)
	if not arquivo:
		return {}
	var conteudo = arquivo.get_as_text()
	var json = JSON.new()
	var erro = json.parse(conteudo)
	
	if erro == OK:
		return json.data
	else:
		return {}

## Função chamada quando o jogador resolve o PCU com sucesso
func completar_contrato(conseguiu_minimo: bool, ritmo : float):
	if contrato_ativo != null:
		var recompensa = contrato_ativo.recompensa
		recompensa_base = contrato_ativo.recompensa
		var bonus = 0.0
		if conseguiu_minimo:
			bonus = recompensa * 0.2
		recompensa = (recompensa / 2.0) + ((recompensa * ritmo) / 2.0) 
		recompensa += bonus
		recompensa_final = recompensa
		dinheiro += recompensa
		ganhos_do_dia += recompensa
		
		registrar_contrato_concluido(contrato_ativo)
		
		contrato_ativo = null
		fez_contrato_diario = true
		return true
	else:
		return false

func adicionar_dinheiro(qtd: int):
	dinheiro += qtd
	ganhos_do_dia += qtd

func remover_dinheiro(qtd: int) -> bool:
	if dinheiro >= qtd:
		dinheiro -= qtd
		return true
	return false

func _criar_icone_arma(peca, tipo_id: int) -> TextureRect:
	var icone = TextureRect.new()
	icone.texture = load(peca.caminho_textura)
	icone.custom_minimum_size = Vector2(50, 50)
	icone.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icone.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icone.set_meta("tipo_id", tipo_id) 
	return icone

## Inicia o próximo dia
func proximo_dia():
	dia_atual += 1
	ganhos_do_dia = 0
	contrato_ativo = null
	gerar_conteudo_do_dia()
	get_tree().change_scene_to_file("res://scene/Cena_1.tscn")
