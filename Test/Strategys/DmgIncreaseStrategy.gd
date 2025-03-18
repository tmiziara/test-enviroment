extends BaseProjectileStrategy
class_name DmgIncreaseStrategy

@export var dmg_bonus: int = 10  # Aumento de 20% na chance de crítico

func apply_upgrade(projectile: Node) -> void:
	print("Aumentando dano do projétil! Antes:", projectile.damage, "Bônus:", dmg_bonus)
	projectile.damage += dmg_bonus
	print("Novo crit_chance:", projectile.damage)
