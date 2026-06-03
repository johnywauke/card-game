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

## --- Ouro e Relíquias (estado da run) ---
var ouro: int = 0
var reliquias: Array[RelicData] = []
var energia_max_jogador: int = 3

## --- Estado do MAPA ---
## O mapa é uma lista de andares; cada andar é uma lista de nós.
## Cada nó: { "tipo": String, "coluna": int, "ligacoes": Array[int] }
##   tipo  -> "combate" | "elite" | "fogueira" | "chefe"
##   coluna -> posição horizontal (para desenhar)
##   ligacoes -> índices (na coluna seguinte) que este nó alcança
var mapa: Array = []
## Andar atual onde o jogador está (-1 = ainda não entrou no mapa).
var andar_atual: int = -1
## Índice, dentro do andar atual, do nó escolhido pelo jogador.
var no_atual: int = -1
## Tipo do nó que está sendo jogado agora (para o combate saber se é elite/chefe).
var tipo_no_atual: String = "combate"

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
# Pool de recompensas do Dragão: curado para dar VARIEDADE e tiers claros.
# Mistura ataques, defesa, escamas, status, força/destreza, cura e invocações.
# A raridade de cada carta controla a frequência (ver sortear_recompensas).
const _POOL_DRAGAO := [
	# --- Comuns (preenchimento confiável) ---
	"res://Resources/Cards/Dragao/d22.tres", # Mordida Profunda (12 dano)
	"res://Resources/Cards/Dragao/d19.tres", # Garras Dilacerantes (3x2)
	"res://Resources/Cards/Dragao/d44.tres", # Brado de Guerra (+1 Força, 6 bloq)
	"res://Resources/Cards/Dragao/d47.tres", # Olhar Aterrorizante (3 Vulnerável)
	"res://Resources/Cards/Dragao/d45.tres", # Bater de Asas (compra 2)
	# --- Incomuns (sinergias e riders) ---
	"res://Resources/Cards/Dragao/d46.tres", # Sangue de Dragão (cura 8)
	"res://Resources/Cards/Dragao/d16.tres", # Chamas Persistentes (dano + queimadura)
	"res://Resources/Cards/Dragao/d17.tres", # Cuspe Ácido (dano + Vulnerável)
	"res://Resources/Cards/Dragao/d20.tres", # Cauda Esmagadora (dano + Fraqueza)
	"res://Resources/Cards/Dragao/d18.tres", # Investida do Dragão (16 dano)
	"res://Resources/Cards/Dragao/d04.tres", # Muralha de Escamas (14 bloq)
	"res://Resources/Cards/Dragao/d23.tres", # Voo Rasante (dano + bloq)
	"res://Resources/Cards/Dragao/d06.tres", # Reforço Ósseo (+3 Escamas)
	"res://Resources/Cards/Dragao/d37.tres", # Fúria Dracônica (+2 Força)
	"res://Resources/Cards/Dragao/d39.tres", # Sangue Ancestral (+1 Força/+1 Destreza)
	"res://Resources/Cards/Dragao/d40.tres", # Concentração Reptiliana (+2 Destreza)
	"res://Resources/Cards/Dragao/d10.tres", # Escamas Regenerativas (Escamas + cura)
	"res://Resources/Cards/Dragao/d27.tres", # Invocar Dragãozinho (5 dano x3)
	"res://Resources/Cards/Dragao/d32.tres", # Servo Flamejante (6 dano x3)
	"res://Resources/Cards/Dragao/d30.tres", # Guardião Alado (5 bloq x3)
	"res://Resources/Cards/Dragao/d35.tres", # Espírito do Dragão (cura 3 x3)
	# --- Raras (definem a build) ---
	"res://Resources/Cards/Dragao/d24.tres", # Explosão Ígnea (28 dano)
	"res://Resources/Cards/Dragao/d09.tres", # Casulo de Cristal (20 bloq)
	"res://Resources/Cards/Dragao/d12.tres", # Égide do Ancião (14 bloq + 3 Escamas)
	"res://Resources/Cards/Dragao/d41.tres", # Pacto Ancestral (+2 Força/+2 Destreza)
	"res://Resources/Cards/Dragao/d48.tres", # Ira do Cataclismo (18 a todos)
	"res://Resources/Cards/Dragao/d49.tres", # Renascer das Cinzas (cura 12 + Escamas)
	"res://Resources/Cards/Dragao/d29.tres", # Ninho de Dragões (4 a todos x3)
	"res://Resources/Cards/Dragao/d50.tres", # Avatar do Dragão Ancião (10 dano x3)
]

## Classe escolhida para a run atual ("espadachin" ou "dragao").
var classe_atual: String = "espadachin"

## Caminho do save local da run. "user://" é uma pasta segura do sistema
## (no Windows: %APPDATA%/Godot/app_userdata/card/).
const CAMINHO_SAVE: String = "user://savegame.json"
## Versão do formato de save (para migração futura, se mudarmos os campos).
const VERSAO_SAVE: int = 1

## --- Pools de inimigos por tipo de nó (usadas na geração do mapa) ---
const _INIMIGOS_BASICOS := [
	"res://Resources/Enemies/geleko.tres",
	"res://Resources/Enemies/cogumin.tres",
	"res://Resources/Enemies/vesporio.tres",
	"res://Resources/Enemies/casco.tres",
	"res://Resources/Enemies/espreitador.tres",
]
const _INIMIGOS_ELITE := [
	"res://Resources/Enemies/brutamonte.tres",
	"res://Resources/Enemies/naja.tres",
]
const _INIMIGO_CHEFE := "res://Resources/Enemies/guardiao_bronze.tres"


## Define o baralho da run (chamado ao iniciar uma partida).
## Faz cópias independentes de cada carta para evitar efeitos colaterais.
func definir_baralho(cartas: Array[CardData]) -> void:
	baralho_mestre.clear()
	for c in cartas:
		baralho_mestre.append(c.duplicar())


## Adiciona uma carta nova ao baralho mestre (recompensa pós-combate / loja).
func adicionar_carta(carta: CardData) -> void:
	baralho_mestre.append(carta.duplicar())


## --- Ouro e Relíquias ---

func ganhar_ouro(quantidade: int) -> void:
	ouro += quantidade


func comprar_reliquia(relic: RelicData) -> bool:
	if relic == null or ouro < relic.custo or possui_reliquia(relic):
		return false
	ouro -= relic.custo
	_adicionar_reliquia(relic)
	return true


func possui_reliquia(relic: RelicData) -> bool:
	for r in reliquias:
		if r.id == relic.id:
			return true
	return false


func _adicionar_reliquia(relic: RelicData) -> void:
	reliquias.append(relic)
	if relic.efeito_tipo == "hp_max":
		hp_max_jogador += relic.efeito_valor
		hp_jogador += relic.efeito_valor
	elif relic.efeito_tipo == "energia":
		energia_max_jogador += relic.efeito_valor


func bonus_reliquia(tipo: String) -> int:
	var total := 0
	for r in reliquias:
		if r.efeito_tipo == tipo:
			total += r.efeito_valor
	return total


## --- Eventos (cura/dano fora do combate) ---

func curar_jogador(valor: int) -> void:
	hp_jogador = min(hp_jogador + valor, hp_max_jogador)


## Fere o jogador, mas nunca o mata fora do combate (mínimo 1 de HP).
func ferir_jogador(valor: int) -> void:
	hp_jogador = max(hp_jogador - valor, 1)


## --- Melhorar carta (fogueira) ---

## Devolve o baralho mestre (para listar na fogueira).
func cartas_do_baralho() -> Array[CardData]:
	return baralho_mestre


## True se a carta ainda não foi melhorada.
func pode_melhorar(carta: CardData) -> bool:
	return not carta.nome.ends_with("+")


## Melhora a carta no índice dado: +valor_base e marca o nome com "+".
func melhorar_carta(indice: int) -> void:
	if indice < 0 or indice >= baralho_mestre.size():
		return
	var c: CardData = baralho_mestre[indice]
	if c.nome.ends_with("+"):
		return
	var bonus: int = max(3, int(round(c.valor_base * 0.5)))
	c.valor_base += bonus
	c.nome += "+"


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
	ouro = 0
	reliquias = []
	energia_max_jogador = 3
	run_iniciada = true
	_gerar_mapa()
	salvar_run()  # checkpoint inicial: a run já é retomável de cara.


## Encerra a run atual (chamado no game over ou na vitória final).
## Apaga o save para que o menu volte a oferecer "Novo Jogo".
func encerrar_run() -> void:
	run_iniciada = false
	mapa = []
	andar_atual = -1
	no_atual = -1
	apagar_save()


## --- Geração e navegação do MAPA ---

## Gera um mapa simples com vários andares. Cada andar tem 1 a 3 nós.
## O último andar é sempre o Chefe.
func _gerar_mapa() -> void:
	mapa = []
	andar_atual = -1
	no_atual = -1

	var total_andares := 8
	var contador_id := 0
	for a in total_andares:
		var andar: Array = []
		if a == total_andares - 1:
			# Último andar: o Chefe (nó único).
			andar.append({ "id": contador_id, "tipo": "chefe", "coluna": 1, "ligacoes": [], "inimigo": _INIMIGO_CHEFE })
			contador_id += 1
		else:
			var qtd := randi_range(2, 3)  # 2 ou 3 nós por andar.
			for col in qtd:
				var tipo := _sortear_tipo_no(a)
				andar.append({
					"id": contador_id,
					"tipo": tipo,
					"coluna": col,
					"ligacoes": [],
					"inimigo": _sortear_inimigo_para(tipo),
				})
				contador_id += 1
		mapa.append(andar)

	# Liga cada nó a 1-2 nós do andar seguinte (caminhos ramificados).
	for a in total_andares - 1:
		var atual: Array = mapa[a]
		var proximo: Array = mapa[a + 1]
		for no in atual:
			var qtd_lig := 1 if proximo.size() == 1 else randi_range(1, 2)
			var alvos := range(proximo.size())
			alvos.shuffle()
			var ligacoes: Array = []
			for i in min(qtd_lig, alvos.size()):
				ligacoes.append(alvos[i])
			ligacoes.sort()
			no["ligacoes"] = ligacoes


## Sorteia o caminho de um inimigo conforme o tipo de nó (na geração).
## Fogueira não tem inimigo (retorna vazio).
func _sortear_inimigo_para(tipo: String) -> String:
	match tipo:
		"elite":
			return _INIMIGOS_ELITE.pick_random()
		"chefe":
			return _INIMIGO_CHEFE
		"combate":
			return _INIMIGOS_BASICOS.pick_random()
		_:
			return ""  # fogueira etc.


## Retorna o EnemyData do nó atual (já decidido na geração do mapa).
## Usado pelo CombatSetup. Retorna null se o nó não tiver inimigo.
func inimigo_do_no_atual() -> EnemyData:
	if andar_atual < 0 or andar_atual >= mapa.size():
		return null
	var no: Dictionary = mapa[andar_atual][no_atual]
	var caminho: String = no.get("inimigo", "")
	if caminho == "":
		return null
	return load(caminho) as EnemyData


## Sorteia o tipo de um nó conforme o andar (fogueira/elite ficam mais ao meio/fim).
func _sortear_tipo_no(andar: int) -> String:
	# Andares iniciais: mais combate. Depois aparecem elite e fogueira.
	var r := randf()
	if andar >= 2 and r < 0.16:
		return "elite"
	elif andar >= 1 and r < 0.30:
		return "fogueira"
	elif andar >= 1 and r < 0.44:
		return "loja"
	elif andar >= 1 and r < 0.56:
		return "evento"
	return "combate"


## Retorna os nós que o jogador pode escolher AGORA.
## Se ainda não entrou no mapa, são todos os nós do primeiro andar.
## Senão, são os nós ligados ao nó atual, no próximo andar.
func nos_disponiveis() -> Array:
	if mapa.is_empty():
		return []
	if andar_atual < 0:
		return mapa[0]
	if andar_atual >= mapa.size() - 1:
		return []  # já no chefe / fim.
	var no: Dictionary = mapa[andar_atual][no_atual]
	var proximos: Array = []
	for idx in no["ligacoes"]:
		proximos.append(mapa[andar_atual + 1][idx])
	return proximos


## Marca a escolha do jogador e avança o andar. Guarda o tipo do nó.
func escolher_no(andar: int, indice: int) -> void:
	andar_atual = andar
	no_atual = indice
	tipo_no_atual = mapa[andar][indice]["tipo"]


## True se o jogador acabou de vencer o Chefe (fim da run).
func venceu_chefe() -> bool:
	return andar_atual == mapa.size() - 1 and mapa.size() > 0


## Sorteia até n cartas distintas de recompensa, com PESO por raridade.
## Comuns aparecem com frequência; raras são um "achado". A chance de rara
## cresce conforme você avança nos andares e é maior em combates de Elite.
func sortear_recompensas(n: int = 3) -> Array[CardData]:
	var caminhos: Array = (_POOL_DRAGAO if classe_atual == "dragao" else _POOL_ESPADACHIN)
	# Agrupa as cartas por raridade (0=Comum, 1=Incomum, 2=Rara).
	var por_raridade := { 0: [], 1: [], 2: [] }
	for caminho in caminhos:
		var carta := load(caminho) as CardData
		if carta != null:
			por_raridade[carta.raridade].append(carta)

	# Pesos base; a chance de rara melhora com o progresso e em Elites.
	var progresso: int = maxi(andar_atual, 0)
	var peso_rara: int = 6 + progresso * 2
	if tipo_no_atual == "elite":
		peso_rara += 15
	var pesos := { 0: 66, 1: 28, 2: peso_rara }

	var resultado: Array[CardData] = []
	var ids_usados := {}
	for i in n:
		var carta := _sortear_carta_ponderada(por_raridade, pesos, ids_usados)
		if carta == null:
			break
		resultado.append(carta)
		ids_usados[carta.id] = true
	return resultado


## Escolhe uma carta: sorteia a raridade pelos pesos e, dentro dela, uma carta
## ainda não escolhida. Se a raridade sorteada estiver esgotada, usa as outras.
func _sortear_carta_ponderada(por_raridade: Dictionary, pesos: Dictionary, ids_usados: Dictionary) -> CardData:
	var ordem := [_sortear_raridade(pesos), 0, 1, 2]  # sorteada primeiro; demais de reserva.
	for raridade in ordem:
		var disponiveis: Array = []
		for carta in por_raridade.get(raridade, []):
			if not ids_usados.has(carta.id):
				disponiveis.append(carta)
		if not disponiveis.is_empty():
			return disponiveis[randi() % disponiveis.size()]
	return null


## Sorteia uma raridade (0/1/2) conforme os pesos informados.
func _sortear_raridade(pesos: Dictionary) -> int:
	var total: int = pesos[0] + pesos[1] + pesos[2]
	var r := randi() % maxi(total, 1)
	if r < pesos[0]:
		return 0
	if r < pesos[0] + pesos[1]:
		return 1
	return 2


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


## ============================================================================
## SAVE / LOAD DA RUN
## A run inteira (baralho, HP, ouro, relíquias, mapa e posição) é persistida
## em disco como JSON. O save é um CHECKPOINT entre atividades: gravamos sempre
## que o jogador volta ao mapa, então fechar o jogo e voltar retoma de onde
## parou. As pilhas de combate (monte/mão/descarte) NÃO são salvas: o combate
## sempre recomeça do baralho mestre.
## ============================================================================

## True se existe um save de run para retomar.
func tem_save() -> bool:
	return FileAccess.file_exists(CAMINHO_SAVE)


## Apaga o save (no game over, vitória final, ou save corrompido).
func apagar_save() -> void:
	if FileAccess.file_exists(CAMINHO_SAVE):
		DirAccess.remove_absolute(CAMINHO_SAVE)


## Grava o estado atual da run no arquivo de save (JSON).
func salvar_run() -> void:
	if not run_iniciada:
		return
	var dados := {
		"versao": VERSAO_SAVE,
		"classe_atual": classe_atual,
		"hp_jogador": hp_jogador,
		"hp_max_jogador": hp_max_jogador,
		"ouro": ouro,
		"energia_max_jogador": energia_max_jogador,
		"andar_atual": andar_atual,
		"no_atual": no_atual,
		"tipo_no_atual": tipo_no_atual,
		"baralho": _serializar_baralho(),
		"reliquias": _serializar_reliquias(),
		"mapa": mapa,  # já é uma estrutura de Arrays/Dicionários simples.
	}
	var arquivo := FileAccess.open(CAMINHO_SAVE, FileAccess.WRITE)
	if arquivo == null:
		push_error("DeckManager: não foi possível abrir o save para escrita.")
		return
	arquivo.store_string(JSON.stringify(dados, "\t"))
	arquivo.close()


## Carrega a run do save e reconstrói o estado. Retorna true se conseguiu.
func carregar_run() -> bool:
	if not tem_save():
		return false
	var arquivo := FileAccess.open(CAMINHO_SAVE, FileAccess.READ)
	if arquivo == null:
		return false
	var texto := arquivo.get_as_text()
	arquivo.close()

	var dados = JSON.parse_string(texto)
	if not (dados is Dictionary):
		push_warning("DeckManager: save corrompido; ignorando.")
		apagar_save()
		return false

	classe_atual = dados.get("classe_atual", "espadachin")
	hp_jogador = int(dados.get("hp_jogador", 70))
	hp_max_jogador = int(dados.get("hp_max_jogador", 70))
	ouro = int(dados.get("ouro", 0))
	energia_max_jogador = int(dados.get("energia_max_jogador", 3))
	andar_atual = int(dados.get("andar_atual", -1))
	no_atual = int(dados.get("no_atual", -1))
	tipo_no_atual = dados.get("tipo_no_atual", "combate")
	_desserializar_baralho(dados.get("baralho", []))
	_desserializar_reliquias(dados.get("reliquias", []))
	mapa = _desserializar_mapa(dados.get("mapa", []))

	# Limpa qualquer pilha de combate antiga; o combate recomeça do baralho.
	monte_compra.clear()
	mao.clear()
	descarte.clear()

	run_iniciada = true
	return true


## --- Serialização auxiliar ---

func _serializar_baralho() -> Array:
	var lista: Array = []
	for c in baralho_mestre:
		lista.append(c.to_dict())
	return lista


func _desserializar_baralho(lista) -> void:
	baralho_mestre.clear()
	for d in lista:
		if d is Dictionary:
			baralho_mestre.append(CardData.from_dict(d))


## Relíquias não são modificadas durante a run, então basta salvar o caminho
## do .tres e recarregar. (Cai fora silenciosamente se o caminho não existir.)
func _serializar_reliquias() -> Array:
	var lista: Array = []
	for r in reliquias:
		if r != null and r.resource_path != "":
			lista.append(r.resource_path)
	return lista


func _desserializar_reliquias(lista) -> void:
	reliquias.clear()
	for caminho in lista:
		if typeof(caminho) == TYPE_STRING and ResourceLoader.exists(caminho):
			var r := load(caminho) as RelicData
			if r != null:
				reliquias.append(r)


## Reconstrói o mapa com os tipos certos (o JSON converte int em float e perde
## a tipagem dos Arrays). Cada nó volta a ter id/coluna/ligacoes como int.
func _desserializar_mapa(bruto) -> Array:
	var novo_mapa: Array = []
	for andar in bruto:
		var novo_andar: Array = []
		for no in andar:
			if not (no is Dictionary):
				continue
			var ligacoes: Array = []
			for lig in no.get("ligacoes", []):
				ligacoes.append(int(lig))
			novo_andar.append({
				"id": int(no.get("id", 0)),
				"tipo": no.get("tipo", "combate"),
				"coluna": int(no.get("coluna", 0)),
				"ligacoes": ligacoes,
				"inimigo": no.get("inimigo", ""),
			})
		novo_mapa.append(novo_andar)
	return novo_mapa
