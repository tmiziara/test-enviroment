extends BaseProjectileStrategy
class_name PreciseAimStrategy

@export var damage_increase_percent: float = 15.0

func get_strategy_name() -> String:
	return "PreciseAim"

func apply_upgrade(projectile: Node) -> void:
	# Adiciona tags para identificação
	if projectile.has_method("add_tag"):
		projectile.add_tag("precise_aim")
	
	# Adiciona metadados para processamento
	projectile.set_meta("precise_aim_damage_bonus", damage_increase_percent / 100.0)
	
	# Opcional: log para debug
	print("Precise Aim upgrade applied. Damage increase: ", damage_increase_percent, "%")
