## Loja.gd
## Nó de loja: vende relíquias (buffs passivos) por ouro.
## Mostra 3 relíquias sorteadas que o jogador ainda não possui.
extends Control

const CENA_MAPA := "res://Scenes/Map/Map.tscn"

const RELIQUIAS := [
	"res://Resources/Relics/coracao_vital.tres",
	"res://Resources/Relics/garra_afiada.tres",
	"res://Resources/Relics/couraca_ferro.tres",
	"res://Resources/Relics/broquel_eterno.tres",
	"res://Resources/Relics/escama_drag.tres",
	"res://Resources/Relics/amuleto_cura.tres",
	"res://Resources/Relics/nucleo_energia.tres",
	"res://Resources/Relics/talisma_vigor.tres",
]

@onready var label_ouro: Label = $Centro/VBox/Ouro
@onready var caixa: HBoxContainer = $Centro/VBox/Caixa
@onready var botao_sair: Button = $Centro/VBox/BotaoSair

var _a_venda: Array[RelicData] = []


func _ready() -> void:
	botao_sair.pressed.connect(_voltar_mapa)
	_sortear_estoque()
	_atualizar()


func _sortear_estoque() -> void:
	var pool: Array = RELIQUIAS.duplicate()
	pool.shuffle()
	_a_venda.clear()
	for caminho in pool:
		var relic := load(caminho) as RelicData
		if relic != null and not DeckManager.possui_reliquia(relic):
			_a_venda.append(relic)
		if _a_venda.size() >= 3:
			break


func _atualizar() -> void:
	label_ouro.text = "💰 Ouro: %d" % DeckManager.ouro
	for filho in caixa.get_children():
		filho.queue_free()
	if _a_venda.is_empty():
		var vazio := Label.new()
		vazio.text = "Estoque esgotado!"
		vazio.add_theme_font_size_override("font_size", 22)
		caixa.add_child(vazio)
		return
	for relic in _a_venda:
		caixa.add_child(_criar_cartao(relic))


func _criar_cartao(relic: RelicData) -> Control:
	var painel := PanelContainer.new()
	painel.custom_minimum_size = Vector2(220, 280)
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0.15, 0.13, 0.10, 0.98)
	estilo.set_border_width_all(3)
	estilo.border_color = Color(0.8, 0.65, 0.25)
	estilo.set_corner_radius_all(10)
	estilo.set_content_margin_all(14)
	painel.add_theme_stylebox_override("panel", estilo)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	painel.add_child(vbox)

	var nome := Label.new()
	nome.text = relic.nome
	nome.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nome.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	nome.add_theme_font_size_override("font_size", 20)
	nome.add_theme_color_override("font_color", Color(0.95, 0.85, 0.5))
	vbox.add_child(nome)

	var desc := Label.new()
	desc.text = relic.descricao
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_size_override("font_size", 14)
	vbox.add_child(desc)

	var espaco := Control.new()
	espaco.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(espaco)

	var botao := Button.new()
	botao.text = "💰 %d" % relic.custo
	botao.custom_minimum_size = Vector2(0, 48)
	botao.add_theme_font_size_override("font_size", 20)
	botao.disabled = DeckManager.ouro < relic.custo
	botao.pressed.connect(_comprar.bind(relic))
	vbox.add_child(botao)
	return painel


func _comprar(relic: RelicData) -> void:
	if DeckManager.comprar_reliquia(relic):
		_a_venda.erase(relic)
		_atualizar()


func _voltar_mapa() -> void:
	get_tree().change_scene_to_file(CENA_MAPA)
