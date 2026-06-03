## MainMenu.gd
## Controla o menu inicial: Jogar/Continuar, Opções e Sair.
## Se houver um save de run, o botão principal vira "Continuar" e um botão
## extra "Novo Jogo" é criado. O save é gerido pelo DeckManager (fonte única).
extends Control

## Cena de seleção de classe (abre ao começar um novo jogo).
const CENA_SELECAO_CLASSE: String = "res://Scenes/UI/ClassSelect.tscn"
## Mapa da run (abre ao continuar uma run salva).
const CENA_MAPA: String = "res://Scenes/Map/Map.tscn"

@onready var botao_jogar: Button = $VBoxContainer/BotaoJogar
@onready var botao_opcoes: Button = $VBoxContainer/BotaoOpcoes
@onready var botao_sair: Button = $VBoxContainer/BotaoSair

## True quando o botão principal está no modo "Continuar".
var _modo_continuar: bool = false


func _ready() -> void:
	if DeckManager.tem_save():
		# Há uma run salva: botão principal continua; adiciona "Novo Jogo".
		_modo_continuar = true
		botao_jogar.text = "Continuar"
		_criar_botao_novo_jogo()
	else:
		_modo_continuar = false
		botao_jogar.text = "Novo Jogo"


## --- Sinais dos botões ---

func _on_botao_jogar_pressed() -> void:
	if _modo_continuar and DeckManager.carregar_run():
		# Retoma a run salva direto no mapa.
		get_tree().change_scene_to_file(CENA_MAPA)
	else:
		# Sem save (ou falha ao carregar): começa um jogo novo.
		get_tree().change_scene_to_file(CENA_SELECAO_CLASSE)


func _on_botao_opcoes_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/UI/Options.tscn")


func _on_botao_sair_pressed() -> void:
	get_tree().quit()


## --- Novo Jogo (quando há save) ---

## Cria, por código, um botão "Novo Jogo" logo abaixo do "Continuar".
## Começar um jogo novo só sobrescreve o save quando a classe é escolhida
## (DeckManager.iniciar_run grava o novo checkpoint), então o save antigo
## permanece intacto se o jogador desistir na tela de seleção.
func _criar_botao_novo_jogo() -> void:
	var novo := Button.new()
	novo.text = "Novo Jogo"
	# Copia o tamanho/fonte do botão principal para manter o visual coeso.
	novo.custom_minimum_size = botao_jogar.custom_minimum_size
	var fonte := botao_jogar.get_theme_font_size("font_size")
	if fonte > 0:
		novo.add_theme_font_size_override("font_size", fonte)
	novo.pressed.connect(_ao_novo_jogo)
	botao_jogar.get_parent().add_child(novo)
	botao_jogar.get_parent().move_child(novo, botao_jogar.get_index() + 1)


func _ao_novo_jogo() -> void:
	get_tree().change_scene_to_file(CENA_SELECAO_CLASSE)
