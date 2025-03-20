extends TextureButton
class_name SkillNode

@export var skill_name: String  # Descrição da skill

@export var icon: Texture  # Ícone da skill
@export var is_starter: bool = false  # Define se essa é a skill inicial 

@onready var panel: Panel = $Panel
@onready var label: Label = $MarginContainer/Label
@onready var line_2d: Line2D = $Line2D

var _level: int = 0  # Armazena o nível da habilidade
var skill_tree  # Referência à árvore de talentos
var prerequisites_met: bool = false  # Indica se os pré-requisitos foram atendidos

func _ready():
	# Adiciona este nó ao grupo skill_buttons para ser reconhecido pelo sistema
	add_to_group("skill_buttons")
	texture_normal = icon
	# Procura a Skill Tree pelo grupo
	skill_tree = get_tree().get_first_node_in_group("skill_tree")
	
	print("SkillNode inicializado: ", name)
	print("SkillTree encontrada: ", skill_tree != null)
	
	# Conecta o sinal pressed ao método _on_pressed
	if not is_connected("pressed", _on_pressed):
		connect("pressed", _on_pressed)
	
	# Se for a habilidade inicial, ative-a imediatamente
	if is_starter:
		set_level(1)
		panel.show_behind_parent = true
		label.visible = false
		
		# Avisa a skill tree que uma skill foi desbloqueada
		if skill_tree:
			skill_tree.show_skill_description(self)
			
			# Ativa habilidades conectadas
			skill_tree.enable_connected_talents(self)
 
# Retorna o ícone da habilidade
func get_icon() -> Texture: 
	return icon

# Setter para atualizar corretamente o nível da habilidade
func set_level(value: int):
	_level = value
	if label:
		label.text = str(_level) + "/1"
	
	# Atualiza a aparência visual
	if _level > 0:
		modulate = Color(1.0, 1.0, 1.0)  # Normal
		panel.self_modulate = Color(0.2, 0.8, 0.2, 0.7)  # Verde transparente para mostrar que está ativo
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

func _on_pressed():
	print("Botão pressionado: ", name)
	
	if skill_tree:
		# Extrai o ID do talento
		if name.begins_with("talent_"):
			var talent_id = int(name.split("_")[1])
			
			# Verifica se pode desbloquear o talento (pré-requisitos)
			if not skill_tree.can_unlock_talent(talent_id):
				print("Não pode desbloquear: pré-requisitos não atendidos")
				
				# Mesmo não podendo desbloquear, mostra a descrição
				skill_tree.show_skill_description(self)
				
				# Feedback visual (opcional)
				var tween = create_tween()
				tween.tween_property(self, "modulate", Color(1, 0.3, 0.3), 0.2)  # Vermelho rápido
				tween.tween_property(self, "modulate", Color(0.7, 0.7, 0.7), 0.2)  # Volta ao cinza
				
				return
			
			# Tenta desbloquear o talento
			if _level == 0 and skill_tree.total_talent_points > 0:
				print("Desbloqueando habilidade...")
				skill_tree.unlock_skill(self)
				panel.show_behind_parent = true
				line_2d.default_color = Color(1, 1, 0.24705882370472)  # Amarelo
			else:
				# Mesmo se já estiver desbloqueado, mostra a descrição
				skill_tree.show_skill_description(self)
		
	else:
		# Exibe informações de depuração
		print("ERRO: skill_tree não encontrada")
