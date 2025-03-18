extends BaseProjectileStrategy
class_name IncreaseCritStrategy

@export var crit_bonus: float = 0.2  # Aumento de 20% na chance de crítico

func apply_upgrade(projectile: Node) -> void:
	print("Aumentando crítico do projétil! Antes:", projectile.crit_chance, "Bônus:", crit_bonus)
	projectile.crit_chance += crit_bonus
	print("Novo crit_chance:", projectile.crit_chance)
