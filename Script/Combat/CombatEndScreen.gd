## CombatEndScreen.gd
## Overlay (CanvasLayer) que cobre a tela quando o combate termina.
##  - VITÓRIA: mostra 3 cartas de recompensa (com etiqueta de tipo) para escolher.
##  - DERROTA: mostra "Derrota" e um botão para voltar ao menu (encerra a run).
## Camada acima da mão (Hand), para cobrir as cartas.
extends CanvasLayer

const CENA_COMBATE := "res://Scenes/Combat/Combat.tscn"
const CENA_MAPA := "res://Scenes/Map/Map.tscn"
const CENA_MENU := "res://Scenes/UI/MainMenu.tscn"

var jogador: Combatant

var _raiz: Control
var _titulo: Label
var _caixa_cartas: HBoxContainer
var _rodape: HBoxContainer


func _ready() -> void:
	layer = 20  # acima da mão (camada 10).

	_raiz = Control.new()
	_raiz.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_raiz.visible = false
	add_child(_raiz)

	var fundo := ColorRect.new()
	fundo.color = Color(0, 0, 0, 0.74)
	fundo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fundo.mouse_filter = Control.MOUSE_FILTER_STOP
	_raiz.add_child(fundo)

	var coluna := VBoxContainer.new()
	coluna.alignment = BoxContainer.ALIGNMENT_CENTER
	coluna.add_theme_constant_override("separation", 28)
	coluna.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	coluna.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_raiz.add_child(coluna)

	_titulo = Label.new()
	_titulo.add_theme_font_size_override("font_size", 46)
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

	var cura := DeckManager.bonus_reliquia("cura_combate")
	if cura > 0:
		DeckManager.hp_jogador = min(DeckManager.hp_jogador + cura, DeckManager.hp_max_jogador)

	var ouro_ganho := 20
	match DeckManager.tipo_no_atual:
		"elite":
			ouro_ganho = 45
		"chefe":
			ouro_ganho = 100
		_:
			ouro_ganho = randi_range(15, 28)
	DeckManager.ganhar_ouro(ouro_ganho)

	# Venceu o Chefe? Fim da run (vitória final).
	if DeckManager.venceu_chefe():
		_titulo.text = "Você venceu a Torre! 🏆"
		_limpar(_caixa_cartas)
		_limpar(_rodape)
		var voltar := Button.new()
		voltar.custom_minimum_size = Vector2(240, 60)
		voltar.add_theme_font_size_override("font_size", 24)
		voltar.text = "Voltar ao Menu"
		voltar.pressed.connect(_voltar_menu)
		_rodape.add_child(voltar)
		_raiz.visible = true
		return

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
	pular.pressed.connect(_voltar_mapa)
	_rodape.add_child(pular)

	_raiz.visible = true


func _escolher_recompensa(carta: CardData) -> void:
	DeckManager.adicionar_carta(carta)
	_voltar_mapa()


## Volta ao mapa para escolher o próximo nó.
func _voltar_mapa() -> void:
	get_tree().change_scene_to_file(CENA_MAPA)


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


func _limpar(container: Node) -> void:
	for filho in container.get_children():
		filho.queue_free()
