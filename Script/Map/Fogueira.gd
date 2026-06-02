## Fogueira.gd
## Nó de descanso. O jogador escolhe UMA ação: descansar (curar 30% do HP)
## OU melhorar uma carta do baralho. Depois segue viagem.
extends Control

const CENA_MAPA := "res://Scenes/Map/Map.tscn"

@onready var label_info: Label = $Centro/VBox/Info
@onready var botao_curar: Button = $Centro/VBox/BotaoCurar
@onready var botao_melhorar: Button = $Centro/VBox/BotaoMelhorar
@onready var botao_seguir: Button = $Centro/VBox/BotaoSeguir

var _overlay: Control


func _ready() -> void:
	_atualizar_info()
	botao_curar.pressed.connect(_descansar)
	botao_melhorar.pressed.connect(_abrir_melhorar)
	botao_seguir.pressed.connect(_voltar_mapa)
	botao_seguir.text = "Seguir sem usar →"


func _atualizar_info() -> void:
	label_info.text = "HP: %d / %d" % [DeckManager.hp_jogador, DeckManager.hp_max_jogador]


func _descansar() -> void:
	var cura := int(DeckManager.hp_max_jogador * 0.30)
	DeckManager.curar_jogador(cura)
	_consumir_acao()
	botao_seguir.text = "Seguir viagem →"
	_atualizar_info()


## Desabilita as ações (a fogueira permite apenas uma).
func _consumir_acao() -> void:
	botao_curar.disabled = true
	botao_melhorar.disabled = true


# --- Melhorar carta ---

func _abrir_melhorar() -> void:
	_overlay = Control.new()
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_overlay)

	var fundo := ColorRect.new()
	fundo.color = Color(0, 0, 0, 0.85)
	fundo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fundo.mouse_filter = Control.MOUSE_FILTER_STOP
	_overlay.add_child(fundo)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 18)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_overlay.add_child(vbox)

	var titulo := Label.new()
	titulo.text = "Escolha uma carta para melhorar"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_font_size_override("font_size", 32)
	vbox.add_child(titulo)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 280)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	vbox.add_child(scroll)

	var lista := HBoxContainer.new()
	lista.add_theme_constant_override("separation", 12)
	scroll.add_child(lista)

	var baralho := DeckManager.cartas_do_baralho()
	for i in baralho.size():
		var carta: CardData = baralho[i]
		var b := CartaVisual.criar(carta)
		if DeckManager.pode_melhorar(carta):
			b.pressed.connect(_melhorar.bind(i))
		else:
			b.disabled = true
		lista.add_child(b)

	var cancelar := Button.new()
	cancelar.text = "Cancelar"
	cancelar.custom_minimum_size = Vector2(220, 50)
	cancelar.add_theme_font_size_override("font_size", 22)
	cancelar.pressed.connect(_fechar_melhorar)
	vbox.add_child(cancelar)


func _melhorar(indice: int) -> void:
	DeckManager.melhorar_carta(indice)
	_consumir_acao()
	_fechar_melhorar()
	botao_seguir.text = "Seguir viagem →"


func _fechar_melhorar() -> void:
	if _overlay != null:
		_overlay.queue_free()
		_overlay = null


func _voltar_mapa() -> void:
	get_tree().change_scene_to_file(CENA_MAPA)
