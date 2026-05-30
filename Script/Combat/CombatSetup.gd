## CombatSetup.gd
## Monta o combate quando a cena Combat abre:
##  - cria o baralho inicial no DeckManager
##  - configura o jogador (Combatant) e o inimigo (Enemy)
##  - conecta a HUD e a mão de cartas (Hand)
##  - inicia a CombatStateMachine
##
## Os campos abaixo podem ser preenchidos no Inspector. Se ficarem VAZIOS,
## o setup carrega um baralho e um inimigo padrão automaticamente.
extends Node

## Cartas do baralho inicial (opcional: arraste .tres no Inspector).
@export var baralho_inicial: Array[CardData] = []

## Dados do inimigo (opcional: arraste um EnemyData no Inspector).
@export var dados_inimigo: EnemyData

# Baralho inicial padrão do Espadachin (estilo Slay the Spire):
# 5 Corte, 4 Defender, 1 Quebra-Guarda.
const DECK_PADRAO := {
	"res://Resources/Cards/corte.tres": 5,
	"res://Resources/Cards/defender.tres": 4,
	"res://Resources/Cards/quebra_guarda.tres": 1,
}
const INIMIGO_PADRAO := "res://Resources/Enemies/geleko.tres"
const HAND_SCRIPT := "res://Script/Combat/Hand.gd"

@onready var jogador: Combatant = $"../Jogador"
@onready var inimigo: Enemy = $"../Inimigo"
@onready var maquina: CombatStateMachine = $"../CombatStateMachine"
@onready var hud: Control = $"../HUD_Root"


func _ready() -> void:
	# 1) Baralho: usa o do Inspector ou monta o padrão do Espadachin.
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

	# 4) Cria a mão de cartas clicáveis e a adiciona à UI.
	_criar_mao()

	# 5) Inicia o combate (isto compra a primeira mão e dispara a UI).
	var lista_inimigos: Array[Combatant] = [inimigo]
	maquina.iniciar_combate(jogador, lista_inimigos)


## Instancia o nó da mão (Hand.gd) dentro da camada de UI e o configura.
func _criar_mao() -> void:
	if hud == null:
		return
	var mao := Control.new()
	mao.name = "Mao"
	mao.set_script(load(HAND_SCRIPT))
	hud.add_child(mao)        # dispara o _ready do Hand (conecta aos sinais).
	if mao.has_method("configurar"):
		mao.configurar(maquina, inimigo)


## Monta o baralho inicial padrão a partir do dicionário DECK_PADRAO.
func _construir_baralho_padrao() -> Array[CardData]:
	var cartas: Array[CardData] = []
	for caminho in DECK_PADRAO:
		var carta := load(caminho) as CardData
		if carta != null:
			for i in DECK_PADRAO[caminho]:
				cartas.append(carta)
	if cartas.is_empty():
		push_warning("CombatSetup: não foi possível carregar as cartas padrão.")
	return cartas
