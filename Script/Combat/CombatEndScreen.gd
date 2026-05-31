## CombatEndScreen.gd
## Overlay (CanvasLayer) que cobre a tela quando o combate termina.
##  - VITÓRIA: mostra 3 cartas de recompensa para escolher (some ao baralho)
##            e segue para o próximo combate. Também permite pular.
##  - DERROTA: mostra "Derrota" e um botão para voltar ao menu (encerra a run).
##
## Usa CanvasLayer com camada acima da mão (Hand), para cobrir as cartas.
extends CanvasLayer

const CENA_COMBATE := "res://Scenes/Combat/Combat.tscn"
const CENA_MENU := "res://Scenes/UI/MainMenu.tscn"

var jogador: Combatant

var _raiz: Control          # container de tela cheia, mostrado só no fim.
var _titulo: Label
var _caixa_cartas: HBoxContainer
var _rodape: HBoxContainer


func _ready() -> void:
	layer = 20  # acima da mão (camada 10).

	_raiz = Control.new()
	_raiz.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_raiz.visible = false
	add_child(_raiz)

	# Fundo escuro que bloqueia cliques atrás.
	var fundo := ColorRect.new()
	fundo.color = Color(0, 0, 0, 0.72)
	fundo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fundo.mouse_filter = Control.MOUSE_FILTER_STOP
	_raiz.add_child(fundo)

	# Coluna central: título, cartas e rodapé.
	var coluna := VBoxContainer.new()
	coluna.alignment = BoxContainer.ALIGNMENT_CENTER
	coluna.add_theme_constant_override("separation", 28)
	coluna.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	coluna.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_raiz.add_child(coluna)

	_titulo = Label.new()
	_titulo.add_theme_font_size_override("font_size", 48)
	_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_titulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	coluna.add_child(_titulo)

	_caixa_cartas = HBoxContainer.new()
	_caixa_cartas.alignment = BoxContainer.ALIGNMENT_CENTER
	_caixa_cartas.add_theme_constant_override("separation", 18)
	_caixa_cartas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	coluna.add_child(_caixa_cartas)

	_rodape = HBoxContainer.new()
	_rodape.alignment = BoxContainer.ALIGNMENT_CENTER
	_rodape.add_theme_constant_override("separation", 16)
	_rodape.mouse_filter = Control.MOUSE_FILTER_IGNORE
	coluna.add_child(_rodape)

	SignalBus.combate_vencido.connect(_ao_vencer)
	SignalBus.combate_perdido.connect(_ao_perder)


func configurar(p_jogador: Combatant) -> void:
	jogador = p_jogador


# --- VITÓRIA ---

func _ao_vencer() -> void:
	if jogador != null:
		DeckManager.hp_jogador = jogador.hp_atual

	_titulo.text = "Vitória! Escolha uma carta:"
	_limpar(_caixa_cartas)
	_limpar(_rodape)

	for carta in DeckManager.sortear_recompensas(3):
		var b := CartaVisual.criar(carta)
		b.pressed.connect(_escolher_recompensa.bind(carta))
		_caixa_cartas.add_child(b)

	var pular := Button.new()
	pular.custom_minimum_size = Vector2(160, 50)
	pular.text = "Pular"
	pular.pressed.connect(_proximo_combate)
	_rodape.add_child(pular)

	_raiz.visible = true


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

	_raiz.visible = true


func _voltar_menu() -> void:
	DeckManager.encerrar_run()
	get_tree().change_scene_to_file(CENA_MENU)


# --- Utilitário ---

func _limpar(container: Node) -> void:
	for filho in container.get_children():
		filho.queue_free()
