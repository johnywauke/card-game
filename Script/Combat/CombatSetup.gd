## CombatSetup.gd
## Monta o combate quando a cena Combat abre:
##  - garante que há uma run em andamento (baralho + HP persistem entre combates)
##  - configura o jogador (Combatant) e o inimigo (Enemy)
##  - conecta a HUD, a mão de cartas (Hand) e a tela de fim de combate
##  - inicia a CombatStateMachine
extends Node

## Dados do inimigo (opcional: arraste um EnemyData no Inspector para forçar um).
@export var dados_inimigo: EnemyData

# Pools de inimigos por tipo de nó.
const INIMIGOS_BASICOS := [
	"res://Resources/Enemies/geleko.tres",
	"res://Resources/Enemies/cogumin.tres",
	"res://Resources/Enemies/vesporio.tres",
	"res://Resources/Enemies/casco.tres",
	"res://Resources/Enemies/espreitador.tres",
]
const INIMIGOS_ELITE := [
	"res://Resources/Enemies/brutamonte.tres",
	"res://Resources/Enemies/naja.tres",
]
const INIMIGO_CHEFE := "res://Resources/Enemies/guardiao_bronze.tres"

const HAND_SCRIPT := "res://Script/Combat/Hand.gd"
const FIM_SCRIPT := "res://Script/Combat/CombatEndScreen.gd"

@onready var jogador: Combatant = $"../Jogador"
@onready var inimigo: Enemy = $"../Inimigo"
@onready var maquina: CombatStateMachine = $"../CombatStateMachine"
@onready var hud: Control = $"../HUD_Root"
@onready var inimigo_sprite: Sprite2D = $"../InimigoSprite"


func _ready() -> void:
	# 1) Garante uma run ativa (na primeira vez, monta o baralho do Espadachin).
	if not DeckManager.run_iniciada:
		DeckManager.iniciar_run()

	# 2) Aplica o HP do jogador salvo na run.
	if jogador != null:
		jogador.hp_max = DeckManager.hp_max_jogador
		jogador.hp_atual = DeckManager.hp_jogador
		jogador.eh_jogador = true
		var f := DeckManager.bonus_reliquia("forca_inicial")
		var d := DeckManager.bonus_reliquia("destreza_inicial")
		var e := DeckManager.bonus_reliquia("escamas_inicial")
		var b := DeckManager.bonus_reliquia("bloqueio_inicial")
		if f > 0:
			jogador.aplicar_status(&"forca", f)
		if d > 0:
			jogador.aplicar_status(&"destreza", d)
		if e > 0:
			jogador.aplicar_status(&"escamas", e)
		if b > 0:
			jogador.ganhar_bloqueio(b)

	if maquina != null:
		maquina.energia_maxima = DeckManager.energia_max_jogador

	# 3) Escolhe o inimigo: usa o do Inspector, ou o já definido no nó do mapa,
	#    ou (fallback) sorteia. Assim o monstro do preview é o mesmo do combate.
	if dados_inimigo == null:
		dados_inimigo = DeckManager.inimigo_do_no_atual()
	if dados_inimigo == null:
		dados_inimigo = _sortear_inimigo()
	if inimigo != null and dados_inimigo != null:
		inimigo.aplicar_dados(dados_inimigo)
		# Elite recebe um reforço extra de HP (além de já ser um inimigo forte).
		if DeckManager.tipo_no_atual == "elite":
			inimigo.hp_max = int(dados_inimigo.hp_max * 1.2)
			inimigo.hp_atual = inimigo.hp_max
			inimigo.nome_exibicao = dados_inimigo.nome + " (Elite)"
		elif DeckManager.tipo_no_atual == "chefe":
			inimigo.nome_exibicao = dados_inimigo.nome + " (Chefe)"

		# Troca o sprite na cena pelo do inimigo sorteado (se tiver).
		if inimigo_sprite != null and dados_inimigo.sprite != null:
			inimigo_sprite.texture = dados_inimigo.sprite

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


## Sorteia o inimigo conforme o tipo de nó atual do mapa.
func _sortear_inimigo() -> EnemyData:
	var caminho := ""
	match DeckManager.tipo_no_atual:
		"elite":
			caminho = INIMIGOS_ELITE.pick_random()
		"chefe":
			caminho = INIMIGO_CHEFE
		_:
			caminho = INIMIGOS_BASICOS.pick_random()
	return load(caminho) as EnemyData
