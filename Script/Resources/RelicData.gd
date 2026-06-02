## RelicData.gd
## Define uma RELÍQUIA como Resource (.tres). Relíquias são buffs passivos
## permanentes durante a run (não vão para a mão como cartas).
class_name RelicData
extends Resource

## Tipos de efeito: "hp_max", "forca_inicial", "destreza_inicial",
## "bloqueio_inicial", "escamas_inicial", "cura_combate", "energia".
@export var id: StringName = &""
@export var nome: String = "Relíquia"
@export_multiline var descricao: String = ""
@export var efeito_tipo: String = "hp_max"
@export var efeito_valor: int = 1
@export var custo: int = 100
@export var icone: Texture2D
