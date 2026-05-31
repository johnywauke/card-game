## Combatant.gd
## Classe base para qualquer participante de um combate: o jogador e os inimigos.
## Gerencia vida (HP), bloqueio (escudo temporário), dano, cura e status.
##
## É um Node para poder ser anexado a uma cena (com sprite, animações etc.),
## mas toda a LÓGICA de combate vive aqui. A parte visual escuta os sinais
## do SignalBus e reage.
class_name Combatant
extends Node

## --- Vida ---
@export var hp_max: int = 70
var hp_atual: int

## --- Bloqueio ---
## Escudo temporário. Absorve dano e zera no início do próximo turno do dono.
var bloqueio: int = 0

## --- Status / Efeitos ativos ---
## Dicionário { StringName: int }, ex: { &"veneno": 3, &"forca": 2 }.
## O valor representa intensidade (Força) ou duração/quantidade (Veneno).
var status: Dictionary = {}

## Nome para exibição e debug.
@export var nome_exibicao: String = "Combatente"

## Marque como true no Inspector para o combatente controlado pelo jogador.
## Evita acoplar esta classe base às subclasses de inimigo.
@export var eh_jogador: bool = false


func _ready() -> void:
	hp_atual = hp_max


## --- Vida e morte ---

func esta_vivo() -> bool:
	return hp_atual > 0


## Aplica dano levando em conta bloqueio e status (Vulnerável).
## Retorna o dano efetivamente aplicado ao HP (após o bloqueio).
func receber_dano(quantidade: int) -> int:
	if quantidade <= 0:
		return 0

	# Vulnerável aumenta o dano recebido em 50%.
	if tem_status(&"vulneravel"):
		quantidade = int(round(quantidade * 1.5))

	# O bloqueio absorve primeiro.
	var dano_restante := quantidade
	if bloqueio > 0:
		var absorvido: int = min(bloqueio, dano_restante)
		bloqueio -= absorvido
		dano_restante -= absorvido
		SignalBus.bloqueio_ganho.emit(self, -absorvido)

	if dano_restante > 0:
		hp_atual = max(hp_atual - dano_restante, 0)
		SignalBus.dano_causado.emit(self, dano_restante)
		SignalBus.hp_alterado.emit(self, hp_atual, hp_max)

	if not esta_vivo():
		_morrer()

	return dano_restante


## Cura HP, sem ultrapassar o máximo.
func curar(quantidade: int) -> void:
	if quantidade <= 0 or not esta_vivo():
		return
	hp_atual = min(hp_atual + quantidade, hp_max)
	SignalBus.hp_alterado.emit(self, hp_atual, hp_max)


func _morrer() -> void:
	if eh_jogador:
		SignalBus.jogador_morreu.emit()
	else:
		SignalBus.inimigo_morreu.emit(self)


## --- Bloqueio ---

## Adiciona bloqueio, considerando o status Destreza (+bloqueio).
func ganhar_bloqueio(quantidade: int) -> void:
	if quantidade <= 0:
		return
	if tem_status(&"destreza"):
		quantidade += get_status(&"destreza")
	bloqueio += quantidade
	SignalBus.bloqueio_ganho.emit(self, quantidade)


## Zera o bloqueio (chamado no início do turno do dono).
## Com Escamas, o bloqueio não vai a zero: volta ao valor de Escamas
## (armadura persistente do dragão). Sem Escamas, zera normalmente.
func limpar_bloqueio() -> void:
	bloqueio = get_status(&"escamas")
	SignalBus.bloqueio_ganho.emit(self, 0)


## --- Status / Efeitos ---

func tem_status(chave: StringName) -> bool:
	return status.has(chave) and status[chave] != 0


func get_status(chave: StringName) -> int:
	return status.get(chave, 0)


## Aplica (soma) um valor a um status. Use valores negativos para reduzir.
func aplicar_status(chave: StringName, valor: int) -> void:
	var novo := get_status(chave) + valor
	if novo == 0:
		status.erase(chave)
	else:
		status[chave] = novo
	SignalBus.status_aplicado.emit(self, chave, get_status(chave))


## Calcula o dano de saída de um ataque, aplicando Força (+) e Fraqueza (-25%).
func calcular_dano_ataque(base: int) -> int:
	var dano := base
	if tem_status(&"forca"):
		dano += get_status(&"forca")
	if tem_status(&"fraqueza"):
		dano = int(round(dano * 0.75))
	return max(dano, 0)


## Processa os status que agem no FIM do turno deste combatente
## (veneno causa dano; durações diminuem). Chamado pela máquina de combate.
func processar_status_fim_turno() -> void:
	# Veneno: perde HP igual ao valor, depois o valor cai 1.
	if tem_status(&"veneno"):
		var dano_veneno := get_status(&"veneno")
		hp_atual = max(hp_atual - dano_veneno, 0)
		SignalBus.dano_causado.emit(self, dano_veneno)
		SignalBus.hp_alterado.emit(self, hp_atual, hp_max)
		aplicar_status(&"veneno", -1)
		if not esta_vivo():
			_morrer()
			return

	# Regeneração: cura e cai 1.
	if tem_status(&"regeneracao"):
		curar(get_status(&"regeneracao"))
		aplicar_status(&"regeneracao", -1)

	# Status com duração em turnos: reduz 1.
	for chave in [&"vulneravel", &"fraqueza"]:
		if tem_status(chave):
			aplicar_status(chave, -1)