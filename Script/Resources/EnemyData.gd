## EnemyData.gd
## Define um TIPO de inimigo como Resource (.tres), editável no Godot.
## Assim você cria "Geleko", "Cogumín", "Vespório" etc. sem mexer no código.
##
## O padrão de ações (intencoes) é uma lista de "moves". A cada turno o inimigo
## escolhe um move (em ordem ou aleatório) e o telegrafa para o jogador ver.
class_name EnemyData
extends Resource

## Como o inimigo escolhe o próximo move.
enum PadraoIA {
	SEQUENCIAL,  ## Segue a lista em ordem, repetindo do início ao fim.
	ALEATORIO,   ## Sorteia um move a cada turno.
}

## --- Identidade ---
@export var id: StringName = &""
@export var nome: String = "Inimigo"

## --- Atributos ---
@export var hp_max: int = 12

## --- Comportamento ---
@export var padrao: PadraoIA = PadraoIA.SEQUENCIAL

## Lista de moves. Cada move é um dicionário descrevendo a intenção, ex:
##   { "tipo": "atacar", "valor": 6 }
##   { "tipo": "defender", "valor": 5 }
##   { "tipo": "atacar_multiplo", "valor": 3, "vezes": 2 }   # golpe duplo
##   { "tipo": "buff", "status": "forca", "valor": 2 }
##   { "tipo": "debuff", "status": "fraqueza", "valor": 1 }
## Estes moves são interpretados em Enemy.gd.
@export var intencoes: Array[Dictionary] = []

## --- Apresentação ---
@export var sprite: Texture2D
