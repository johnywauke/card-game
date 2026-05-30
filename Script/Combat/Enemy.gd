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


func _ready() -> void:
	# Configura a partir do EnemyData antes de inicializar a vida.
	if dados != null:
		hp_max = dados.hp_max
		nome_exibicao = dados.nome
	eh_jogador = false
	super._ready() # define hp_atual = hp_max


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

		"buff":
			var chave := StringName(intencao_atual.get("status", "forca"))
			aplicar_status(chave, intencao_atual.get("valor", 0))

		"debuff":
			var chave := StringName(intencao_atual.get("status", "fraqueza"))
			jogador.aplicar_status(chave, intencao_atual.get("valor", 0))

		_:
			push_warning("Enemy: intenção desconhecida '%s'." % tipo)
