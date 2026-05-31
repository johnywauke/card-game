## DeckManager.gd
## Gerencia as três pilhas de cartas durante um combate:
##   - monte_compra: de onde o jogador compra cartas
##   - mao: cartas atualmente na mão
##   - descarte: cartas já jogadas ou descartadas no turno
##
## Regras (padrão deckbuilder estilo Slay the Spire):
##   - No início do combate, o baralho completo é embaralhado no monte de compra.
##   - Ao comprar, se o monte de compra acabar, o descarte é reembaralhado nele.
##   - No fim do turno, a mão inteira vai para o descarte.
##
## CONFIGURAÇÃO: pode ser usado como Autoload OU instanciado por combate.
## Recomendado como Autoload para acesso global durante a run:
##   Project -> Project Settings -> Globals/Autoload
##   Path: res://Script/Globals/DeckManager.gd   |   Nome: DeckManager
extends Node

## Baralho mestre da run (todas as cartas que o jogador possui).
## Não é mexido durante o combate; serve de base para montar o monte de compra.
var baralho_mestre: Array[CardData] = []

## Pilhas ativas durante o combate.
var monte_compra: Array[CardData] = []
var mao: Array[CardData] = []
var descarte: Array[CardData] = []

## Tamanho padrão da mão por turno.
var tamanho_mao: int = 5

## --- Estado da RUN (persiste entre combates) ---
## Marca se uma run está em andamento. CombatSetup usa isto para decidir se
## monta um baralho novo ou reaproveita o da run em curso.
var run_iniciada: bool = false
## HP do jogador carregado entre combates.
var hp_jogador: int = 70
var hp_max_jogador: int = 70

# Baralho inicial padrão do Espadachin (caminho -> quantidade).
## --- Baralhos iniciais por classe ---
const _DECK_ESPADACHIN := {
	"res://Resources/Cards/corte.tres": 5,
	"res://Resources/Cards/defender.tres": 4,
	"res://Resources/Cards/quebra_guarda.tres": 1,
}
const _DECK_DRAGAO := {
	"res://Resources/Cards/Dragao/d13.tres": 4,  # Sopro Flamejante
	"res://Resources/Cards/Dragao/d01.tres": 4,  # Escama Endurecida
	"res://Resources/Cards/Dragao/d03.tres": 1,  # Pele de Dragão (Escamas)
	"res://Resources/Cards/Dragao/d28.tres": 1,  # Filhote de Fogo (invocação)
}

## --- Pools de recompensa por classe (cartas que podem aparecer pós-combate) ---
const _POOL_ESPADACHIN := [
	"res://Resources/Cards/investida_pesada.tres",
	"res://Resources/Cards/talho_duplo.tres",
	"res://Resources/Cards/postura_de_ferro.tres",
	"res://Resources/Cards/grito_de_guerra.tres",
	"res://Resources/Cards/segundo_folego.tres",
	"res://Resources/Cards/rodopio.tres",
	"res://Resources/Cards/decapitar.tres",
]
# Para o dragão, sorteamos de quase todo o conjunto (exceto as do baralho base).
const _POOL_DRAGAO := [
	"res://Resources/Cards/Dragao/d04.tres", "res://Resources/Cards/Dragao/d06.tres",
	"res://Resources/Cards/Dragao/d09.tres", "res://Resources/Cards/Dragao/d10.tres",
	"res://Resources/Cards/Dragao/d12.tres", "res://Resources/Cards/Dragao/d18.tres",
	"res://Resources/Cards/Dragao/d21.tres", "res://Resources/Cards/Dragao/d22.tres",
	"res://Resources/Cards/Dragao/d24.tres", "res://Resources/Cards/Dragao/d27.tres",
	"res://Resources/Cards/Dragao/d29.tres", "res://Resources/Cards/Dragao/d30.tres",
	"res://Resources/Cards/Dragao/d32.tres", "res://Resources/Cards/Dragao/d33.tres",
	"res://Resources/Cards/Dragao/d36.tres", "res://Resources/Cards/Dragao/d37.tres",
	"res://Resources/Cards/Dragao/d41.tres", "res://Resources/Cards/Dragao/d43.tres",
	"res://Resources/Cards/Dragao/d48.tres", "res://Resources/Cards/Dragao/d50.tres",
]

## Classe escolhida para a run atual ("espadachin" ou "dragao").
var classe_atual: String = "espadachin"


## Define o baralho da run (chamado ao iniciar uma partida).
## Faz cópias independentes de cada carta para evitar efeitos colaterais.
func definir_baralho(cartas: Array[CardData]) -> void:
	baralho_mestre.clear()
	for c in cartas:
		baralho_mestre.append(c.duplicar())


## Adiciona uma carta nova ao baralho mestre (recompensa pós-combate / loja).
func adicionar_carta(carta: CardData) -> void:
	baralho_mestre.append(carta.duplicar())


## Inicia uma nova run com a classe escolhida ("espadachin" ou "dragao").
## Monta o baralho inicial correspondente e reseta o HP.
func iniciar_run(classe: String = "espadachin") -> void:
	classe_atual = classe
	var deck_def: Dictionary = _DECK_DRAGAO if classe == "dragao" else _DECK_ESPADACHIN
	var inicial: Array[CardData] = []
	for caminho in deck_def:
		var carta := load(caminho) as CardData
		if carta != null:
			for i in deck_def[caminho]:
				inicial.append(carta)
	definir_baralho(inicial)
	hp_max_jogador = 70
	hp_jogador = 70
	run_iniciada = true


## Encerra a run atual (chamado no game over).
func encerrar_run() -> void:
	run_iniciada = false


## Sorteia até n cartas distintas do pool de recompensas da classe atual.
func sortear_recompensas(n: int = 3) -> Array[CardData]:
	var pool: Array = (_POOL_DRAGAO if classe_atual == "dragao" else _POOL_ESPADACHIN).duplicate()
	pool.shuffle()
	var resultado: Array[CardData] = []
	for i in min(n, pool.size()):
		var carta := load(pool[i]) as CardData
		if carta != null:
			resultado.append(carta)
	return resultado


## Prepara as pilhas para um novo combate.
## Copia o baralho mestre para o monte de compra e embaralha.
func iniciar_combate() -> void:
	monte_compra.clear()
	mao.clear()
	descarte.clear()
	for c in baralho_mestre:
		monte_compra.append(c.duplicar())
	embaralhar_monte_compra()


## Embaralha o monte de compra no lugar.
func embaralhar_monte_compra() -> void:
	monte_compra.shuffle()


## Compra UMA carta do monte de compra para a mão.
## Se o monte estiver vazio, reembaralha o descarte nele primeiro.
## Retorna a carta comprada, ou null se não houver cartas em lugar nenhum.
func comprar_carta() -> CardData:
	if monte_compra.is_empty():
		_reembaralhar_descarte_no_monte()
	if monte_compra.is_empty():
		return null  ## Sem cartas em nenhuma pilha.

	var carta: CardData = monte_compra.pop_back()
	mao.append(carta)
	SignalBus.carta_comprada.emit(carta)
	SignalBus.mao_alterada.emit()
	return carta


## Compra várias cartas de uma vez (ex: no início do turno).
func comprar_cartas(quantidade: int) -> void:
	for i in quantidade:
		comprar_carta()


## Compra cartas até a mão atingir o tamanho padrão.
func comprar_mao_inicial() -> void:
	var faltam: int = tamanho_mao - mao.size()
	if faltam > 0:
		comprar_cartas(faltam)


## Move uma carta específica da mão para o descarte (ao jogá-la).
func descartar_carta(carta: CardData) -> void:
	var idx: int = mao.find(carta)
	if idx == -1:
		push_warning("DeckManager: tentativa de descartar carta que não está na mão.")
		return
	mao.remove_at(idx)
	descarte.append(carta)
	SignalBus.carta_descartada.emit(carta)
	SignalBus.mao_alterada.emit()


## Descarta a mão inteira (chamado no fim do turno do jogador).
func descartar_mao() -> void:
	for carta in mao:
		descarte.append(carta)
		SignalBus.carta_descartada.emit(carta)
	mao.clear()
	SignalBus.mao_alterada.emit()


## Move todo o descarte de volta para o monte de compra e embaralha.
func _reembaralhar_descarte_no_monte() -> void:
	if descarte.is_empty():
		return
	for carta in descarte:
		monte_compra.append(carta)
	descarte.clear()
	embaralhar_monte_compra()


## --- Consultas úteis (para UI / debug) ---

func qtd_monte_compra() -> int:
	return monte_compra.size()

func qtd_mao() -> int:
	return mao.size()

func qtd_descarte() -> int:
	return descarte.size()
