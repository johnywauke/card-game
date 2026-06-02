## Evento.gd
## Nó de evento: apresenta uma situação com escolhas de risco/recompensa.
## Cada opção pode ter um custo em ouro e uma lista de efeitos. Após escolher,
## mostra o resultado e um botão para voltar ao mapa.
extends Control

const CENA_MAPA := "res://Scenes/Map/Map.tscn"

# Pool de eventos. Cada opção: { label, custo_ouro?, efeitos:[{tipo,valor}], resultado }
# Efeitos: "curar", "dano", "ouro", "carta".
const EVENTOS := [
	{
		"titulo": "Fonte Sagrada",
		"texto": "Uma fonte de água cristalina borbulha à sua frente, irradiando uma luz suave.",
		"opcoes": [
			{ "label": "Beber da fonte", "efeitos": [{ "tipo": "curar", "valor": 15 }],
			  "resultado": "A água restaura suas forças. +15 de HP." },
			{ "label": "Seguir viagem", "efeitos": [],
			  "resultado": "Você decide não arriscar e segue em frente." },
		],
	},
	{
		"titulo": "Mercador Errante",
		"texto": "Um mercador encapuzado oferece uma carta rara em troca de algumas moedas.",
		"opcoes": [
			{ "label": "Comprar carta (50 ouro)", "custo_ouro": 50, "efeitos": [{ "tipo": "carta", "valor": 1 }],
			  "resultado": "Você adquire uma nova carta para o baralho!" },
			{ "label": "Recusar", "efeitos": [],
			  "resultado": "O mercador encolhe os ombros e desaparece na névoa." },
		],
	},
	{
		"titulo": "Altar de Sangue",
		"texto": "Um altar sombrio exige um tributo de sangue em troca de riquezas.",
		"opcoes": [
			{ "label": "Oferecer sangue (-8 HP, +40 ouro)", "efeitos": [{ "tipo": "dano", "valor": 8 }, { "tipo": "ouro", "valor": 40 }],
			  "resultado": "Você sangra sobre o altar e moedas surgem. -8 HP, +40 ouro." },
			{ "label": "Afastar-se", "efeitos": [],
			  "resultado": "Você recua, perturbado, e segue caminho." },
		],
	},
	{
		"titulo": "Tesouro Esquecido",
		"texto": "Você encontra um pequeno tesouro abandonado entre os escombros.",
		"opcoes": [
			{ "label": "Pegar o ouro", "efeitos": [{ "tipo": "ouro", "valor": 30 }],
			  "resultado": "Você embolsa as moedas. +30 de ouro!" },
			{ "label": "Vasculhar mais (-6 HP, +60 ouro)", "efeitos": [{ "tipo": "dano", "valor": 6 }, { "tipo": "ouro", "valor": 60 }],
			  "resultado": "Você se arranha remexendo, mas acha mais riquezas. -6 HP, +60 ouro." },
		],
	},
]

@onready var titulo: Label = $Centro/VBox/Titulo
@onready var texto: Label = $Centro/VBox/Texto
@onready var caixa_opcoes: VBoxContainer = $Centro/VBox/Opcoes
@onready var label_resultado: Label = $Centro/VBox/Resultado
@onready var botao_continuar: Button = $Centro/VBox/BotaoContinuar

var _evento: Dictionary = {}


func _ready() -> void:
	_evento = EVENTOS[randi() % EVENTOS.size()]
	titulo.text = _evento["titulo"]
	texto.text = _evento["texto"]
	label_resultado.visible = false
	botao_continuar.visible = false
	botao_continuar.pressed.connect(_voltar_mapa)
	_montar_opcoes()


func _montar_opcoes() -> void:
	for filho in caixa_opcoes.get_children():
		filho.queue_free()
	for opcao in _evento["opcoes"]:
		var b := Button.new()
		b.text = opcao["label"]
		b.custom_minimum_size = Vector2(420, 52)
		b.add_theme_font_size_override("font_size", 20)
		# Desabilita se a opção custa mais ouro do que o jogador tem.
		var custo: int = opcao.get("custo_ouro", 0)
		if custo > 0 and DeckManager.ouro < custo:
			b.disabled = true
			b.text += "  (ouro insuficiente)"
		b.pressed.connect(_escolher_opcao.bind(opcao))
		caixa_opcoes.add_child(b)


func _escolher_opcao(opcao: Dictionary) -> void:
	# Paga o custo em ouro, se houver.
	var custo: int = opcao.get("custo_ouro", 0)
	if custo > 0:
		DeckManager.ganhar_ouro(-custo)

	# Aplica os efeitos.
	for ef in opcao.get("efeitos", []):
		match ef.get("tipo", ""):
			"curar":
				DeckManager.curar_jogador(ef.get("valor", 0))
			"dano":
				DeckManager.ferir_jogador(ef.get("valor", 0))
			"ouro":
				DeckManager.ganhar_ouro(ef.get("valor", 0))
			"carta":
				var recompensas := DeckManager.sortear_recompensas(1)
				if recompensas.size() > 0:
					DeckManager.adicionar_carta(recompensas[0])

	# Mostra o resultado e troca os botões pelo "Continuar".
	for filho in caixa_opcoes.get_children():
		filho.queue_free()
	label_resultado.text = opcao.get("resultado", "")
	label_resultado.visible = true
	botao_continuar.visible = true


func _voltar_mapa() -> void:
	get_tree().change_scene_to_file(CENA_MAPA)
