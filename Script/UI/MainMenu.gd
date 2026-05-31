## MainMenu.gd
## Controla o menu inicial: Jogar, Opções e Sair.
## Detecta se existe um save local para decidir entre "Continuar" e "Novo Jogo".
extends Control

## Caminho do arquivo de save local. "user://" aponta para uma pasta segura
## do sistema (no Windows: %APPDATA%/Godot/app_userdata/card/).
const CAMINHO_SAVE: String = "user://savegame.json"

## Cena de seleção de classe (abre ao começar um novo jogo).
const CENA_SELECAO_CLASSE: String = "res://Scenes/UI/ClassSelect.tscn"

@onready var botao_jogar: Button = $VBoxContainer/BotaoJogar
@onready var botao_opcoes: Button = $VBoxContainer/BotaoOpcoes
@onready var botao_sair: Button = $VBoxContainer/BotaoSair


func _ready() -> void:
	botao_jogar.text = "Novo Jogo"


## --- Sinais dos botões (conecte cada pressed() a estas funções no editor) ---

func _on_botao_jogar_pressed() -> void:
	# Vai para a seleção de classe, que inicia a run com o baralho escolhido.
	get_tree().change_scene_to_file(CENA_SELECAO_CLASSE)


func _on_botao_opcoes_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/UI/Options.tscn")


func _on_botao_sair_pressed() -> void:
	get_tree().quit()


## --- Save local (utilitários) ---

## Verifica se existe um arquivo de save.
func _existe_save() -> bool:
	return FileAccess.file_exists(CAMINHO_SAVE)


## Salva um dicionário de dados no arquivo local (JSON).
## Chame de outras partes do jogo: ex. salvar_jogo({"andar": 2, "hp": 50}).
func salvar_jogo(dados: Dictionary) -> void:
	var arquivo := FileAccess.open(CAMINHO_SAVE, FileAccess.WRITE)
	if arquivo == null:
		push_error("Não foi possível abrir o save para escrita.")
		return
	arquivo.store_string(JSON.stringify(dados, "\t"))
	arquivo.close()


## Carrega os dados do save. Retorna um dicionário vazio se não houver save
## ou se o arquivo estiver corrompido.
func carregar_jogo() -> Dictionary:
	if not _existe_save():
		return {}
	var arquivo := FileAccess.open(CAMINHO_SAVE, FileAccess.READ)
	if arquivo == null:
		return {}
	var texto := arquivo.get_as_text()
	arquivo.close()
	var resultado = JSON.parse_string(texto)
	if resultado is Dictionary:
		return resultado
	return {}
