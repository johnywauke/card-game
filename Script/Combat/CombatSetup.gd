## CombatSetup.gd
## Monta o combate quando a cena Combat abre:
##  - garante que há uma run em andamento (baralho + HP persistem entre combates)
##  - configura o jogador (Combatant) e o inimigo (Enemy)
##  - conecta a HUD, a mão de cartas (Hand) e a tela de fim de combate
##  - inicia a CombatStateMachine
extends Node

## Dados do inimigo (opcional: arraste um EnemyData no Inspector).
@export var dados_inimigo: EnemyData

const INIMIGO_PADRAO := "res://Resources/Enemies/geleko.tres"
const HAND_SCRIPT := "res://Script/Combat/Hand.gd"
const FIM_SCRIPT := "res://Script/Combat/CombatEndScreen.gd"

@onready var jogador: Combatant = $"../Jogador"
@onready var inimigo: Enemy = $"../Inimigo"
@onready var maquina: CombatStateMachine = $"../CombatStateMachine"
@onready var hud: Control = $"../HUD_Root"


func _ready() -> void:
	# 1) Garante uma run ativa (na primeira vez, monta o baralho do Espadachin).
	if not DeckManager.run_iniciada:
		DeckManager.iniciar_run()

	# 2) Aplica o HP do jogador salvo na run.
	if jogador != null:
		jogador.hp_max = DeckManager.hp_max_jogador
		jogador.hp_atual = DeckManager.hp_jogador

	# 3) Inimigo: usa o do Inspector ou carrega o Geleko padrão.
	if dados_inimigo == null:
		dados_inimigo = load(INIMIGO_PADRAO) as EnemyData
	if inimigo != null and dados_inimigo != null:
		inimigo.aplicar_dados(dados_inimigo)
		# Elite e Chefe são mais fortes (mais HP).
		match DeckManager.tipo_no_atual:
			"elite":
				inimigo.hp_max = int(dados_inimigo.hp_max * 2.5)
				inimigo.hp_atual = inimigo.hp_max
				inimigo.nome_exibicao = dados_inimigo.nome + " (Elite)"
			"chefe":
				inimigo.hp_max = int(dados_inimigo.hp_max * 5)
				inimigo.hp_atual = inimigo.hp_max
				inimigo.nome_exibicao = dados_inimigo.nome + " (Chefe)"

	# 4) Conecta a HUD (lê o HP já ajustado).
	if hud != null and hud.has_method("configurar"):
		hud.configurar(jogador, inimigo, maquina)

	# 5) Cria a mão de cartas clicáveis e a tela de fim de combate.
	_criar_mao()
	_criar_tela_fim()

	# 6) Inicia o combate (compra a primeira mão e dispara a UI).
	var lista_inimigos: Array[Combatant] = [inimigo]
	maquina.iniciar_combate(jogador, lista_inimigos)


## Instancia a mão (Hand.gd, um CanvasLayer) e a configura.
func _criar_mao() -> void:
	var mao = load(HAND_SCRIPT).new()
	mao.name = "Mao"
	add_child(mao)            # CanvasLayer renderiza por cima de tudo.
	mao.configurar(maquina, inimigo)


## Instancia a tela de fim de combate (escondida até o combate acabar).
func _criar_tela_fim() -> void:
	if hud == null:
		return
	var fim = load(FIM_SCRIPT).new()
	fim.name = "TelaFim"
	hud.add_child(fim)
	fim.configurar(jogador)
