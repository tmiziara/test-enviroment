extends BaseProjectileStrategy
class_name Talent_6

# 20% do dano base será aplicado como dano de fogo
@export var fire_damage_percent: float = 0.20

# DoT será uma porcentagem do dano base
@export var dot_percent_per_tick: float = 0.05   # 5% do dano base por tick
@export var dot_duration: float = 3.0           # Duração total do efeito em segundos
@export var dot_interval: float = 0.5           # Intervalo entre ticks de dano

# Propriedade para o sistema de debug
@export var talent_id: int = 6    # ID do talento correspondente

# Use get_strategy_name() em vez de get_class() para evitar conflitos
func get_strategy_name() -> String:
	return "Flaming Arrows"  # Nome amigável para o painel de debug

func apply_upgrade(projectile: Node) -> void:
	print("Aplicando upgrade de Flecha de Fogo!")
	
	# Adiciona tag de fogo ao projétil
	if not "tags" in projectile:
		projectile.tags = []
	
	if not "fire" in projectile.tags:
		projectile.tags.append("fire")
		print("Tag 'fire' adicionada")
	
	# Verifica se temos acesso ao dano base para calcular o dano de fogo
	var base_damage = projectile.damage if "damage" in projectile else 10
	
	# Se tiver um calculador de dano, adiciona dano elemental
	if projectile.has_node("DmgCalculatorComponent"):
		var dmg_calc = projectile.get_node("DmgCalculatorComponent")
		
		# Garante que o dicionário elemental_damage existe
		if not "elemental_damage" in dmg_calc:
			dmg_calc.elemental_damage = {}
		
		# Calcula o dano de fogo como 20% do dano base
		var fire_damage = int(base_damage * fire_damage_percent)
		
		# Adiciona dano elemental de fogo
		if "fire" in dmg_calc.elemental_damage:
			dmg_calc.elemental_damage["fire"] += fire_damage
		else:
			dmg_calc.elemental_damage["fire"] = fire_damage
		
		print("Dano de fogo adicionado:", dmg_calc.elemental_damage["fire"], "(", fire_damage_percent * 100, "% do dano base)")
		
		# Calcula o dano do DoT com base no dano base
		var dot_damage_per_tick = int(base_damage * dot_percent_per_tick)
		if dot_damage_per_tick < 1:
			dot_damage_per_tick = 1  # Garantir pelo menos 1 de dano
		
		# Adiciona o efeito DoT
		dmg_calc.add_dot_effect(
			dot_damage_per_tick,
			dot_duration,
			dot_interval,
			"fire"
		)
		
		print("DoT de fogo adicionado:", dot_damage_per_tick, "a cada", dot_interval, "s durante", dot_duration, "s")
