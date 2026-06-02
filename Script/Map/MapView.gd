## MapView.gd
## Desenha o mapa da run e deixa o jogador escolher o próximo nó.
## Os nós disponíveis (ligados ao nó atual) ficam clicáveis; os demais, apenas
## ilustrativos. Ao clicar, registra a escolha e vai para o combate ou fogueira.
##
## Monta-se por código a partir do mapa gerado no DeckManager.
extends Control

const CENA_COMBATE := "res://Scenes/Combat/Combat.tscn"
const CENA_FOGUEIRA := "res://Scenes/Map/Fogueira.tscn"
const CENA_LOJA := "res://Scenes/Map/Loja.tscn"
const CENA_EVENTO := "res://Scenes/Map/Evento.tscn"
const PREVIEW_SCRIPT := "res://Script/Map/MonsterPreview.gd"
const LINHAS_SCRIPT := "res://Script/Map/MapConnections.gd"

# Espaçamento visual.
const ALTURA_ANDAR := 130
const LARGURA_COLUNA := 220
const MARGEM_TOPO := 80

@onready var _camada := $Scroll/Conteudo


func _ready() -> void:
	_desenhar_mapa()
	_construir_barra_topo()


func _desenhar_mapa() -> void:
	for filho in _camada.get_children():
		filho.queue_free()

	var mapa: Array = DeckManager.mapa
	if mapa.is_empty():
		return

	# Índices dos nós que o jogador pode escolher agora.
	var disponiveis := DeckManager.nos_disponiveis()

	var total := mapa.size()

	# 1) Desenha as linhas de ligação ATRÁS dos botões.
	var linhas := []
	for a in total - 1:
		var andar_a: Array = mapa[a]
		for i in andar_a.size():
			var no_a: Dictionary = andar_a[i]
			for j in no_a.get("ligacoes", []):
				linhas.append([_centro_no(a, i), _centro_no(a + 1, j)])
	var desenho = load(LINHAS_SCRIPT).new()
	desenho.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	desenho.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_camada.add_child(desenho)
	desenho.definir(linhas)

	# 2) Desenha os botões dos nós por cima.
	for a in total:
		var andar: Array = mapa[a]
		for i in andar.size():
			var no: Dictionary = andar[i]
			var botao := _criar_botao_no(no)
			botao.position = _posicao_no(a, i)

			var pode := _no_esta_disponivel(no, disponiveis)
			botao.disabled = not pode
			if pode:
				botao.pressed.connect(_ao_escolher.bind(a, i))
			_camada.add_child(botao)


## Posição (canto superior esquerdo) do botão de um nó.
func _posicao_no(a: int, i: int) -> Vector2:
	var total := DeckManager.mapa.size()
	var andar: Array = DeckManager.mapa[a]
	var y := MARGEM_TOPO + (total - 1 - a) * ALTURA_ANDAR
	var largura_total := andar.size() * LARGURA_COLUNA
	var x := 600 - largura_total / 2 + i * LARGURA_COLUNA
	return Vector2(x, y)


## Centro do nó (para ligar as linhas). Botão tem 180x80.
func _centro_no(a: int, i: int) -> Vector2:
	return _posicao_no(a, i) + Vector2(90, 40)


## Verifica se um nó está entre os disponíveis (compara pelo id único).
func _no_esta_disponivel(no: Dictionary, disponiveis: Array) -> bool:
	for d in disponiveis:
		if d.get("id", -1) == no.get("id", -2):
			return true
	return false


## Cria o botão visual de um nó, com ícone + nome conforme o tipo.
func _criar_botao_no(no: Dictionary) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(180, 80)
	b.size = Vector2(180, 80)
	b.add_theme_font_size_override("font_size", 20)

	var tipo: String = no["tipo"]
	var texto := ""
	var cor := Color(0.5, 0.5, 0.5)
	match tipo:
		"combate":
			texto = "⚔ Combate"
			cor = Color(0.55, 0.25, 0.22)
		"elite":
			texto = "💀 Elite"
			cor = Color(0.55, 0.20, 0.45)
		"fogueira":
			texto = "🔥 Fogueira"
			cor = Color(0.70, 0.45, 0.15)
		"loja":
			texto = "🏪 Loja"
			cor = Color(0.20, 0.50, 0.45)
		"evento":
			texto = "❓ Evento"
			cor = Color(0.35, 0.35, 0.55)
		"chefe":
			texto = "👑 Chefe"
			cor = Color(0.65, 0.55, 0.15)
	b.text = texto

	var estilo := StyleBoxFlat.new()
	estilo.bg_color = cor
	estilo.set_corner_radius_all(10)
	estilo.set_border_width_all(3)
	estilo.border_color = Color(0.9, 0.85, 0.7)
	b.add_theme_stylebox_override("normal", estilo)

	var hover := estilo.duplicate()
	hover.bg_color = cor.lightened(0.2)
	b.add_theme_stylebox_override("hover", hover)

	var desab := estilo.duplicate()
	desab.bg_color = cor.darkened(0.4)
	desab.border_color = Color(0.4, 0.4, 0.4)
	b.add_theme_stylebox_override("disabled", desab)
	b.add_theme_color_override("font_color", Color.WHITE)
	b.add_theme_color_override("font_disabled_color", Color(0.7, 0.7, 0.7))
	return b


## Registra a escolha e vai para a cena correspondente ao tipo do nó.
func _ao_escolher(andar: int, indice: int) -> void:
	DeckManager.escolher_no(andar, indice)
	var tipo := DeckManager.tipo_no_atual
	if tipo == "fogueira":
		get_tree().change_scene_to_file(CENA_FOGUEIRA)
	elif tipo == "loja":
		get_tree().change_scene_to_file(CENA_LOJA)
	elif tipo == "evento":
		get_tree().change_scene_to_file(CENA_EVENTO)
	else:
		# Combate/elite/chefe: mostra o preview do monstro antes de lutar.
		var dados := DeckManager.inimigo_do_no_atual()
		if dados == null:
			get_tree().change_scene_to_file(CENA_COMBATE)
			return
		var preview = load(PREVIEW_SCRIPT).new()
		add_child(preview)
		preview.mostrar(dados, tipo, _ir_para_combate)


## Callback chamado pelo botão "Lutar" do preview.
func _ir_para_combate() -> void:
	get_tree().change_scene_to_file(CENA_COMBATE)


## Barra fixa no topo do mapa mostrando HP e ouro da run.
func _construir_barra_topo() -> void:
	var barra := HBoxContainer.new()
	barra.add_theme_constant_override("separation", 24)
	barra.position = Vector2(20, 16)
	barra.z_index = 100
	add_child(barra)

	var hp := Label.new()
	hp.text = "❤ %d/%d" % [DeckManager.hp_jogador, DeckManager.hp_max_jogador]
	hp.add_theme_font_size_override("font_size", 24)
	hp.add_theme_color_override("font_color", Color(0.9, 0.4, 0.4))
	barra.add_child(hp)

	var ouro := Label.new()
	ouro.text = "💰 %d" % DeckManager.ouro
	ouro.add_theme_font_size_override("font_size", 24)
	ouro.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
	barra.add_child(ouro)
