## CombatFeedback.gd
## Dá vida ao combate: escuta os sinais do SignalBus e dispara feedback visual.
##  - Número flutuante de dano (vermelho), cura (verde) e bloqueio (azul) que
##    sobe e some sobre o sprite do alvo.
##  - "Tremor" + flash vermelho no sprite de quem recebe dano.
##  - Pequeno "pulo"/escala no sprite de quem ataca (impacto).
##
## É instanciado pelo CombatSetup, que liga os sprites e combatentes via configurar().
extends Node

var jogador: Combatant
var inimigo: Combatant
var heroi_sprite: Sprite2D
var inimigo_sprite: Sprite2D

# Posições originais dos sprites (para restaurar após o tremor).
var _pos_heroi: Vector2
var _pos_inimigo: Vector2
var _escala_heroi: Vector2
var _escala_inimigo: Vector2

# Camada dedicada para os números flutuantes (coordenadas de tela confiáveis).
var _camada_numeros: CanvasLayer


func _ready() -> void:
	_camada_numeros = CanvasLayer.new()
	_camada_numeros.layer = 40  # acima da HUD e da mão.
	add_child(_camada_numeros)


func configurar(p_jogador: Combatant, p_inimigo: Combatant, p_heroi_sprite: Sprite2D, p_inimigo_sprite: Sprite2D) -> void:
	jogador = p_jogador
	inimigo = p_inimigo
	heroi_sprite = p_heroi_sprite
	inimigo_sprite = p_inimigo_sprite

	if heroi_sprite != null:
		_pos_heroi = heroi_sprite.position
		_escala_heroi = heroi_sprite.scale
	if inimigo_sprite != null:
		_pos_inimigo = inimigo_sprite.position
		_escala_inimigo = inimigo_sprite.scale

	SignalBus.dano_causado.connect(_ao_dano)
	SignalBus.bloqueio_ganho.connect(_ao_bloqueio)
	SignalBus.cura_recebida.connect(_ao_cura)


## Sprite correspondente a um combatente.
func _sprite_de(alvo) -> Sprite2D:
	if alvo == jogador:
		return heroi_sprite
	elif alvo == inimigo:
		return inimigo_sprite
	return null


# --- Reações aos sinais ---

func _ao_dano(alvo, quantidade: int) -> void:
	if quantidade <= 0:
		return
	var spr := _sprite_de(alvo)
	if spr == null:
		return
	_numero_flutuante(spr, "-%d" % quantidade, Color(1.0, 0.3, 0.25))
	_tremer(spr)
	_flash(spr, Color(1.0, 0.4, 0.4))


func _ao_bloqueio(alvo, quantidade: int) -> void:
	# Só mostra ganho de bloqueio positivo (ignora limpeza/absorção).
	if quantidade <= 0:
		return
	var spr := _sprite_de(alvo)
	if spr == null:
		return
	_numero_flutuante(spr, "+%d 🛡" % quantidade, Color(0.5, 0.7, 1.0))


func _ao_cura(alvo, quantidade: int) -> void:
	if quantidade <= 0:
		return
	var spr := _sprite_de(alvo)
	if spr == null:
		return
	_numero_flutuante(spr, "+%d ❤" % quantidade, Color(0.4, 1.0, 0.4))
	_flash(spr, Color(0.6, 1.0, 0.6))


# --- Animações ---

## Cria um Label que sobe e some sobre o sprite.
func _numero_flutuante(spr: Sprite2D, texto: String, cor: Color) -> void:
	var lbl := Label.new()
	lbl.text = texto
	lbl.add_theme_font_size_override("font_size", 40)
	lbl.add_theme_color_override("font_color", cor)
	lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	lbl.add_theme_constant_override("outline_size", 6)
	lbl.z_index = 50
	lbl.position = spr.global_position + Vector2(-20, -90)
	_camada_numeros.add_child(lbl)

	var alvo_y := lbl.position + Vector2(0, -70)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(lbl, "position", alvo_y, 0.9).set_ease(Tween.EASE_OUT)
	tween.tween_property(lbl, "modulate:a", 0.0, 0.9).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(func() -> void:
		if is_instance_valid(lbl):
			lbl.queue_free())


## Faz o sprite "tremer" rapidamente e volta à posição original.
func _tremer(spr: Sprite2D) -> void:
	var base := _pos_heroi if spr == heroi_sprite else _pos_inimigo
	var tween := create_tween()
	for i in 4:
		var desvio := Vector2(randf_range(-12, 12), randf_range(-6, 6))
		tween.tween_property(spr, "position", base + desvio, 0.04)
	tween.tween_property(spr, "position", base, 0.05)


## Pisca o sprite na cor dada e volta ao normal.
func _flash(spr: Sprite2D, cor: Color) -> void:
	var tween := create_tween()
	tween.tween_property(spr, "modulate", cor, 0.06)
	tween.tween_property(spr, "modulate", Color.WHITE, 0.18)


## Efeito de "impacto" no atacante (pequeno avanço e volta). Público para o
## CombatStateMachine/CombatSetup chamar ao jogar uma carta de ataque, se quiser.
func impacto_ataque(eh_jogador: bool) -> void:
	var spr := heroi_sprite if eh_jogador else inimigo_sprite
	if spr == null:
		return
	var base := _pos_heroi if eh_jogador else _pos_inimigo
	var frente := base + Vector2(40 if eh_jogador else -40, 0)
	var tween := create_tween()
	tween.tween_property(spr, "position", frente, 0.08).set_ease(Tween.EASE_OUT)
	tween.tween_property(spr, "position", base, 0.12).set_ease(Tween.EASE_IN)
