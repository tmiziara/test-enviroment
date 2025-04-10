extends Node
class_name ArcherTalentManager

# Referência ao arqueiro
var archer: ArcherBase
# Referência ao sistema de talentos
var talent_system: ArcherTalentSystem

# Contador de ataques (para talentos como Arrow Rain)
var attack_counter: int = 0
var attack_handlers: Dictionary = {}

func _ready():
	# Encontra referência do arqueiro (deve ser o pai)
	archer = get_parent() as ArcherBase
	
	if not archer:
		push_error("ArcherTalentManager: Parent is not an ArcherBase")
		return
	
	# Encontra o sistema de talentos
	talent_system = archer.get_node_or_null("ArcherTalentSystem")
	
	if not talent_system:
		push_error("ArcherTalentManager: No ArcherTalentSystem found")
		return
