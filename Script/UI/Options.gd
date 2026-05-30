## Options.gd
## Tela de opções: volume de música e efeitos, tela cheia.
## As configurações são salvas localmente e recarregadas ao abrir o jogo.
extends Control

## Caminho do arquivo de configurações.
const CAMINHO_CONFIG: String = "user://settings.json"

@onready var slider_musica: HSlider = $Painel/VBox/LinhaMusica/SliderMusica
@onready var slider_efeitos: HSlider = $Painel/VBox/LinhaEfeitos/SliderEfeitos
@onready var check_tela_cheia: CheckButton = $Painel/VBox/CheckTelaCheia
@onready var botao_voltar: Button = $Painel/VBox/BotaoVoltar


func _ready() -> void:
	_carregar_config()


## --- Sinais (conecte no editor) ---

func _on_slider_musica_value_changed(valor: float) -> void:
	_aplicar_volume("Music", valor)
	_salvar_config()


func _on_slider_efeitos_value_changed(valor: float) -> void:
	_aplicar_volume("SFX", valor)
	_salvar_config()


func _on_check_tela_cheia_toggled(ativado: bool) -> void:
	if ativado:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	_salvar_config()


func _on_botao_voltar_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/UI/MainMenu.tscn")


## --- Aplicar áudio ---
## Ajusta o volume de um bus de áudio (0.0 a 1.0 vindo do slider).
## IMPORTANTE: crie os buses "Music" e "SFX" no editor de áudio do Godot
## (parte inferior -> aba Audio), senão o índice retorna -1 e nada acontece.
func _aplicar_volume(nome_bus: String, valor: float) -> void:
	var idx := AudioServer.get_bus_index(nome_bus)
	if idx == -1:
		return
	# Converte 0..1 para decibéis. Em 0, silencia (-80 dB).
	var db := linear_to_db(valor) if valor > 0.0 else -80.0
	AudioServer.set_bus_volume_db(idx, db)


## --- Salvar / carregar configurações ---

func _salvar_config() -> void:
	var dados := {
		"musica": slider_musica.value,
		"efeitos": slider_efeitos.value,
		"tela_cheia": check_tela_cheia.button_pressed,
	}
	var arquivo := FileAccess.open(CAMINHO_CONFIG, FileAccess.WRITE)
	if arquivo == null:
		return
	arquivo.store_string(JSON.stringify(dados, "\t"))
	arquivo.close()


func _carregar_config() -> void:
	if not FileAccess.file_exists(CAMINHO_CONFIG):
		# Sem arquivo ainda: usa valores padrão e aplica.
		_aplicar_volume("Music", slider_musica.value)
		_aplicar_volume("SFX", slider_efeitos.value)
		return
	var arquivo := FileAccess.open(CAMINHO_CONFIG, FileAccess.READ)
	if arquivo == null:
		return
	var resultado = JSON.parse_string(arquivo.get_as_text())
	arquivo.close()
	if not (resultado is Dictionary):
		return

	# Aplica os valores salvos aos controles (sem disparar os sinais em cascata,
	# definimos o valor e aplicamos manualmente).
	slider_musica.value = resultado.get("musica", 0.8)
	slider_efeitos.value = resultado.get("efeitos", 0.8)
	check_tela_cheia.button_pressed = resultado.get("tela_cheia", false)

	_aplicar_volume("Music", slider_musica.value)
	_aplicar_volume("SFX", slider_efeitos.value)
	if check_tela_cheia.button_pressed:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
