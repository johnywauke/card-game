## Enemy.gd
## Um Combatant controlado pela IA. Usa um EnemyData para saber seus moves,
## escolhe uma "intenção" a cada turno (telegrafada ao jogador) e a executa.
##
## A CombatStateMachine chama:
##   - escolher_intencao()        -> decide o próximo move (e emite sinal pra UI)
##   - executar_intencao(jogador) -> aplica o move escolhido
class_name Enemy
extends Combatant

## Sinal emitido quando a intenção muda, para o IntentDisplay mostrar o ícone.
## intencao é o dicionário do move atual (ex: {"tipo":"atacar","valor":6}).
signal intencao_alterada(intencao: Dictionary)

## Dados deste inimigo (atribua um .tres no Inspector).
@export var dados: EnemyData

## Move escolhido para o próximo turno.
var intencao_atual: Dictionary = {}

## Índice usado quando o padrão é SEQUENCIAL.
var _indice_seq: int = 0

## Marca se o chefe já enfureceu (para aplicar o buff só uma vez).
var _enfurecido: bool = false


func _ready() -> void:
	eh_jogador = false
	# Configura a partir do EnemyData antes de inicializar a vida.
	if dados != null:
		hp_max = dados.hp_max
		nome_exibicao = dados.nome
	super._ready() # define hp_atual = hp_max


## (Re)configura o inimigo a partir de um EnemyData. Útil quando o setup
## define os dados depois do _ready (ex: CombatSetup). Reseta o HP cheio.
func aplicar_dados(novos_dados: EnemyData) -> void:
	dados = novos_dados
	if dados == null:
		return
	hp_max = dados.hp_max
	nome_exibicao = dados.nome
	hp_atual = hp_max
	_indice_seq = 0
	_enfurecido = false


## Escolhe o próximo move conforme o padrão de IA e avisa a UI.
func escolher_intencao() -> void:
	if dados == null or dados.intencoes.is_empty():
		intencao_atual = {}
		return

	match dados.padrao:
		EnemyData.PadraoIA.ALEATORIO:
			intencao_atual = dados.intencoes[randi() % dados.intencoes.size()]
		EnemyData.PadraoIA.SEQUENCIAL, _:
			intencao_atual = dados.intencoes[_indice_seq]
			_indice_seq = (_indice_seq + 1) % dados.intencoes.size()

	intencao_alterada.emit(intencao_atual)


## Executa o move atual contra o jogador.
func executar_intencao(jogador: Combatant) -> void:
	if intencao_atual.is_empty():
		return

	var tipo: String = intencao_atual.get("tipo", "")
	match tipo:
		"atacar":
			var dano := calcular_dano_ataque(intencao_atual.get("valor", 0))
			jogador.receber_dano(dano)

		"atacar_multiplo":
			var base: int = intencao_atual.get("valor", 0)
			var vezes: int = intencao_atual.get("vezes", 1)
			for i in vezes:
				if jogador.esta_vivo():
					jogador.receber_dano(calcular_dano_ataque(base))

		"defender":
			ganhar_bloqueio(intencao_atual.get("valor", 0))

		"atacar_defender":
			# Ataca E ganha bloqueio no mesmo turno.
			jogador.receber_dano(calcular_dano_ataque(intencao_atual.get("valor", 0)))
			ganhar_bloqueio(intencao_atual.get("bloqueio", 0))

		"atacar_status":
			# Ataca e aplica um status no jogador (ex: veneno, vulneravel, fraqueza).
			jogador.receber_dano(calcular_dano_ataque(intencao_atual.get("valor", 0)))
			var st := StringName(intencao_atual.get("status", "veneno"))
			jogador.aplicar_status(st, intencao_atual.get("status_valor", 1))

		"defender_buff":
			# Ganha bloqueio e se fortalece.
			ganhar_bloqueio(intencao_atual.get("bloqueio", 0))
			var bchave := StringName(intencao_atual.get("status", "forca"))
			aplicar_status(bchave, intencao_atual.get("valor", 1))

		"buff":
			var chave := StringName(intencao_atual.get("status", "forca"))
			aplicar_status(chave, intencao_atual.get("valor", 0))

		"debuff":
			var chave := StringName(intencao_atual.get("status", "fraqueza"))
			jogador.aplicar_status(chave, intencao_atual.get("valor", 0))

		_:
			push_warning("Enemy: intenção desconhecida '%s'." % tipo)


## Recebe dano e, se for um chefe que enfurece, checa o limiar de 50%.
func receber_dano(quantidade: int) -> int:
	var resultado := super(quantidade)
	_checar_enfurecer()
	return resultado


## Ao cair em 50% ou menos do HP, ganha Força uma única vez (mecânica de chefe).
func _checar_enfurecer() -> void:
	if dados == null or not dados.enfurece or _enfurecido:
		return
	if hp_atual > 0 and hp_atual <= hp_max / 2.0:
		_enfurecido = true
		aplicar_status(&"forca", dados.enfurece_forca)
