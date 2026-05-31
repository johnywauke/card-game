## CombatStateMachine.gd
## Orquestra o fluxo de um combate por turnos, juntando Combatant, DeckManager
## e CardEffects. É o "maestro": decide de quem é a vez e o que acontece.
##
## Fluxo:
##   INICIO -> TURNO_JOGADOR -> TURNO_INIMIGO -> (repete) -> VITORIA ou DERROTA
##
## Como usar: adicione este nó à cena de combate, com o jogador e os inimigos
## como Combatant na árvore. Depois chame iniciar_combate(jogador, inimigos).
class_name CombatStateMachine
extends Node

## Estados possíveis do combate.
enum Estado {
	INICIO,
	TURNO_JOGADOR,
	TURNO_INIMIGO,
	VITORIA,
	DERROTA,
}

var estado: Estado = Estado.INICIO

## Combatentes ativos.
var jogador: Combatant
var inimigos: Array[Combatant] = []

## Energia do jogador.
@export var energia_maxima: int = 3
var energia_atual: int = 0

## Dragões invocados ativos. Cada item: { "efeito": Dictionary, "turnos": int }.
## Aplicados no início do turno do jogador; "turnos" diminui até expirarem.
var poderes_ativos: Array[Dictionary] = []


func _ready() -> void:
	# Escuta mortes para checar fim de combate.
	SignalBus.inimigo_morreu.connect(_ao_inimigo_morrer)
	SignalBus.jogador_morreu.connect(_ao_jogador_morrer)


## Ponto de entrada: inicia um combate com um jogador e uma lista de inimigos.
func iniciar_combate(p_jogador: Combatant, p_inimigos: Array[Combatant]) -> void:
	jogador = p_jogador
	inimigos = p_inimigos
	estado = Estado.INICIO
	poderes_ativos.clear()

	DeckManager.iniciar_combate()
	SignalBus.combate_iniciado.emit()

	# Define a intenção inicial de cada inimigo.
	for inimigo in inimigos:
		if inimigo.has_method("escolher_intencao"):
			inimigo.escolher_intencao()

	iniciar_turno_jogador()


## --- TURNO DO JOGADOR ---

func iniciar_turno_jogador() -> void:
	estado = Estado.TURNO_JOGADOR

	# Reseta energia e bloqueio, compra a mão.
	energia_atual = energia_maxima
	SignalBus.energia_alterada.emit(energia_atual, energia_maxima)
	jogador.limpar_bloqueio()
	_aplicar_poderes()
	DeckManager.comprar_mao_inicial()

	SignalBus.turno_jogador_iniciado.emit()


## Tenta jogar uma carta da mão. Retorna true se conseguiu.
## Validações: energia suficiente e Fervor suficiente (se a carta exigir).
func jogar_carta(carta: CardData, alvo: Combatant = null) -> bool:
	if estado != Estado.TURNO_JOGADOR:
		return false
	if carta.custo > energia_atual:
		return false
	if carta.fervor_custo > 0 and jogador.get_status(&"fervor") < carta.fervor_custo:
		return false

	# Gasta energia.
	energia_atual -= carta.custo
	SignalBus.energia_alterada.emit(energia_atual, energia_maxima)

	# Executa o efeito.
	var lista_inimigos: Array = inimigos
	CardEffects.executar(carta, jogador, alvo, lista_inimigos)
	SignalBus.carta_jogada.emit(carta)

	# Carta de Poder fica em jogo; as demais vão para o descarte.
	if carta.tipo != CardData.CardType.PODER:
		DeckManager.descartar_carta(carta)
	else:
		_registrar_poderes_da_carta(carta)

	_checar_vitoria()
	return true


## Encerra o turno do jogador e passa para os inimigos.
func terminar_turno_jogador() -> void:
	if estado != Estado.TURNO_JOGADOR:
		return
	DeckManager.descartar_mao()
	jogador.processar_status_fim_turno()
	SignalBus.turno_jogador_terminado.emit()

	if not jogador.esta_vivo():
		return # _ao_jogador_morrer cuida da derrota.

	iniciar_turno_inimigo()


## --- TURNO DOS INIMIGOS ---

func iniciar_turno_inimigo() -> void:
	estado = Estado.TURNO_INIMIGO
	SignalBus.turno_inimigo_iniciado.emit()

	for inimigo in inimigos:
		if not inimigo.esta_vivo():
			continue
		inimigo.limpar_bloqueio()
		# O inimigo executa a intenção que havia telegrafado.
		if inimigo.has_method("executar_intencao"):
			inimigo.executar_intencao(jogador)
		inimigo.processar_status_fim_turno()
		# Escolhe a próxima intenção para o jogador ver.
		if inimigo.has_method("escolher_intencao"):
			inimigo.escolher_intencao()

	SignalBus.turno_inimigo_terminado.emit()

	if not jogador.esta_vivo():
		return

	iniciar_turno_jogador()


## --- Fim de combate ---

## --- Invocações temporárias (dragões que duram X turnos) ---

## Registra os dragões invocados pela carta, no formato de efeito:
## { "tipo": "invocar", "turnos": 3, "efeito": { ... } }.
func _registrar_poderes_da_carta(carta: CardData) -> void:
	for ef in carta.efeitos:
		if ef.get("tipo", "") == "invocar":
			var recorrente: Dictionary = ef.get("efeito", {})
			if not recorrente.is_empty():
				poderes_ativos.append({
					"efeito": recorrente,
					"turnos": int(ef.get("turnos", 3)),
				})


## Aplica cada dragão ativo e reduz sua duração; remove os que expiraram.
## Chamado no início do turno do jogador.
func _aplicar_poderes() -> void:
	var sobreviventes: Array[Dictionary] = []
	for poder in poderes_ativos:
		CardEffects.aplicar_efeito_recorrente(poder["efeito"], jogador, inimigos)
		var turnos: int = poder["turnos"] - 1
		if turnos > 0:
			poder["turnos"] = turnos
			sobreviventes.append(poder)
	poderes_ativos = sobreviventes
	_checar_vitoria()  # um dragão pode ter derrotado o inimigo.


## Quantidade de dragões ativos (para a HUD, se quiser exibir).
func dragoes_ativos() -> int:
	return poderes_ativos.size()


func _ao_inimigo_morrer(_inimigo) -> void:
	_checar_vitoria()


func _ao_jogador_morrer() -> void:
	if estado == Estado.DERROTA or estado == Estado.VITORIA:
		return
	estado = Estado.DERROTA
	SignalBus.combate_perdido.emit()


func _checar_vitoria() -> void:
	# Evita sinalizar vitória mais de uma vez (ou após derrota).
	if estado == Estado.VITORIA or estado == Estado.DERROTA:
		return
	for inimigo in inimigos:
		if inimigo.esta_vivo():
			return # Ainda há inimigos vivos.
	estado = Estado.VITORIA
	SignalBus.combate_vencido.emit()


## --- Consultas ---

func inimigos_vivos() -> Array[Combatant]:
	var vivos: Array[Combatant] = []
	for inimigo in inimigos:
		if inimigo.esta_vivo():
			vivos.append(inimigo)
	return vivos
