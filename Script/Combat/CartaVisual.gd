## CartaVisual.gd
## Fábrica do visual de uma carta: um Button estilizado com etiqueta de tipo
## colorida, título (custo + nome) e descrição, tudo com quebra de linha.
## A cor da BORDA reflete a raridade. Usado pela mão e pela tela de recompensa.
class_name CartaVisual
extends RefCounted


## Cria e retorna um Button representando a carta.
static func criar(carta: CardData) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(180, 248)
	b.clip_contents = true
	b.mouse_filter = Control.MOUSE_FILTER_STOP
	b.text = ""

	_aplicar_estilo(b, carta)

	var margem := MarginContainer.new()
	margem.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margem.add_theme_constant_override("margin_left", 12)
	margem.add_theme_constant_override("margin_right", 12)
	margem.add_theme_constant_override("margin_top", 12)
	margem.add_theme_constant_override("margin_bottom", 12)
	margem.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(margem)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margem.add_child(vbox)

	# Etiqueta de tipo (colorida).
	var etiqueta := _criar_etiqueta_tipo(carta)
	vbox.add_child(etiqueta)

	# Selo de raridade: deixa o TIER explícito ao escolher/comprar cartas
	# (além da cor da borda). Comum < Incomum < Rara.
	var selo := Label.new()
	selo.text = "● %s" % carta.raridade_texto()
	selo.add_theme_font_size_override("font_size", 12)
	selo.add_theme_color_override("font_color", _cor_raridade(carta.raridade))
	selo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(selo)

	# Título: custo + nome.
	var titulo := Label.new()
	titulo.text = "[%d] %s" % [carta.custo, carta.nome]
	titulo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	titulo.add_theme_font_size_override("font_size", 17)
	titulo.add_theme_color_override("font_color", Color(0.12, 0.09, 0.05))
	titulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(titulo)

	# Descrição.
	var desc := Label.new()
	desc.text = carta.descricao
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_size_override("font_size", 13)
	desc.add_theme_color_override("font_color", Color(0.18, 0.14, 0.10))
	desc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(desc)

	return b


## Cria a etiqueta (PanelContainer + Label) com emoji, nome do tipo e cor.
static func _criar_etiqueta_tipo(carta: CardData) -> Control:
	var texto := ""
	var cor := Color.GRAY
	match carta.tipo:
		CardData.CardType.ATAQUE:
			texto = "⚔ Ataque"
			cor = Color(0.70, 0.20, 0.18)
		CardData.CardType.DEFESA:
			texto = "🛡 Defesa"
			cor = Color(0.20, 0.40, 0.70)
		CardData.CardType.HABILIDADE:
			texto = "✦ Habilidade"
			cor = Color(0.25, 0.55, 0.30)
		CardData.CardType.PODER:
			texto = "🐉 Invocação"
			cor = Color(0.50, 0.30, 0.65)

	var painel := PanelContainer.new()
	painel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = cor
	estilo.set_corner_radius_all(6)
	estilo.set_content_margin_all(4)
	painel.add_theme_stylebox_override("panel", estilo)

	var lbl := Label.new()
	lbl.text = texto
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", Color(1, 1, 1))
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	painel.add_child(lbl)
	return painel


## Cor que representa a raridade (usada na borda e no selo de tier).
##   Comum = cinza, Incomum = azul, Rara = dourado.
static func _cor_raridade(raridade: int) -> Color:
	match raridade:
		CardData.Rarity.INCOMUM:
			return Color(0.25, 0.50, 0.85)  # Azul.
		CardData.Rarity.RARA:
			return Color(0.90, 0.72, 0.20)  # Dourado.
	return Color(0.45, 0.45, 0.45)  # Comum: cinza.


## Estilo do botão: fundo claro + borda colorida por raridade.
static func _aplicar_estilo(b: Button, carta: CardData) -> void:
	var cor_borda := _cor_raridade(carta.raridade)

	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.93, 0.89, 0.79)
	normal.set_border_width_all(4)
	normal.border_color = cor_borda
	normal.set_corner_radius_all(10)
	b.add_theme_stylebox_override("normal", normal)

	var hover := normal.duplicate()
	hover.bg_color = Color(1.0, 0.97, 0.86)
	b.add_theme_stylebox_override("hover", hover)

	var pressed := normal.duplicate()
	pressed.bg_color = Color(0.80, 0.74, 0.62)
	b.add_theme_stylebox_override("pressed", pressed)

	var desabilitado := normal.duplicate()
	desabilitado.bg_color = Color(0.42, 0.42, 0.42, 0.75)
	desabilitado.border_color = Color(0.3, 0.3, 0.3)
	b.add_theme_stylebox_override("disabled", desabilitado)
