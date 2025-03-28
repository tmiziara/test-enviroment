extends BaseProjectileStrategy
class_name Talent_2

# Configurações para aumento de alcance
@export var range_increase_percentage: float = 20.0  # Aumento de 20% no alcance de ataque
@export var talent_id: int = 2  # ID do talento correspondente

# Retorna o nome da estratégia para exibição no debug
func get_strategy_name() -> String:
	return "EnhancedRangeStrategy"

func apply_upgrade(projectile: Node) -> void:
	print("Aplicando upgrade de Enhanced Range!")
	
	# Adiciona tag para identificação
	if "tags" in projectile:
		if projectile.has_method("add_tag"):
			projectile.add_tag("enhanced_range")
		elif not "enhanced_range" in projectile.tags:
			projectile.tags.append("enhanced_range")
	
	# IMPORTANTE: 
	# Com o ConsolidatedTalentSystem, o aumento de alcance 
	# será aplicado no método compile_effects() do sistema de talentos
	# Veja o método _apply_strategy_effects() no ConsolidatedTalentSystem
	# Nele, este talento será processado assim:
	# effects.range_multiplier += strategy.range_increase_percentage / 100.0
