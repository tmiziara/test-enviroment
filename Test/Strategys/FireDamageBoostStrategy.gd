extends BaseProjectileStrategy
class_name FireDamageBoostStrategy

@export var fire_damage_multiplier: float = 1.5  # Multiplicador para dano de fogo
@export var dot_damage_multiplier: float = 1.5   # Multiplicador para dano ao longo do tempo

func apply_upgrade(projectile: Node) -> void:
	print("Aplicando FireDamageBoostStrategy ao projétil")
	
	# Verifica se o projétil tem tags
	if not "tags" in projectile:
		print("Projétil não tem tags, não é possível aumentar dano de fogo")
		return
	
	# Verifica se o projétil é de fogo
	if not "fire" in projectile.tags:
		print("Projétil não é de fogo, não aplicando aumento de dano")
		return
		
	print("Projétil de fogo detectado, aumentando dano")
	
	# Se tiver um calculador de dano, aplica os multiplicadores
	if projectile.has_node("DmgCalculatorComponent"):
		var dmg_calc = projectile.get_node("DmgCalculatorComponent")
		
		# Verifica se tem dano elemental de fogo e aumenta
		if "elemental_damage" in dmg_calc and "fire" in dmg_calc.elemental_damage:
			var original_fire_damage = dmg_calc.elemental_damage["fire"]
			dmg_calc.elemental_damage["fire"] = int(original_fire_damage * fire_damage_multiplier)
			print("Dano de fogo aumentado de", original_fire_damage, "para", dmg_calc.elemental_damage["fire"])
		
		# Percorre os efeitos DoT e aumenta o dano dos que são de fogo
		if "dot_effects" in dmg_calc:
			for dot_effect in dmg_calc.dot_effects:
				if dot_effect.get("type") == "fire":
					var original_dot_damage = dot_effect.damage
					dot_effect.damage = int(original_dot_damage * dot_damage_multiplier)
					print("DoT de fogo aumentado de", original_dot_damage, "para", dot_effect.damage)
	else:
		# Fallback se não tiver componente de cálculo de dano
		print("Sem componente de cálculo de dano, aplicando aumento direto")
		projectile.damage = int(projectile.damage * fire_damage_multiplier)
