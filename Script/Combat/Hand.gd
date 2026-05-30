## Hand.gd
## Mostra a mão do jogador como cartas CLICÁVEIS na parte de baixo da tela.
## Cada carta é um botão; clicar joga a carta pela CombatStateMachine.
##
## Este nó se monta sozinho (cria seu próprio layout). O CombatSetup o instancia
## e chama configurar(maquina, alvo). Ele escuta o SignalBus para saber quando
## a mão muda e redesenhar.
extends Control

# Referências de lógica (recebidas via configurar).
var maquina: CombatStateMachine
var alvo_padrao: Combatant   # inimigo mirado por padrão (versão de 1 inimigo).

# Container horizontal onde as cartas ficam.
var _linha: HBoxContainer


func _ready() -> void:
	# Ancora numa faixa na parte inferior da tela, largura cheia.
	anchor_left = 0.0
	anchor_right = 1.0
	anchor_top = 1.0
	anchor_bottom = 1.0
	offset_top = -210.0
	offset_bottom = -10.0
	offset_left = 0.0
	offset_right = 0.0
	mouse_filter = Control.MOUSE_FILTER_IGNORE  # só os botões capturam clique.

	# HBox centralizado para as cartas.
	_linha = HBoxContainer.new()
	_linha.alignment = BoxContainer.ALIGNMENT_CENTER
	_linha.add_theme_constant_override("separation", 12)
	_linha.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_linha.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_linha)

	# Reage a mudanças na mão e à energia (para habilitar/desabilitar cartas).
	SignalBus.mao_alterada.connect(_redesenhar)
	SignalBus.energia_alterada.connect(func(_a, _b): _redesenhar())
	SignalBus.turno_jogador_iniciado.connect(_redesenhar)
	SignalBus.turno_inimigo_iniciado.connect(_redesenhar)


## Recebe as referências necessárias para jogar cartas.
func configurar(p_maquina: CombatStateMachine, p_alvo: Combatant) -> void:
	maquina = p_maquina
	alvo_padrao = p_alvo
	_redesenhar()


## Limpa e recria os botões de carta a partir da mão atual do DeckManager.
func _redesenhar(_ignorar = null) -> void:
	if _linha == null:
		return
	# Remove cartas antigas.
	for filho in _linha.get_children():
		filho.queue_free()

	var energia := maquina.energia_atual if maquina != null else 0
	var turno_do_jogador := maquina != null and maquina.estado == CombatStateMachine.Estado.TURNO_JOGADOR

	for carta in DeckManager.mao:
		var botao := _criar_botao_carta(carta)
		# Desabilita se não for o turno do jogador ou faltar energia.
		botao.disabled = (not turno_do_jogador) or (carta.custo > energia)
		botao.pressed.connect(_ao_clicar_carta.bind(carta))
		_linha.add_child(botao)


## Cria o visual de uma carta como um Button com texto (custo, nome, descrição).
func _criar_botao_carta(carta: CardData) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(150, 200)
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.clip_text = true
	b.add_theme_font_size_override("font_size", 16)
	b.text = "[%d] %s\n\n%s" % [carta.custo, carta.nome, carta.descricao]
	return b


## Joga a carta clicada. Para ataques, mira o alvo padrão (o inimigo).
func _ao_clicar_carta(carta: CardData) -> void:
	if maquina == null:
		return
	maquina.jogar_carta(carta, alvo_padrao)
