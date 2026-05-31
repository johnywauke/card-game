## Hand.gd
## Mostra a mão do jogador como cartas CLICÁVEIS na parte de baixo da tela.
## Usa um CanvasLayer para garantir que as cartas fiquem SEMPRE por cima de
## tudo (cenário, sprites e HUD).
extends CanvasLayer

var maquina: CombatStateMachine
var alvo_padrao: Combatant
var _linha: HBoxContainer


func _ready() -> void:
	layer = 10  # acima do canvas padrão (camada 0).

	var painel := Control.new()
	painel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	painel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(painel)

	_linha = HBoxContainer.new()
	_linha.alignment = BoxContainer.ALIGNMENT_CENTER
	_linha.add_theme_constant_override("separation", 14)
	_linha.anchor_left = 0.0
	_linha.anchor_right = 1.0
	_linha.anchor_top = 1.0
	_linha.anchor_bottom = 1.0
	_linha.offset_left = 0.0
	_linha.offset_right = 0.0
	_linha.offset_top = -240.0
	_linha.offset_bottom = -20.0
	_linha.mouse_filter = Control.MOUSE_FILTER_IGNORE
	painel.add_child(_linha)

	SignalBus.mao_alterada.connect(_quando_atualizar)
	SignalBus.energia_alterada.connect(_quando_energia)
	SignalBus.turno_jogador_iniciado.connect(_quando_atualizar)
	SignalBus.turno_inimigo_iniciado.connect(_quando_atualizar)


func configurar(p_maquina: CombatStateMachine, p_alvo: Combatant) -> void:
	maquina = p_maquina
	alvo_padrao = p_alvo
	_redesenhar()


func _quando_atualizar() -> void:
	_redesenhar()

func _quando_energia(_atual: int, _maximo: int) -> void:
	_redesenhar()


func _redesenhar() -> void:
	if _linha == null:
		return
	for filho in _linha.get_children():
		filho.queue_free()

	var energia := maquina.energia_atual if maquina != null else 0
	var turno := maquina != null and maquina.estado == CombatStateMachine.Estado.TURNO_JOGADOR

	for carta in DeckManager.mao:
		var botao := CartaVisual.criar(carta)
		botao.disabled = (not turno) or (carta.custo > energia)
		botao.pressed.connect(_ao_clicar_carta.bind(carta))
		_linha.add_child(botao)


func _ao_clicar_carta(carta: CardData) -> void:
	if maquina == null:
		return
	maquina.jogar_carta(carta, alvo_padrao)
