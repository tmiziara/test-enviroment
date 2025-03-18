extends BaseProjectileStrategy
class_name DmgIncreaseStrategy

@export var dmg_bonus: int = 10  # Aumento de 20% na chance de crítico

func apply_upgrade(projectile: Node) -> void:
	projectile.damage += dmg_bonus
