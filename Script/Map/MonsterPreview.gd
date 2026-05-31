## MonsterPreview.gd
## Popup que mostra um resumo do monstro antes de entrar no combate:
## sprite, nome, HP, tipo do nó e lista de habilidades. Botões "Lutar" e "Voltar".
##
## Monta-se sozinho (CanvasLayer por cima do mapa). O MapView cria e chama
## mostrar(dados_inimigo, tipo_no, callback_lutar).
extends CanvasLayer

var _callback_lutar: Callable
var _raiz: Control
var _sprite: TextureRect
var _nome: Label
var _hp: Label
var _habilidades: VBoxContainer


func _ready() -> void:
	layer = 30  # acima do mapa.
	_construir()
	_raiz.visible = false


func _construir() -> void:
	_raiz = Control.new()
	_raiz.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_raiz)

	# Fundo escuro que bloqueia cliques.
	var fundo := ColorRect.new()
	fundo.color = Color(0, 0, 0, 0.7)
	fundo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fundo.mouse_filter = Control.MOUSE_FILTER_STOP
	_raiz.add_child(fundo)

	# Painel central.
	var painel := PanelContainer.new()
	painel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	painel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	painel.grow_vertical = Control.GROW_DIRECTION_BOTH
	painel.custom_minimum_size = Vector2(460, 520)
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0.12, 0.10, 0.14, 0.98)
	estilo.set_border_width_all(3)
	estilo.border_color = Color(0.7, 0.6, 0.3)
	estilo.set_corner_radius_all(12)
	estilo.set_content_margin_all(24)
	painel.add_theme_stylebox_override("panel", estilo)
	_raiz.add_child(painel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	painel.add_child(vbox)

	# Sprite do monstro.
	_sprite = TextureRect.new()
	_sprite.custom_minimum_size = Vector2(0, 160)
	_sprite.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	vbox.add_child(_sprite)

	# Nome.
	_nome = Label.new()
	_nome.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_nome.add_theme_font_size_override("font_size", 32)
	vbox.add_child(_nome)

	# HP.
	_hp = Label.new()
	_hp.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hp.add_theme_font_size_override("font_size", 22)
	_hp.add_theme_color_override("font_color", Color(0.9, 0.4, 0.4))
	vbox.add_child(_hp)

	# Título "Habilidades".
	var titulo_hab := Label.new()
	titulo_hab.text = "Habilidades:"
	titulo_hab.add_theme_font_size_override("font_size", 18)
	titulo_hab.add_theme_color_override("font_color", Color(0.8, 0.8, 0.6))
	vbox.add_child(titulo_hab)

	# Lista de habilidades.
	_habilidades = VBoxContainer.new()
	_habilidades.add_theme_constant_override("separation", 4)
	vbox.add_child(_habilidades)

	# Botões.
	var linha_botoes := HBoxContainer.new()
	linha_botoes.alignment = BoxContainer.ALIGNMENT_CENTER
	linha_botoes.add_theme_constant_override("separation", 16)
	vbox.add_child(linha_botoes)

	var voltar := Button.new()
	voltar.text = "Voltar"
	voltar.custom_minimum_size = Vector2(140, 54)
	voltar.add_theme_font_size_override("font_size", 22)
	voltar.pressed.connect(_ao_voltar)
	linha_botoes.add_child(voltar)

	var lutar := Button.new()
	lutar.text = "⚔ Lutar"
	lutar.custom_minimum_size = Vector2(140, 54)
	lutar.add_theme_font_size_override("font_size", 22)
	lutar.pressed.connect(_ao_lutar)
	linha_botoes.add_child(lutar)


## Exibe o preview de um inimigo. callback é chamado ao clicar em Lutar.
func mostrar(dados: EnemyData, tipo_no: String, callback: Callable) -> void:
	_callback_lutar = callback

	var prefixo := ""
	if tipo_no == "elite":
		prefixo = "[Elite] "
	elif tipo_no == "chefe":
		prefixo = "[Chefe] "
	_nome.text = prefixo + dados.nome

	# HP exibido considera o reforço de elite (1.2x), igual ao CombatSetup.
	var hp := dados.hp_max
	if tipo_no == "elite":
		hp = int(hp * 1.2)
	_hp.text = "❤ %d HP" % hp

	if dados.sprite != null:
		_sprite.texture = dados.sprite

	for filho in _habilidades.get_children():
		filho.queue_free()
	for linha in dados.resumo_habilidades():
		var lbl := Label.new()
		lbl.text = "• " + linha
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 16)
		_habilidades.add_child(lbl)

	_raiz.visible = true


func _ao_lutar() -> void:
	_raiz.visible = false
	if _callback_lutar.is_valid():
		_callback_lutar.call()


func _ao_voltar() -> void:
	_raiz.visible = false
