## CartaVisual.gd
## Fábrica do visual de uma carta.
## O layout agora vive na CENA res://Scenes/Combat/Carta.tscn (editável no
## editor do Godot — tamanho, margens, fontes, posição dos elementos).
## Aqui só instanciamos essa cena e preenchemos os dados via Carta.gd.
## Mantido o nome criar() para não quebrar quem já chama (mão, recompensa, fogueira).
class_name CartaVisual
extends RefCounted

const CENA_CARTA := "res://Scenes/Combat/Carta.tscn"


## Cria e retorna o nó (Button) representando a carta.
static func criar(carta: CardData) -> Button:
	var b: Button = load(CENA_CARTA).instantiate()
	b.configurar(carta)
	return b
