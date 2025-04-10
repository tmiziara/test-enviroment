extends Resource
class_name BaseProjectileStrategy

enum TargetType {
	ARCHER,
	PROJECTILE,
	BOTH
}

# Propriedade que indica onde o talento deve ser aplicado
@export var target_type: int = TargetType.PROJECTILE

# Métodos separados para aplicar em cada tipo de alvo
func apply_to_archer(archer: ArcherBase) -> void:
	pass
	
func apply_to_projectile(projectile: Node) -> void:
	pass
	
# Método geral que redireciona com base no tipo de alvo
func apply_upgrade(target: Node) -> void:
	if target is ArcherBase and (target_type == TargetType.ARCHER or target_type == TargetType.BOTH):
		apply_to_archer(target)
	elif target_type == TargetType.PROJECTILE or target_type == TargetType.BOTH:
		apply_to_projectile(target)

# Para compatibilidade com código existente que possa chamar get_strategy_name()
func get_strategy_name() -> String:
	return "BaseProjectileStrategy"
