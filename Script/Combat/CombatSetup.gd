## CombatSetup.gd
## Monta um combate de teste quando a cena Combat abre:
##  - cria o baralho inicial no DeckManager
##  - configura o jogador (Combatant) e o inimigo (Enemy)
##  - conecta a HUD e inicia a CombatStateMachine
##
## Fica num nó da cena Combat. As referências aos nós são pegas via @onready.
extends Node

## Cartas do baralho inicial (arraste os .tres no Inspector).
@export var baralho_inicial: Array[CardData] = []

## Dados do inimigo deste encontro (arraste geleko.tres no Inspector).
@export var dados_inimigo: EnemyData

@onready var jogador: Combatant = $"../Jogador"
@onready var inimigo: Enemy = $"../Inimigo"
@onready var maquina: CombatStateMachine = $"../CombatStateMachine"
@onready var hud: Control = $"../HUD_Root"


func _ready() -> void:
	# 1) Monta o baralho da run.
	if baralho_inicial.is_empty():
		push_warning("CombatSetup: baralho_inicial vazio — adicione cartas no Inspector.")
	DeckManager.definir_baralho(baralho_inicial)

	# 2) Aplica os dados ao inimigo (caso não tenha sido setado direto no nó).
	if dados_inimigo != null and inimigo != null:
		inimigo.dados = dados_inimigo

	# 3) Conecta a HUD.
	if hud != null and hud.has_method("configurar"):
		hud.configurar(jogador, inimigo, maquina)

	# 4) Inicia o combate (jogador vs. lista de inimigos).
	var lista_inimigos: Array[Combatant] = [inimigo]
	maquina.iniciar_combate(jogador, lista_inimigos)
