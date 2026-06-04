## Hand.gd
## Mostra a mão do jogador como cartas CLICÁVEIS.
## A POSIÇÃO de cada carta é definida na CENA Hand.tscn pelos nós-slot
## (Cartas > Slot0, Slot1, ...). Arraste cada Slot no editor para posicionar
## as cartas como quiser — NADA de posição em código aqui.
## A carta i da mão é colocada dentro do Slot i; slots a mais ficam vazios.
extends CanvasLayer

## Cena de UMA carta. O layout/tamanho/estilo dela é editável em Carta.tscn.
const CENA_CARTA := preload("res://Scenes/Combat/Carta.tscn")

var maquina: CombatStateMachine
var alvo_padrao: Combatant

## Nó que contém os Slots de posição (definidos na cena Hand.tscn).
@onready var _cartas_root: Control = $Cartas


func _ready() -> void:
	SignalBus.mao_alterada.connect(_quando_atualizar)
	SignalBus.energia_alterada.connect(_quando_energia)
	SignalBus.turno_jogador_iniciado.connect(_quando_atualizar)
	SignalBus.turno_inimigo_iniciado.connect(_quando_atualizar)
	# Caso configurar() tenha rodado antes deste nó estar pronto (ordem da cena).
	_redesenhar()


func configurar(p_maquina: CombatStateMachine, p_alvo: Combatant) -> void:
	maquina = p_maquina
	alvo_padrao = p_alvo
	if is_node_ready():
		_redesenhar()


func _quando_atualizar() -> void:
	_redesenhar()

func _quando_energia(_atual: int, _maximo: int) -> void:
	_redesenhar()


## Lista os Slots de posição, na ordem em que aparecem na cena.
func _slots() -> Array[Node]:
	var lista: Array[Node] = []
	if _cartas_root != null:
		for filho in _cartas_root.get_children():
			if filho is Control:
				lista.append(filho)
	return lista


func _redesenhar() -> void:
	if _cartas_root == null:
		return

	var slots := _slots()

	# Remove cartas antigas de todos os slots.
	for slot in slots:
		for filho in slot.get_children():
			filho.queue_free()

	var energia := maquina.energia_atual if maquina != null else 0
	var turno := maquina != null and maquina.estado == CombatStateMachine.Estado.TURNO_JOGADOR

	var i := 0
	for carta in DeckManager.mao:
		if i >= slots.size():
			break  # Sem slots suficientes: adicione mais Slots em Hand.tscn.
		var botao = CENA_CARTA.instantiate()
		botao.configurar(carta)
		botao.disabled = (not turno) or (carta.custo > energia)
		botao.pressed.connect(_ao_clicar_carta.bind(carta))
		slots[i].add_child(botao)
		i += 1


func _ao_clicar_carta(carta: CardData) -> void:
	if maquina == null:
		return
	maquina.jogar_carta(carta, alvo_padrao)
