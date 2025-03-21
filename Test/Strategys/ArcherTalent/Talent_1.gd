extends BaseProjectileStrategy
class_name Talent_1

# Aumenta o dano básico em 15%
@export var damage_increase_percent: float = 0.15

# Propriedade para o sistema de debug
@export var talent_id: int = 1    # ID do talento correspondente

# Use get_strategy_name() em vez de get_class() para evitar conflitos
func get_strategy_name() -> String:
	return "PreciseAimStrategy"  # Nome amigável para o painel de debug

func apply_upgrade(projectile: Node) -> void:
	print("Aplicando upgrade de Mira Precisa!")
	
	# Verifica se o projétil tem a propriedade de dano
	if "damage" in projectile:
		var original_damage = projectile.damage
		
		# Calcula o aumento de dano (15%)
		var damage_increase = int(original_damage * damage_increase_percent)
		if damage_increase < 1:
			damage_increase = 1  # Garantir pelo menos 1 de dano adicional
			
		# Aplica o aumento de dano
		projectile.damage += damage_increase
		
		print("Dano aumentado:", original_damage, "→", projectile.damage, "(+", damage_increase_percent * 100, "%)")
	
	# Se tiver um calculador de dano, também atualiza o dano base lá
	if projectile.has_node("DmgCalculatorComponent"):
		var dmg_calc = projectile.get_node("DmgCalculatorComponent")
		
		if "base_damage" in dmg_calc:
			var original_base_damage = dmg_calc.base_damage
			
			# Calcula o aumento de dano (15%)
			var base_damage_increase = int(original_base_damage * damage_increase_percent)
			if base_damage_increase < 1:
				base_damage_increase = 1  # Garantir pelo menos 1 de dano adicional
				
			# Aplica o aumento de dano
			dmg_calc.base_damage += base_damage_increase
			
			print("Dano base calculador aumentado:", original_base_damage, "→", dmg_calc.base_damage)
