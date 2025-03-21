extends TextureButton
class_name SkillNode

@export var talent_id: int = -1  # ID único do talento
@export var skill_name: String = ""  # Nome do talento
@export var icon: Texture  # Ícone da habilidade
@export var is_starter: bool = false  # Define se é o talento inicial
@export var talent_strategy: Resource  # Strategy que será aplicada quando o talento for desbloqueado

@onready var panel = $Panel
@onready var label = $MarginContainer/Label

var _level: int = 0  # Nível atual da habilidade
var skill_tree  # Referência à árvore de talentos
var prerequisites_met: bool = false  # Indica se os pré-requisitos foram atendidos

func _ready():
	# Adiciona ao grupo de skill buttons
	add_to_group("skill_buttons")
	
	# Define o ícone do botão
	texture_normal = icon
	
	# Procura a Skill Tree
	skill_tree = get_tree().get_first_node_in_group("skill_tree")
	
	# Conecta o sinal de pressionamento
	if not is_connected("pressed", Callable(self, "_on_pressed")):
		connect("pressed", Callable(self, "_on_pressed"))
	
	# Se for o talento inicial, ativa-o
	if is_starter:
		set_level(1)
		
		# Se o panel existe, ajusta suas propriedades
		if has_node("Panel"):
			$Panel.show_behind_parent = true
		
		if has_node("MarginContainer/Label"):
			$MarginContainer/Label.visible = false
		
		# Mostra descrição e ativa habilidades conectadas
		if skill_tree:
			skill_tree.show_skill_description(self)
			skill_tree.enable_connected_talents(self)

# Atualiza o nível da habilidade
func set_level(value: int):
	_level = value
	
	# Atualiza o label de nível
	var current_label = get_node_or_null("MarginContainer/Label")
	if current_label:
		current_label.text = str(_level) + "/1"
	
	# Atualiza a aparência visual
	var current_panel = get_node_or_null("Panel")
	if current_panel:
		if _level > 0:
			modulate = Color(1.0, 1.0, 1.0)  # Normal
			current_panel.self_modulate = Color(0.2, 0.8, 0.2, 0.7)  # Verde transparente
		else:
			if prerequisites_met:
				modulate = Color(1.0, 1.0, 1.0)  # Normal
				current_panel.self_modulate = Color(0.5, 0.5, 0.5, 0.5)  # Cinza transparente
			else:
				modulate = Color(0.7, 0.7, 0.7)  # Escurecido
				current_panel.self_modulate = Color(0.3, 0.3, 0.3, 0.5)  # Cinza escuro transparente
	else:
		# O panel não existe, apenas atualiza o modulate
		if _level > 0:
			modulate = Color(1.0, 1.0, 1.0)  # Normal
		else:
			if prerequisites_met:
				modulate = Color(1.0, 1.0, 1.0)  # Normal
			else:
				modulate = Color(0.7, 0.7, 0.7)  # Escurecido

# Atualiza o estado visual com base nos pré-requisitos
func update_prereq_status(met: bool):
	prerequisites_met = met
	set_level(_level)  # Reaplica a visualização

# Manipula o pressionamento do botão
func _on_pressed():
	if skill_tree:
		# Apenas mostra a descrição da habilidade
		# O desbloqueio deve ser feito através do botão Unlock
		skill_tree.show_skill_description(self)
