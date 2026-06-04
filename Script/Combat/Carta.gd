## Carta.gd
## Script do visual de UMA carta (cena Carta.tscn).
## A POSIÇÃO, o TAMANHO e o layout (margens, fontes, espaçamento, cores base,
## bordas, cantos) ficam na CENA (Carta.tscn) e podem ser ajustados no editor
## do Godot. Aqui só preenchemos os DADOS (nome, custo, descrição) e as poucas
## CORES que dependem da carta em tempo de execução (borda por raridade e fundo
## da etiqueta por tipo), reaproveitando os StyleBox da própria cena.
extends Button


## Preenche o visual a partir de um CardData.
## Pode ser chamado logo após instanciar a cena (antes de entrar na árvore):
## os nós-filhos já existem e os StyleBox locais já estão disponíveis.
func configurar(carta: CardData) -> void:
	var cor_borda := _cor_raridade(carta.raridade)

	# Borda colorida por raridade, reaproveitando os StyleBox definidos na cena
	# (cada carta tem cópia própria por causa de resource_local_to_scene).
	for nome_estilo in ["normal", "hover", "pressed"]:
		var sb := get_theme_stylebox(nome_estilo) as StyleBoxFlat
		if sb != null:
			sb.border_color = cor_borda

	# Etiqueta de tipo (cor de fundo + texto).
	var texto_tipo := ""
	var cor_tipo := Color.GRAY
	match carta.tipo:
		CardData.CardType.ATAQUE:
			texto_tipo = "⚔ Ataque"
			cor_tipo = Color(0.70, 0.20, 0.18)
		CardData.CardType.DEFESA:
			texto_tipo = "🛡 Defesa"
			cor_tipo = Color(0.20, 0.40, 0.70)
		CardData.CardType.HABILIDADE:
			texto_tipo = "✦ Habilidade"
			cor_tipo = Color(0.25, 0.55, 0.30)
		CardData.CardType.PODER:
			texto_tipo = "🐉 Invocação"
			cor_tipo = Color(0.50, 0.30, 0.65)

	var painel_etiqueta: PanelContainer = $Margem/Conteudo/Etiqueta
	($Margem/Conteudo/Etiqueta/EtiquetaLabel as Label).text = texto_tipo
	var sb_etiqueta := painel_etiqueta.get_theme_stylebox("panel") as StyleBoxFlat
	if sb_etiqueta != null:
		sb_etiqueta.bg_color = cor_tipo

	# Selo de raridade.
	var selo: Label = $Margem/Conteudo/Selo
	selo.text = "● %s" % carta.raridade_texto()
	selo.add_theme_color_override("font_color", cor_borda)

	# Título: custo + nome.
	($Margem/Conteudo/Titulo as Label).text = "[%d] %s" % [carta.custo, carta.nome]

	# Descrição.
	($Margem/Conteudo/Descricao as Label).text = carta.descricao


## Cor que representa a raridade (usada na borda e no selo de tier).
##   Comum = cinza, Incomum = azul, Rara = dourado.
static func _cor_raridade(raridade: int) -> Color:
	match raridade:
		CardData.Rarity.INCOMUM:
			return Color(0.25, 0.50, 0.85)  # Azul.
		CardData.Rarity.RARA:
			return Color(0.90, 0.72, 0.20)  # Dourado.
	return Color(0.45, 0.45, 0.45)  # Comum: cinza.
