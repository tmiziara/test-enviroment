extends Control

@export var total_talent_points: int = 2  # Total de pontos de talento disponíveis

@onready var talent_points_label = $PanelContainer/HBoxContainer/PanelContainer/VBoxContainer/TalentPointsLabel
@onready var skills_container = $PanelContainer/HBoxContainer/PanelContainer2/SkillTree/SkillsContainer
@onready var skill_description_label = $PanelContainer/HBoxContainer/PanelContainer/VBoxContainer/SkillDescription
@onready var skill_icon_texture = $PanelContainer/HBoxContainer/PanelContainer/VBoxContainer/CenterContainer/SkillIcon  # Ícone da skill

func _ready():
	update_ui()
	adjust_scroll_container()
	activate_starter_skill()


# Atualiza a interface
func update_ui():
	talent_points_label.text = "Pontos de Talento: " + str(total_talent_points)
	check_skill_buttons()

# Verifica se as habilidades podem ser ativadas
func check_skill_buttons():
	for skill in skills_container.get_children():
		if skill is SkillNode:
			skill.disabled = total_talent_points <= 0 and skill._level == 0

# Método para desbloquear habilidade
func unlock_skill(skill: SkillNode):
	if total_talent_points > 0 and skill._level == 0:  # Só pode ativar se tiver pontos
		total_talent_points -= 1
		skill.set_level(1)
		update_ui()  # Atualiza a interface

# Exibe a descrição da habilidade e seu ícone
func show_skill_description(skill: SkillNode):
	if skill_description_label:
		skill_description_label.text = skill.get_description()
	if skill_icon_texture:
		skill_icon_texture.texture = skill.get_icon()

# Ajusta dinamicamente o tamanho do painel das skills
func adjust_scroll_container():
	var min_y = 0
	var max_y = 0
	for skill in skills_container.get_children():
		min_y = min(min_y, skill.position.y)
		max_y = max(max_y, skill.position.y + skill.size.y)
	skills_container.custom_minimum_size.y = max_y - min_y + 100  # Adiciona margem extra para garantir a rolagem

# Ativa a primeira skill automaticamente sem gastar pontos
func activate_starter_skill():
	for skill in skills_container.get_children():
		if skill is SkillNode and skill.is_starter:
			skill.set_level(1)
			unlock_skill(skill)  # Não consome ponto de talento ao ativar a inicial
			show_skill_description(skill)
			break
