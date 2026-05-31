## MapView.gd
## Desenha o mapa da run e deixa o jogador escolher o próximo nó.
## Os nós disponíveis (ligados ao nó atual) ficam clicáveis; os demais, apenas
## ilustrativos. Ao clicar, registra a escolha e vai para o combate ou fogueira.
##
## Monta-se por código a partir do mapa gerado no DeckManager.
extends Control

const CENA_COMBATE := "res://Scenes/Combat/Combat.tscn"
const CENA_FOGUEIRA := "res://Scenes/Map/Fogueira.tscn"
const PREVIEW_SCRIPT := "res://Script/Map/MonsterPreview.gd"

# Espaçamento visual.
const ALTURA_ANDAR := 130
const LARGURA_COLUNA := 220
const MARGEM_TOPO := 80

@onready var _camada := $Scroll/Conteudo


func _ready() -> void:
	_desenhar_mapa()


func _desenhar_mapa() -> void:
	for filho in _camada.get_children():
		filho.queue_free()

	var mapa: Array = DeckManager.mapa
	if mapa.is_empty():
		return

	# Índices dos nós que o jogador pode escolher agora.
	var disponiveis := DeckManager.nos_disponiveis()

	# O mapa é desenhado de baixo (andar 0) para cima (chefe no topo),
	# mas como é um Control, desenhamos de cima pra baixo invertendo o índice.
	var total := mapa.size()
	for a in total:
		var andar: Array = mapa[a]
		var y := MARGEM_TOPO + (total - 1 - a) * ALTURA_ANDAR
		for i in andar.size():
			var no: Dictionary = andar[i]
			var botao := _criar_botao_no(no)
			# Posição X centralizada conforme a quantidade de nós no andar.
			var largura_total := andar.size() * LARGURA_COLUNA
			var x := 600 - largura_total / 2 + i * LARGURA_COLUNA
			botao.position = Vector2(x, y)

			# Clicável só se estiver na lista de disponíveis.
			var pode := _no_esta_disponivel(no, disponiveis)
			botao.disabled = not pode
			if pode:
				botao.pressed.connect(_ao_escolher.bind(a, i))
			_camada.add_child(botao)


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
