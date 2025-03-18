extends BaseProjectileStrategy
class_name FireArrowStrategy

@export var fire_damage: int = 5           # Dano inicial de fogo
@export var dot_damage_per_tick: int = 2   # Dano por tick do DoT
@export var dot_duration: float = 3.0      # Duração total do efeito em segundos
@export var dot_interval: float = 1.0      # Intervalo entre ticks de dano

func apply_upgrade(projectile: Node) -> void:
	print("Aplicando upgrade de Flecha de Fogo!")
	
	# Adiciona tag de fogo ao projétil
	if not "tags" in projectile:
		projectile.tags = []
	
	if not "fire" in projectile.tags:
		projectile.tags.append("fire")
	
	# Se tiver um calculador de dano, adiciona dano elemental e DoT
	if projectile.has_node("DmgCalculatorComponent"):
		var dmg_calc = projectile.get_node("DmgCalculatorComponent")
		
		# Adiciona dano elemental de fogo
		if "elemental_damage" in dmg_calc:
			if "fire" in dmg_calc.elemental_damage:
				dmg_calc.elemental_damage["fire"] += fire_damage
			else:
				dmg_calc.elemental_damage["fire"] = fire_damage
		
		# Adiciona o efeito DoT através do calculador de dano
		dmg_calc.add_dot_effect(
			dot_damage_per_tick,
			dot_duration,
			dot_interval,
			"fire"
		)
	else:
		# Fallback se não tiver calculador de dano
		projectile.damage += fire_damage
