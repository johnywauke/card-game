## CardData.gd
## Define os dados de uma carta. É um Resource, então cada carta do jogo
## pode ser criada como um arquivo .tres no editor do Godot e editada visualmente.
class_name CardData
extends Resource

## Tipos de carta do jogo.
enum CardType {
	ATAQUE,    ## Causa dano ao(s) inimigo(s).
	DEFESA,    ## Concede bloqueio (escudo temporário).
	HABILIDADE, ## Utilidade: buffs, compra, manipulação de energia/fervor.
	PODER,     ## Efeito permanente para o resto do combate (não vai pro descarte).
}

## Raridade da carta. Afeta drop e pool da loja.
enum Rarity {
	COMUM,
	INCOMUM,
	RARA,
}

## Para quem a carta aponta.
enum Target {
	INIMIGO_UNICO,   ## O jogador escolhe um inimigo.
	TODOS_INIMIGOS,  ## Atinge todos os inimigos.
	SI_MESMO,        ## Afeta o próprio jogador.
	NENHUM,          ## Sem alvo (ex: ganhar energia).
}

## --- Identidade ---
@export var id: StringName = &""          ## Identificador único (ex: &"golpe_de_luz").
@export var nome: String = "Nova Carta"
@export_multiline var descricao: String = ""

## --- Regras de jogo ---
@export var tipo: CardType = CardType.ATAQUE
@export var raridade: Rarity = Rarity.COMUM
@export var alvo: Target = Target.INIMIGO_UNICO
@export var custo: int = 1                  ## Energia necessária para jogar.

## Valor principal: dano (se ATAQUE) ou bloqueio (se DEFESA).
@export var valor_base: int = 0

## --- Mecânica da classe (Devota da Aurora) ---
@export var fervor_ganho: int = 0           ## Quanto Fervor a carta concede ao jogador.
@export var fervor_custo: int = 0           ## Quanto Fervor a carta consome ao ser jogada.

## --- Efeitos extras ---
## Lista flexível de efeitos. Cada efeito é um dicionário, ex:
##   { "tipo": "aplicar_status", "status": "veneno", "valor": 2, "alvo": "inimigo" }
##   { "tipo": "comprar_carta", "valor": 1 }
##   { "tipo": "dano_por_fervor", "multiplicador": 3 }
## Mantemos como Array genérico para não precisar de uma classe nova por efeito agora.
@export var efeitos: Array[Dictionary] = []

## --- Apresentação ---
@export var arte: Texture2D                 ## Sprite/ilustração da carta.

## Retorna o nome legível do tipo (útil para UI e debug).
func tipo_texto() -> String:
	match tipo:
		CardType.ATAQUE: return "Ataque"
		CardType.DEFESA: return "Defesa"
		CardType.HABILIDADE: return "Habilidade"
		CardType.PODER: return "Poder"
	return "Desconhecido"

## Retorna o nome legível da raridade.
func raridade_texto() -> String:
	match raridade:
		Rarity.COMUM: return "Comum"
		Rarity.INCOMUM: return "Incomum"
		Rarity.RARA: return "Rara"
	return "Desconhecida"

## Cria uma cópia independente desta carta (útil ao montar o baralho,
## para que upgrades em uma instância não afetem as outras).
func duplicar() -> CardData:
	return duplicate(true) as CardData


## --- Serialização (save/load da run) ---
## As cartas do baralho podem estar MELHORADAS (nome com "+", valor_base maior),
## então não basta guardar o caminho do .tres: salvamos os campos atuais.

## Converte esta carta em um Dicionário simples (compatível com JSON).
func to_dict() -> Dictionary:
	return {
		"id": String(id),
		"nome": nome,
		"descricao": descricao,
		"tipo": int(tipo),
		"raridade": int(raridade),
		"alvo": int(alvo),
		"custo": custo,
		"valor_base": valor_base,
		"fervor_ganho": fervor_ganho,
		"fervor_custo": fervor_custo,
		"efeitos": efeitos.duplicate(true),
		"arte": arte.resource_path if arte != null else "",
	}


## Reconstrói uma CardData a partir de um Dicionário (vindo do save).
## Faz casts explícitos porque o JSON transforma todo número em float.
static func from_dict(d: Dictionary) -> CardData:
	var c := CardData.new()
	c.id = StringName(d.get("id", ""))
	c.nome = d.get("nome", "Carta")
	c.descricao = d.get("descricao", "")
	c.tipo = int(d.get("tipo", 0))
	c.raridade = int(d.get("raridade", 0))
	c.alvo = int(d.get("alvo", 0))
	c.custo = int(d.get("custo", 1))
	c.valor_base = int(d.get("valor_base", 0))
	c.fervor_ganho = int(d.get("fervor_ganho", 0))
	c.fervor_custo = int(d.get("fervor_custo", 0))
	c.efeitos = _sanitizar_efeitos(d.get("efeitos", []))
	var caminho_arte: String = d.get("arte", "")
	if caminho_arte != "" and ResourceLoader.exists(caminho_arte):
		c.arte = load(caminho_arte)
	return c


## Garante a tipagem certa dos efeitos: converte floats inteiros (ex: 2.0)
## de volta para int, já que o JSON não distingue int de float.
static func _sanitizar_efeitos(lista) -> Array[Dictionary]:
	var resultado: Array[Dictionary] = []
	for ef in lista:
		if typeof(ef) != TYPE_DICTIONARY:
			continue
		var limpo: Dictionary = {}
		for chave in ef:
			var v = ef[chave]
			if typeof(v) == TYPE_FLOAT and v == floor(v):
				limpo[chave] = int(v)
			else:
				limpo[chave] = v
		resultado.append(limpo)
	return resultado
