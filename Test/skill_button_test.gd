extends TextureButton
class_name SkillNode

@export var description: String  # Descrição da skill
@export var icon: Texture  # Ícone da skill
@export var is_starter: bool = false  # Define se essa é a skill inicial 

@onready var panel: Panel = $Panel
@onready var label: Label = $MarginContainer/Label
@onready var line_2d: Line2D = $Line2D
var _level : int = 0  # Armazena o nível da habilidade
var skill_tree  # Referência à árvore de talentos

func _ready():
	# Agora procuramos a Skill Tree corretamente sem depender da hierarquia
	skill_tree = get_tree().get_first_node_in_group("skill_tree")  
	print(skill_tree)
	if not skill_tree:
		push_error("SkillNode não conseguiu encontrar a SkillTree! Certifique-se de que a SkillTree está no grupo 'skill_tree'.")
	if get_parent() is SkillNode:
		line_2d.add_point(global_position + size/2)
		line_2d.add_point(get_parent().global_position + size/2)
	# Se for a habilidade inicial, ative-a imediatamente
	if is_starter:
		set_level(1)
		panel.show_behind_parent = true
		label.visible = false
		skill_tree.unlock_skill(self)  # Desbloqueia sem gastar pontos
		skill_tree.show_skill_description(self)
		for skill in get_children():
			if skill is SkillNode and _level == 1:
				skill.disabled = false
 
# Retorna a descrição da habilidade
func get_description() -> String:
	return description

# Retorna o ícone da habilidade
func get_icon() -> Texture: 
	return icon

# Setter para atualizar corretamente o nível da habilidade
func set_level(value: int):
	_level = value
	if label:
		label.text = str(_level) + "/1"

func _on_pressed():
	if skill_tree and _level == 0 and skill_tree.total_talent_points > 0:
		skill_tree.unlock_skill(self)  # Usa a árvore de talentos para gerenciar a ativação
		panel.show_behind_parent = true
		line_2d.default_color = Color(1, 1, 0.24705882370472)
		# Habilita os filhos apenas se a habilidade foi desbloqueada
		for skill in get_children():
			if skill is SkillNode and _level == 1:
				skill.disabled = false
