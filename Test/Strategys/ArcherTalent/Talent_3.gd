extends BaseProjectileStrategy
class_name Talent_3

@export var armor_penetration: float = 0.1  # Ignora 10% da armadura inimiga

func apply_upgrade(projectile: Node) -> void:
	print("Aplicando upgrade de Sharp Arrows - penetração de armadura de ", armor_penetration * 100, "%")
	
	# Verifica se o projétil tem um calculador de dano
	if projectile.has_node("DmgCalculatorComponent"):
		var dmg_calc = projectile.get_node("DmgCalculatorComponent")
		
		# Adiciona ou incrementa a penetração de armadura
		if "armor_penetration" in dmg_calc:
			dmg_calc.armor_penetration += armor_penetration
		else:
			dmg_calc.armor_penetration = armor_penetration
			
		print("Penetração de armadura atualizada para: ", dmg_calc.armor_penetration * 100, "%")
	else:
		print("AVISO: DmgCalculatorComponent não encontrado no projétil")
	
	# Adiciona uma tag para identificação
	if "tags" in projectile:
		if not "armor_piercing" in projectile.tags:
			projectile.add_tag("armor_piercing")
