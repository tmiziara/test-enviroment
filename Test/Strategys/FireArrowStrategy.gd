extends BaseProjectileStrategy
class_name FireArrowStrategy

@export var fire_damage: int = 5           # Dano inicial de fogo
@export var dot_damage_per_tick: int = 2   # Dano por tick do DoT
@export var dot_duration: float = 3.0      # Duração total do efeito em segundos
@export var dot_interval: float = 1.0      # Intervalo entre ticks de dano

# Na FireArrowStrategy.gd
func apply_upgrade(projectile: Node) -> void:
	print("Aplicando upgrade de Flecha de Fogo!")
	
	# Adiciona tag de fogo ao projétil
	if not "tags" in projectile:
		projectile.tags = []
	
	if not "fire" in projectile.tags:
		projectile.tags.append("fire")
	
	# Se tiver um calculador de dano, adiciona dano elemental
	if projectile.has_node("DmgCalculatorComponent"):
		var dmg_calc = projectile.get_node("DmgCalculatorComponent")
		
		# Garante que o dicionário elemental_damage existe
		if not "elemental_damage" in dmg_calc:
			dmg_calc.elemental_damage = {}
		
		# Adiciona dano elemental de fogo
		if "fire" in dmg_calc.elemental_damage:
			dmg_calc.elemental_damage["fire"] += fire_damage
		else:
			dmg_calc.elemental_damage["fire"] = fire_damage
		
		print("Dano de fogo adicionado:", dmg_calc.elemental_damage["fire"])
		
		# Adiciona o efeito DoT
		dmg_calc.add_dot_effect(
			dot_damage_per_tick,
			dot_duration,
			dot_interval,
			"fire"
		)
