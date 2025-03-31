extends BaseProjectileStrategy
class_name Talent_18_BloodseekerStrategy

# Bloodseeker: Consecutive hits on the same enemy increase damage by +10% (max 5 stacks).
# Resets when switching targets.

# Configurações
var damage_increase_per_stack: float = 0.1  # 10% de aumento por stack
var max_stacks: int = 5                     # Máximo de stacks permitido

# Para integração com ConsolidatedTalentSystem
func get_strategy_name() -> String:
	return "Bloodseeker"

# Aplicar estratégia ao projétil
func apply_upgrade(projectile: Node) -> void:
	
	# Adiciona metadados para ConsolidatedTalentSystem e processamento
	projectile.set_meta("has_bloodseeker_effect", true)
	projectile.set_meta("damage_increase_per_stack", damage_increase_per_stack)
	projectile.set_meta("max_stacks", max_stacks)
	
	# Adiciona tag para identificação do efeito
	if projectile.has_method("add_tag"):
		projectile.add_tag("bloodseeker")
	elif "tags" in projectile:
		if not "bloodseeker" in projectile.tags:
			projectile.tags.append("bloodseeker")
			
	# Não é necessário adicionar lógica direta aqui
	# A lógica de processamento de stacks é gerenciada pelo ArcherTalentManager
	# e aplicada pelo ConsolidatedTalentSystem
