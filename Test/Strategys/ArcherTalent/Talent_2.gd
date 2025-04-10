extends BaseProjectileStrategy
class_name EnhancedRangeStrategy

# Configuração de alcance
@export var range_increase_percentage: float = 20.0

func get_strategy_name() -> String:
	return "EnhancedRange"

# Não implementamos apply_to_archer ou apply_to_projectile
# O talent system é responsável por extrair e aplicar os efeitos
