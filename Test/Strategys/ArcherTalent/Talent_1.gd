extends BaseProjectileStrategy
class_name PreciseAimStrategy

@export var damage_increase_percent: float = 15.0

func _init():
	# Inicializa a propriedade herdada da classe pai
	target_type = TargetType.ARCHER  # Apenas afeta o arqueiro, não projéteis

func get_strategy_name() -> String:
	return "PreciseAim"

func apply_to_archer(archer: ArcherBase) -> void:
	# Aplica o bônus ao arqueiro
	archer.damage_multiplier *= (1.0 + damage_increase_percent/100.0)
	print("Precise Aim aplicado ao arqueiro. Novo multiplicador: ", archer.damage_multiplier)

func apply_to_projectile(projectile: Node) -> void:
	# Não faz nada com o projétil diretamente
	pass
