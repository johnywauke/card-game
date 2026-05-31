## ClassSelect.gd
## Tela de seleção de classe. Cada botão inicia uma run com a classe escolhida
## (monta o baralho certo no DeckManager) e segue para o combate.
extends Control

const CENA_MAPA := "res://Scenes/Map/Map.tscn"

@onready var botao_espadachin: Button = $Centro/VBox/Cartoes/Espadachin
@onready var botao_dragao: Button = $Centro/VBox/Cartoes/Dragao
@onready var botao_voltar: Button = $Centro/VBox/BotaoVoltar


func _ready() -> void:
	botao_espadachin.pressed.connect(_escolher.bind("espadachin"))
	botao_dragao.pressed.connect(_escolher.bind("dragao"))
	botao_voltar.pressed.connect(_voltar)


func _escolher(classe: String) -> void:
	DeckManager.iniciar_run(classe)
	get_tree().change_scene_to_file(CENA_MAPA)


func _voltar() -> void:
	get_tree().change_scene_to_file("res://Scenes/UI/MainMenu.tscn")
