extends BaseProjectileStrategy
class_name PreciseAimStrategy

# Configuração de dano
@export var damage_increase_percent: float = 15.0

func get_strategy_name() -> String:
	return "PreciseAim"

# Não implementamos apply_to_archer ou apply_to_projectile
# O talent system é responsável por extrair e aplicar os efeitos
