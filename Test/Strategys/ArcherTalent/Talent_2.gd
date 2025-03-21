extends BaseProjectileStrategy
class_name Talent_2

# Configurações do aumento de alcance
@export var range_increase_percentage: float = 20.0  # Aumento de 20% no alcance de ataque

# Propriedade para o sistema de debug
@export var talent_id: int = 2  # ID do talento correspondente

# Retorna o nome da estratégia para exibição no debug
func get_strategy_name() -> String:
	return "EnhancedRangeStrategy"

func apply_upgrade(projectile: Node) -> void:
	print("Aplicando upgrade de Enhanced Range!")
	
	# Verifica se temos acesso ao atirador
	if not "shooter" in projectile or not projectile.shooter:
		print("ERRO: Não foi possível acessar o atirador para o Enhanced Range")
		return
	
	# Acessa o atirador
	var shooter = projectile.shooter
	
	# Verifica se a propriedade attack_range existe
	if "attack_range" in shooter:
		# Verifica se o aumento já foi aplicado (evita aplicar múltiplas vezes)
		if not shooter.has_meta("enhanced_range_applied"):
			# Calcula o novo alcance
			var original_range = shooter.attack_range
			var range_increase = original_range * (range_increase_percentage / 100.0)
			shooter.attack_range += range_increase
			
			# Marca que o aumento foi aplicado e guarda o valor original
			shooter.set_meta("enhanced_range_applied", true)
			shooter.set_meta("original_attack_range", original_range)
			
			print("Alcance aumentado de ", original_range, " para ", shooter.attack_range)
		else:
			print("Aumento de alcance já aplicado anteriormente.")
	else:
		print("ERRO: O atirador não possui a propriedade attack_range")
