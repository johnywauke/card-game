## CartaVisual.gd
## Fábrica do visual de uma carta: um Button estilizado com o texto organizado
## em Labels internos (título + descrição) com margem e quebra de linha, para
## o texto SEMPRE caber dentro da carta. Usado pela mão e pela tela de recompensa.
class_name CartaVisual
extends RefCounted


## Cria e retorna um Button representando a carta.
static func criar(carta: CardData) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(170, 230)
	b.clip_contents = true
	b.mouse_filter = Control.MOUSE_FILTER_STOP
	b.text = ""  # o texto vai nos Labels filhos.

	_aplicar_estilo(b)

	# MarginContainer ocupa a carta inteira, com margem interna.
	var margem := MarginContainer.new()
	margem.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margem.add_theme_constant_override("margin_left", 12)
	margem.add_theme_constant_override("margin_right", 12)
	margem.add_theme_constant_override("margin_top", 12)
	margem.add_theme_constant_override("margin_bottom", 12)
	margem.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(margem)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margem.add_child(vbox)

	# Título: custo + nome.
	var titulo := Label.new()
	titulo.text = "[%d] %s" % [carta.custo, carta.nome]
	titulo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	titulo.add_theme_font_size_override("font_size", 17)
	titulo.add_theme_color_override("font_color", Color(0.12, 0.09, 0.05))
	titulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(titulo)

	# Descrição (quebra de linha automática).
	var desc := Label.new()
	desc.text = carta.descricao
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_size_override("font_size", 14)
	desc.add_theme_color_override("font_color", Color(0.18, 0.14, 0.10))
	desc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(desc)

	return b


## Aplica os StyleBox (fundo claro com borda) nos vários estados do botão.
static func _aplicar_estilo(b: Button) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.93, 0.89, 0.79)
	normal.set_border_width_all(3)
	normal.border_color = Color(0.25, 0.18, 0.10)
	normal.set_corner_radius_all(10)
	b.add_theme_stylebox_override("normal", normal)

	var hover := normal.duplicate()
	hover.bg_color = Color(1.0, 0.97, 0.86)
	hover.set_border_width_all(4)
	b.add_theme_stylebox_override("hover", hover)

	var pressed := normal.duplicate()
	pressed.bg_color = Color(0.80, 0.74, 0.62)
	b.add_theme_stylebox_override("pressed", pressed)

	var desabilitado := normal.duplicate()
	desabilitado.bg_color = Color(0.42, 0.42, 0.42, 0.75)
	desabilitado.border_color = Color(0.2, 0.2, 0.2)
	b.add_theme_stylebox_override("disabled", desabilitado)
