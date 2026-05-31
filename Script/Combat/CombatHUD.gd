## CombatHUD.gd
## Controla a interface do combate (Etapa 1): barras de HP do jogador e do
## inimigo, energia, fervor, intenção do inimigo e o botão "Terminar Turno".
##
## Não contém regras de jogo: apenas ESCUTA os sinais do SignalBus e atualiza
## os textos/barras. Quem manda nas regras é a CombatStateMachine.
##
## Ligação: este script fica no nó raiz da cena Combat. Ele recebe referências
## ao jogador, ao inimigo e à máquina de combate via configurar().
extends Control

# --- Referências de nós da UI (ajuste os caminhos conforme a árvore da cena) ---
@onready var barra_hp_jogador: ProgressBar = $HUD/PainelJogador/BarraHP
@onready var label_hp_jogador: Label = $HUD/PainelJogador/BarraHP/LabelHP
@onready var label_bloqueio_jogador: Label = $HUD/PainelJogador/LabelBloqueio
@onready var label_energia: Label = $HUD/PainelJogador/LabelEnergia
@onready var label_fervor: Label = $HUD/PainelJogador/LabelFervor

@onready var barra_hp_inimigo: ProgressBar = $HUD/PainelInimigo/BarraHP
@onready var label_hp_inimigo: Label = $HUD/PainelInimigo/BarraHP/LabelHP
@onready var label_bloqueio_inimigo: Label = $HUD/PainelInimigo/LabelBloqueio
@onready var label_intencao: Label = $HUD/PainelInimigo/LabelIntencao

@onready var botao_terminar: Button = $HUD/BotaoTerminarTurno

# --- Referências de lógica ---
var jogador: Combatant
var inimigo: Enemy
var maquina: CombatStateMachine


func _ready() -> void:
	# Conecta aos sinais globais de combate.
	SignalBus.hp_alterado.connect(_ao_hp_alterado)
	SignalBus.bloqueio_ganho.connect(_ao_bloqueio_alterado)
	SignalBus.energia_alterada.connect(_ao_energia_alterada)
	SignalBus.fervor_alterado.connect(_ao_fervor_alterado)
	SignalBus.combate_vencido.connect(_ao_vitoria)
	SignalBus.combate_perdido.connect(_ao_derrota)
	SignalBus.turno_jogador_iniciado.connect(_ao_turno_jogador)
	SignalBus.turno_inimigo_iniciado.connect(_ao_turno_inimigo)

	botao_terminar.pressed.connect(_ao_clicar_terminar)


## Chamado por quem monta o combate, passando as referências prontas.
func configurar(p_jogador: Combatant, p_inimigo: Enemy, p_maquina: CombatStateMachine) -> void:
	jogador = p_jogador
	inimigo = p_inimigo
	maquina = p_maquina

	# Liga o display de intenção do inimigo.
	if inimigo != null:
		inimigo.intencao_alterada.connect(_ao_intencao_alterada)

	_atualizar_tudo()


## Atualiza todos os elementos de uma vez (estado inicial).
func _atualizar_tudo() -> void:
	if jogador != null:
		_set_barra(barra_hp_jogador, label_hp_jogador, jogador.hp_atual, jogador.hp_max)
		label_bloqueio_jogador.text = _texto_bloqueio(jogador)
		label_fervor.text = "Fervor: %d" % jogador.get_status(&"fervor")
	if inimigo != null:
		_set_barra(barra_hp_inimigo, label_hp_inimigo, inimigo.hp_atual, inimigo.hp_max)
		label_bloqueio_inimigo.text = "Bloqueio: %d" % inimigo.bloqueio


# --- Reações aos sinais ---

func _ao_hp_alterado(alvo, hp_atual: int, hp_max: int) -> void:
	if alvo == jogador:
		_set_barra(barra_hp_jogador, label_hp_jogador, hp_atual, hp_max)
	elif alvo == inimigo:
		_set_barra(barra_hp_inimigo, label_hp_inimigo, hp_atual, hp_max)


func _ao_bloqueio_alterado(alvo, _quantidade: int) -> void:
	# Lê o valor atual direto do combatente (mais simples que somar deltas).
	if alvo == jogador:
		label_bloqueio_jogador.text = _texto_bloqueio(jogador)
	elif alvo == inimigo:
		label_bloqueio_inimigo.text = "Bloqueio: %d" % inimigo.bloqueio


## Texto do bloqueio do jogador, incluindo Escamas (armadura) se houver.
func _texto_bloqueio(c: Combatant) -> String:
	var escamas := c.get_status(&"escamas")
	if escamas > 0:
		return "Bloqueio: %d  (Escamas: %d)" % [c.bloqueio, escamas]
	return "Bloqueio: %d" % c.bloqueio


func _ao_energia_alterada(atual: int, maximo: int) -> void:
	label_energia.text = "Energia: %d/%d" % [atual, maximo]


func _ao_fervor_alterado(atual: int) -> void:
	label_fervor.text = "Fervor: %d" % atual


func _ao_intencao_alterada(intencao: Dictionary) -> void:
	label_intencao.text = _texto_intencao(intencao)


## Converte o dicionário de intenção em texto legível com ícone.
func _texto_intencao(intencao: Dictionary) -> String:
	var tipo: String = intencao.get("tipo", "")
	match tipo:
		"atacar":
			return "🗡 %d" % intencao.get("valor", 0)
		"atacar_multiplo":
			return "🗡 %dx%d" % [intencao.get("valor", 0), intencao.get("vezes", 1)]
		"defender":
			return "🛡 %d" % intencao.get("valor", 0)
		"atacar_defender":
			return "🗡 %d / 🛡 %d" % [intencao.get("valor", 0), intencao.get("bloqueio", 0)]
		"atacar_status":
			return "🗡 %d ☠" % intencao.get("valor", 0)
		"defender_buff":
			return "🛡 %d ✨" % intencao.get("bloqueio", 0)
		"buff":
			return "✨ Fortalecendo"
		"debuff":
			return "☠ Enfraquecendo"
		_:
			return "?"


func _ao_turno_jogador() -> void:
	botao_terminar.disabled = false
	_atualizar_tudo()


func _ao_turno_inimigo() -> void:
	# Durante o turno do inimigo o jogador não age.
	botao_terminar.disabled = true


func _ao_clicar_terminar() -> void:
	if maquina != null:
		maquina.terminar_turno_jogador()


func _ao_vitoria() -> void:
	botao_terminar.disabled = true
	label_intencao.text = "Vitória!"


func _ao_derrota() -> void:
	botao_terminar.disabled = true
	label_intencao.text = "Derrota..."


# --- Utilitário ---

func _set_barra(barra: ProgressBar, label: Label, atual: int, maximo: int) -> void:
	barra.max_value = maximo
	barra.value = atual
	label.text = "%d/%d" % [atual, maximo]
