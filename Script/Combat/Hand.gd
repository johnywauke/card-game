## Hand.gd
## Mostra a mão do jogador como cartas CLICÁVEIS na parte de baixo da tela.
## Usa um CanvasLayer para garantir que as cartas fiquem SEMPRE por cima de
## tudo (cenário, sprites e HUD), evitando problemas de ordem de renderização.
extends CanvasLayer

var maquina: CombatStateMachine
var alvo_padrao: Combatant
var _linha: HBoxContainer


func _ready() -> void:
	layer = 10  # bem acima do canvas padrão (camada 0).

	# Container invisível que ocupa a tela toda.
	var painel := Control.new()
	painel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	painel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(painel)

	# Linha de cartas, ancorada na parte inferior e centralizada.
	_linha = HBoxContainer.new()
	_linha.alignment = BoxContainer.ALIGNMENT_CENTER
	_linha.add_theme_constant_override("separation", 14)
	_linha.anchor_left = 0.0
	_linha.anchor_right = 1.0
	_linha.anchor_top = 1.0
	_linha.anchor_bottom = 1.0
	_linha.offset_left = 0.0
	_linha.offset_right = 0.0
	_linha.offset_top = -230.0
	_linha.offset_bottom = -20.0
	_linha.mouse_filter = Control.MOUSE_FILTER_IGNORE
	painel.add_child(_linha)

	# Handlers com assinaturas que batem com os sinais.
	SignalBus.mao_alterada.connect(_quando_atualizar)
	SignalBus.energia_alterada.connect(_quando_energia)
	SignalBus.turno_jogador_iniciado.connect(_quando_atualizar)
	SignalBus.turno_inimigo_iniciado.connect(_quando_atualizar)


## Recebe as referências necessárias para jogar cartas.
func configurar(p_maquina: CombatStateMachine, p_alvo: Combatant) -> void:
	maquina = p_maquina
	alvo_padrao = p_alvo
	_redesenhar()


# Handlers (assinaturas exatas dos sinais).
func _quando_atualizar() -> void:
	_redesenhar()

func _quando_energia(_atual: int, _maximo: int) -> void:
	_redesenhar()


## Limpa e recria os botões de carta a partir da mão atual do DeckManager.
func _redesenhar() -> void:
	if _linha == null:
		return
	for filho in _linha.get_children():
		filho.queue_free()

	var energia := maquina.energia_atual if maquina != null else 0
	var turno := maquina != null and maquina.estado == CombatStateMachine.Estado.TURNO_JOGADOR

	for carta in DeckManager.mao:
		var botao := _criar_botao_carta(carta)
		botao.disabled = (not turno) or (carta.custo > energia)
		botao.pressed.connect(_ao_clicar_carta.bind(carta))
		_linha.add_child(botao)


## Cria o visual de uma carta como um Button estilizado (claramente visível).
func _criar_botao_carta(carta: CardData) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(150, 210)
	b.mouse_filter = Control.MOUSE_FILTER_STOP
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.clip_text = true
	b.add_theme_font_size_override("font_size", 16)
	b.text = "[%d] %s\n\n%s" % [carta.custo, carta.nome, carta.descricao]

	# Fundo claro com borda escura (destaca do cenário).
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.93, 0.89, 0.79)
	normal.set_border_width_all(3)
	normal.border_color = Color(0.25, 0.18, 0.10)
	normal.set_corner_radius_all(8)
	normal.set_content_margin_all(8)
	b.add_theme_stylebox_override("normal", normal)

	var hover := normal.duplicate()
	hover.bg_color = Color(1.0, 0.97, 0.86)
	b.add_theme_stylebox_override("hover", hover)

	var pressed := normal.duplicate()
	pressed.bg_color = Color(0.80, 0.74, 0.62)
	b.add_theme_stylebox_override("pressed", pressed)

	var desabilitado := normal.duplicate()
	desabilitado.bg_color = Color(0.45, 0.45, 0.45, 0.7)
	b.add_theme_stylebox_override("disabled", desabilitado)

	b.add_theme_color_override("font_color", Color(0.1, 0.08, 0.05))
	b.add_theme_color_override("font_disabled_color", Color(0.85, 0.85, 0.85, 0.8))
	return b


## Joga a carta clicada. Para ataques, mira o alvo padrão (o inimigo).
func _ao_clicar_carta(carta: CardData) -> void:
	if maquina == null:
		return
	maquina.jogar_carta(carta, alvo_padrao)
