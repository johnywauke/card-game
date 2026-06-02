## MapConnections.gd
## Control que desenha as linhas que ligam os nós do mapa.
## Fica atrás dos botões (adicionado como primeiro filho do Conteudo).
## O MapView passa os pares de pontos (de -> para) via definir().
extends Control

var _linhas: Array = []  # cada item: [Vector2 de, Vector2 para]


func definir(linhas: Array) -> void:
	_linhas = linhas
	queue_redraw()


func _draw() -> void:
	for par in _linhas:
		draw_line(par[0], par[1], Color(0.85, 0.82, 0.65, 0.45), 4.0, true)
