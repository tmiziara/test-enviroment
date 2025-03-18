extends BaseProjectileStrategy
class_name IncreaseCritStrategy

@export var crit_bonus: float = 0.2  # Aumento de 20% na chance de crítico

func apply_upgrade(projectile: Node) -> void:
	projectile.crit_chance += crit_bonus
