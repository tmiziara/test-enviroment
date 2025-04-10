extends Resource
class_name BaseProjectileStrategy

# Método para identificação de estratégia
func get_strategy_name() -> String:
	return "BaseProjectileStrategy"

# Este método permanece apenas para compatibilidade com código existente
# Mas não deve realizar nenhuma ação - os efeitos são aplicados pelo talent system
func apply_upgrade(projectile: Node) -> void:
	pass
