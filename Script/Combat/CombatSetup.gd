## CombatSetup.gd
## Monta o combate quando a cena Combat abre:
##  - cria o baralho inicial no DeckManager
##  - configura o jogador (Combatant) e o inimigo (Enemy)
##  - conecta a HUD e inicia a CombatStateMachine
##
## Os campos abaixo podem ser preenchidos no Inspector. Se ficarem VAZIOS,
## o setup carrega um baralho e um inimigo padrão automaticamente — assim a
## cena já funciona "de fábrica", sem precisar arrastar nada manualmente.
extends Node

## Cartas do baralho inicial (opcional: arraste .tres no Inspector).
@export var baralho_inicial: Array[CardData] = []

## Dados do inimigo (opcional: arraste um EnemyData no Inspector).
@export var dados_inimigo: EnemyData

# Caminhos dos recursos padrão (usados quando o Inspector está vazio).
const CARTA_GOLPE := "res://Resources/Cards/golpe_de_luz.tres"
const CARTA_EGIDE := "res://Resources/Cards/egide.tres"
const CARTA_PRECE := "res://Resources/Cards/prece.tres"
const INIMIGO_PADRAO := "res://Resources/Enemies/geleko.tres"

@onready var jogador: Combatant = $"../Jogador"
@onready var inimigo: Enemy = $"../Inimigo"
@onready var maquina: CombatStateMachine = $"../CombatStateMachine"
@onready var hud: Control = $"../HUD_Root"


func _ready() -> void:
	# 1) Baralho: usa o do Inspector ou monta o padrão da Devota da Aurora.
	if baralho_inicial.is_empty():
		baralho_inicial = _construir_baralho_padrao()
	DeckManager.definir_baralho(baralho_inicial)

	# 2) Inimigo: usa o do Inspector ou carrega o Geleko padrão.
	if dados_inimigo == null:
		dados_inimigo = load(INIMIGO_PADRAO) as EnemyData
	if inimigo != null and dados_inimigo != null:
		inimigo.aplicar_dados(dados_inimigo)

	# 3) Conecta a HUD.
	if hud != null and hud.has_method("configurar"):
		hud.configurar(jogador, inimigo, maquina)

	# 4) Inicia o combate.
	var lista_inimigos: Array[Combatant] = [inimigo]
	maquina.iniciar_combate(jogador, lista_inimigos)


## Monta o baralho inicial padrão: 5 Golpe de Luz, 4 Égide, 1 Prece.
func _construir_baralho_padrao() -> Array[CardData]:
	var cartas: Array[CardData] = []
	var golpe := load(CARTA_GOLPE) as CardData
	var egide := load(CARTA_EGIDE) as CardData
	var prece := load(CARTA_PRECE) as CardData

	if golpe != null:
		for i in 5:
			cartas.append(golpe)
	if egide != null:
		for i in 4:
			cartas.append(egide)
	if prece != null:
		cartas.append(prece)

	if cartas.is_empty():
		push_warning("CombatSetup: não foi possível carregar as cartas padrão.")
	return cartas
