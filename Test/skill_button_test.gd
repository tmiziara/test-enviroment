extends TextureButton
class_name SkillNode

@export var talent_id: int = -1  # ID único do talento
@export var skill_name: String = ""  # Nome do talento
@export var icon: Texture  # Ícone da habilidade
@export var is_starter: bool = false  # Define se é o talento inicial

@onready var panel: Panel = $Panel
@onready var label: Label = $MarginContainer/Label

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
		panel.show_behind_parent = true
		label.visible = false
		
		# Mostra descrição e ativa habilidades conectadas
		if skill_tree:
			skill_tree.show_skill_description(self)
			skill_tree.enable_connected_talents(self)

# Retorna o ícone da habilidade
func get_icon() -> Texture: 
	return icon

# Atualiza o nível da habilidade
func set_level(value: int):
	_level = value
	
	# Atualiza o label de nível
	if label:
		label.text = str(_level) + "/1"
	
	# Atualiza a aparência visual
	if _level > 0:
		modulate = Color(1.0, 1.0, 1.0)  # Normal
		panel.self_modulate = Color(0.2, 0.8, 0.2, 0.7)  # Verde transparente
	else:
		if prerequisites_met:
			modulate = Color(1.0, 1.0, 1.0)  # Normal
			panel.self_modulate = Color(0.5, 0.5, 0.5, 0.5)  # Cinza transparente
		else:
			modulate = Color(0.7, 0.7, 0.7)  # Escurecido
			panel.self_modulate = Color(0.3, 0.3, 0.3, 0.5)  # Cinza escuro transparente

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
