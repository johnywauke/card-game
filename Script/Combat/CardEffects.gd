## CardEffects.gd
## Traduz uma CardData em ações concretas durante o combate.
## Centraliza "o que cada carta faz", separando regras de jogo da máquina de turnos.
##
## Uso (a partir da máquina de combate):
##   CardEffects.executar(carta, jogador, alvo, todos_inimigos)
class_name CardEffects
extends RefCounted


## Executa uma carta.
##   carta          -> a CardData jogada
##   usuario        -> quem jogou (normalmente o jogador)
##   alvo           -> Combatant alvo escolhido (pode ser null se a carta não mira)
##   todos_inimigos -> lista de Combatant para cartas que atingem todos
static func executar(carta: CardData, usuario: Combatant, alvo: Combatant, todos_inimigos: Array) -> void:
	# 1) Consome Fervor exigido (a checagem de "tem fervor" é feita antes de jogar).
	if carta.fervor_custo > 0:
		usuario.aplicar_status(&"fervor", -carta.fervor_custo)

	# 2) Concede Fervor, se houver.
	if carta.fervor_ganho > 0:
		usuario.aplicar_status(&"fervor", carta.fervor_ganho)
		SignalBus.fervor_alterado.emit(usuario.get_status(&"fervor"))

	# 3) Efeito principal por tipo de carta.
	match carta.tipo:
		CardData.CardType.ATAQUE:
			_aplicar_dano(carta, usuario, alvo, todos_inimigos)
		CardData.CardType.DEFESA:
			usuario.ganhar_bloqueio(carta.valor_base)
		CardData.CardType.HABILIDADE, CardData.CardType.PODER:
			pass # Habilidades/Poderes agem só pelos efeitos extras abaixo.

	# 4) Efeitos extras (lista flexível definida na carta).
	for efeito in carta.efeitos:
		_aplicar_efeito_extra(efeito, usuario, alvo, todos_inimigos)


## Resolve o dano de uma carta de ataque, considerando o alvo (único ou todos).
static func _aplicar_dano(carta: CardData, usuario: Combatant, alvo: Combatant, todos_inimigos: Array) -> void:
	var dano := usuario.calcular_dano_ataque(carta.valor_base)
	if carta.alvo == CardData.Target.TODOS_INIMIGOS:
		for inimigo in todos_inimigos:
			if inimigo != null and inimigo.esta_vivo():
				inimigo.receber_dano(dano)
	else:
		if alvo != null and alvo.esta_vivo():
			alvo.receber_dano(dano)


## Interpreta um dicionário de efeito extra. Cada efeito tem uma chave "tipo".
## Exemplos suportados:
##   { "tipo": "aplicar_status", "status": "veneno", "valor": 2, "alvo": "inimigo" }
##   { "tipo": "comprar_carta", "valor": 1 }
##   { "tipo": "bloqueio", "valor": 5 }
##   { "tipo": "dano_por_fervor", "multiplicador": 3 }  # gasta todo o fervor
static func _aplicar_efeito_extra(efeito: Dictionary, usuario: Combatant, alvo: Combatant, todos_inimigos: Array) -> void:
	var tipo: String = efeito.get("tipo", "")
	match tipo:
		"aplicar_status":
			var chave := StringName(efeito.get("status", ""))
			var valor: int = efeito.get("valor", 0)
			var quem_str: String = efeito.get("alvo", "inimigo")
			var quem := alvo if quem_str == "inimigo" else usuario
			if quem != null:
				quem.aplicar_status(chave, valor)

		"comprar_carta":
			var qtd: int = efeito.get("valor", 1)
			DeckManager.comprar_cartas(qtd)

		"bloqueio":
			usuario.ganhar_bloqueio(efeito.get("valor", 0))

		"escamas":
			# Escamas: armadura persistente (não some no fim do turno).
			usuario.aplicar_status(&"escamas", efeito.get("valor", 0))

		"cura":
			usuario.curar(efeito.get("valor", 0))

		"dano":
			# Golpe de dano adicional (permite cartas de golpe múltiplo).
			# alvo: "inimigo" (o alvo mirado) ou "todos".
			var d := usuario.calcular_dano_ataque(efeito.get("valor", 0))
			var quem_str: String = efeito.get("alvo", "inimigo")
			if quem_str == "todos":
				for inimigo in todos_inimigos:
					if inimigo != null and inimigo.esta_vivo():
						inimigo.receber_dano(d)
			else:
				if alvo != null and alvo.esta_vivo():
					alvo.receber_dano(d)

		"dano_por_fervor":
			# Gasta todo o Fervor e causa dano proporcional a TODOS os inimigos.
			var mult: int = efeito.get("multiplicador", 1)
			var fervor := usuario.get_status(&"fervor")
			var dano := fervor * mult
			usuario.aplicar_status(&"fervor", -fervor)
			SignalBus.fervor_alterado.emit(0)
			for inimigo in todos_inimigos:
				if inimigo != null and inimigo.esta_vivo():
					inimigo.receber_dano(dano)

		_:
			push_warning("CardEffects: efeito desconhecido '%s'." % tipo)


## Aplica um efeito recorrente (de um dragão invocado) a cada turno.
## Escolhe o primeiro inimigo vivo como alvo para efeitos de dano único.
static func aplicar_efeito_recorrente(efeito: Dictionary, jogador: Combatant, inimigos: Array) -> void:
	var alvo: Combatant = null
	for inimigo in inimigos:
		if inimigo != null and inimigo.esta_vivo():
			alvo = inimigo
			break
	_aplicar_efeito_extra(efeito, jogador, alvo, inimigos)
