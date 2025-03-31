extends BaseProjectileStrategy
class_name Talent_1

# Aumenta o dano básico em 15%
@export var damage_increase_percent: float = 0.15

# Propriedade para o sistema de debug
@export var talent_id: int = 1    # ID do talento correspondente

# Use get_strategy_name() em vez de get_class() para evitar conflitos
func get_strategy_name() -> String:
	return "PreciseAimStrategy"

func apply_upgrade(projectile: Node) -> void:
	# Adiciona tag para identificação
	if "tags" in projectile:
		if projectile.has_method("add_tag"):
			projectile.add_tag("precise_aim")
		elif not "precise_aim" in projectile.tags:
			projectile.tags.append("precise_aim")
	
	# IMPORTANTE: 
	# Com o ConsolidatedTalentSystem, o aumento de dano 
	# será aplicado no método compile_effects() do sistema de talentos
	# Veja o método _apply_strategy_effects() no ConsolidatedTalentSystem
	# Nele, este talento será processado assim:
	# effects.damage_multiplier += strategy.damage_increase_percent
