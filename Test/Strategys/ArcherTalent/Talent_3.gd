extends BaseProjectileStrategy
class_name Talent_3

@export var armor_penetration: float = 0.1  # Ignora 10% da armadura inimiga

@export var talent_id: int = 3    # ID do talento correspondente

# Nome amigável para o painel de debug
func get_strategy_name() -> String:
	return "Sharp Arrows"

func apply_upgrade(projectile: Node) -> void:
	print("Aplicando upgrade de Sharp Arrows - penetração de armadura de ", armor_penetration * 100, "%")
	
	# Adiciona tag para identificação
	if "tags" in projectile:
		if projectile.has_method("add_tag"):
			projectile.add_tag("armor_piercing")
		elif not "armor_piercing" in projectile.tags:
			projectile.tags.append("armor_piercing")
	
	# Com o ConsolidatedTalentSystem, a penetração de armadura 
	# será processada no método compile_effects() do sistema de talentos
	# No ConsolidatedTalentSystem, será adicionado:
	# effects.armor_penetration += strategy.armor_penetration
