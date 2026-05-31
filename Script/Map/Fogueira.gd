## Fogueira.gd
## Nó de descanso: o jogador pode CURAR 30% do HP máximo e depois voltar ao mapa.
## (Melhorar carta fica para uma etapa futura.)
extends Control

const CENA_MAPA := "res://Scenes/Map/Map.tscn"

@onready var label_info: Label = $Centro/VBox/Info
@onready var botao_curar: Button = $Centro/VBox/BotaoCurar
@onready var botao_seguir: Button = $Centro/VBox/BotaoSeguir


func _ready() -> void:
	_atualizar_info()
	botao_curar.pressed.connect(_descansar)
	botao_seguir.pressed.connect(_voltar_mapa)


func _atualizar_info() -> void:
	label_info.text = "HP: %d / %d" % [DeckManager.hp_jogador, DeckManager.hp_max_jogador]


func _descansar() -> void:
	var cura := int(DeckManager.hp_max_jogador * 0.30)
	DeckManager.hp_jogador = min(DeckManager.hp_jogador + cura, DeckManager.hp_max_jogador)
	botao_curar.disabled = true
	_atualizar_info()


func _voltar_mapa() -> void:
	get_tree().change_scene_to_file(CENA_MAPA)
