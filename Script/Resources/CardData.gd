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
