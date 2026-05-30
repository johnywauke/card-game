## SignalBus.gd
## Barramento central de sinais (eventos) do jogo.
## Em vez de nós conhecerem uns aos outros diretamente, eles emitem e escutam
## sinais aqui. Isso desacopla o código: a UI pode reagir a "dano_causado"
## sem precisar de referência direta ao sistema de combate.
##
## CONFIGURAÇÃO: registre este script como Autoload (Singleton) no Godot:
##   Project -> Project Settings -> Globals/Autoload
##   Path: res://Script/Globals/SignalBus.gd   |   Nome: SignalBus
##
## Uso:
##   SignalBus.carta_jogada.emit(carta)
##   SignalBus.carta_jogada.connect(_minha_funcao)
extends Node

## --- Cartas / Mão ---
signal carta_comprada(carta: CardData)
signal carta_jogada(carta: CardData)
signal carta_descartada(carta: CardData)
signal mao_alterada                      ## Emite quando a mão muda (para a UI redesenhar).

## --- Combate: vida e dano ---
signal dano_causado(alvo, quantidade: int)     ## alvo pode ser jogador ou inimigo.
signal bloqueio_ganho(alvo, quantidade: int)
signal hp_alterado(alvo, hp_atual: int, hp_max: int)
signal inimigo_morreu(inimigo)
signal jogador_morreu

## --- Recursos ---
signal energia_alterada(atual: int, maximo: int)
signal fervor_alterado(atual: int)             ## Mecânica da Devota da Aurora.

## --- Fluxo de turnos ---
signal combate_iniciado
signal turno_jogador_iniciado
signal turno_jogador_terminado
signal turno_inimigo_iniciado
signal turno_inimigo_terminado
signal combate_vencido
signal combate_perdido

## --- Status / Efeitos ---
signal status_aplicado(alvo, status: StringName, valor: int)
