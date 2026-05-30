## CombatEndScreen.gd
## Overlay que cobre a tela quando o combate termina.
##  - VITÓRIA: mostra 3 cartas de recompensa para escolher (some ao baralho da run)
##            e segue para o próximo combate. Também permite pular.
##  - DERROTA: mostra "Derrota" e um botão para voltar ao menu (encerra a run).
##
## Monta-se sozinho. O CombatSetup o instancia, o configura com o jogador
## (para salvar o HP na vitória) e o deixa escondido até o combate acabar.
extends Control

const CENA_COMBATE := "res://Scenes/Combat/Combat.tscn"
const CENA_MENU := "res://Scenes/UI/MainMenu.tscn"

var jogador: Combatant

var _titulo: Label
var _caixa_cartas: HBoxContainer
var _rodape: HBoxContainer


func _ready() -> void:
	# Cobre a tela inteira e começa escondido.
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false

	# Fundo escuro semitransparente que bloqueia cliques atrás.
	var fundo := ColorRect.new()
	fundo.color = Color(0, 0, 0, 0.7)
	fundo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fundo.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(fundo)

	# Coluna central com título, cartas e rodapé.
	var coluna := VBoxContainer.new()
	coluna.alignment = BoxContainer.ALIGNMENT_CENTER
	coluna.add_theme_constant_override("separation", 24)
	coluna.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	coluna.grow_horizontal = Control.GROW_DIRECTION_BOTH
	coluna.grow_vertical = Control.GROW_DIRECTION_BOTH
	add_child(coluna)

	_titulo = Label.new()
	_titulo.add_theme_font_size_override("font_size", 48)
	_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	coluna.add_child(_titulo)

	_caixa_cartas = HBoxContainer.new()
	_caixa_cartas.alignment = BoxContainer.ALIGNMENT_CENTER
	_caixa_cartas.add_theme_constant_override("separation", 16)
	coluna.add_child(_caixa_cartas)

	_rodape = HBoxContainer.new()
	_rodape.alignment = BoxContainer.ALIGNMENT_CENTER
	_rodape.add_theme_constant_override("separation", 16)
	coluna.add_child(_rodape)

	# Escuta o fim do combate.
	SignalBus.combate_vencido.connect(_ao_vencer)
	SignalBus.combate_perdido.connect(_ao_perder)


## Recebe a referência do jogador (para salvar o HP na vitória).
func configurar(p_jogador: Combatant) -> void:
	jogador = p_jogador


# --- VITÓRIA ---

func _ao_vencer() -> void:
	# Salva o HP atual do jogador para o próximo combate.
	if jogador != null:
		DeckManager.hp_jogador = jogador.hp_atual

	_titulo.text = "Vitória! Escolha uma carta:"
	_limpar(_caixa_cartas)
	_limpar(_rodape)

	# Mostra 3 cartas de recompensa.
	for carta in DeckManager.sortear_recompensas(3):
		var b := _botao_carta(carta)
		b.pressed.connect(_escolher_recompensa.bind(carta))
		_caixa_cartas.add_child(b)

	# Botão para pular a recompensa.
	var pular := Button.new()
	pular.custom_minimum_size = Vector2(160, 50)
	pular.text = "Pular"
	pular.pressed.connect(_proximo_combate)
	_rodape.add_child(pular)

	visible = true


func _escolher_recompensa(carta: CardData) -> void:
	DeckManager.adicionar_carta(carta)
	_proximo_combate()


func _proximo_combate() -> void:
	get_tree().change_scene_to_file(CENA_COMBATE)


# --- DERROTA ---

func _ao_perder() -> void:
	_titulo.text = "Derrota..."
	_limpar(_caixa_cartas)
	_limpar(_rodape)

	var voltar := Button.new()
	voltar.custom_minimum_size = Vector2(220, 60)
	voltar.add_theme_font_size_override("font_size", 24)
	voltar.text = "Voltar ao Menu"
	voltar.pressed.connect(_voltar_menu)
	_rodape.add_child(voltar)

	visible = true


func _voltar_menu() -> void:
	DeckManager.encerrar_run()
	get_tree().change_scene_to_file(CENA_MENU)


# --- Utilitários ---

func _botao_carta(carta: CardData) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(150, 200)
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.clip_text = true
	b.add_theme_font_size_override("font_size", 16)
	b.text = "[%d] %s\n\n%s" % [carta.custo, carta.nome, carta.descricao]
	return b


func _limpar(container: Node) -> void:
	for filho in container.get_children():
		filho.queue_free()
