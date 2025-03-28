extends Node
class_name DmgCalculatorComponent

# Atributos base que influenciam o dano
var base_damage: int = 10  # Valor padrão mínimo
var weapon_damage: int = 0
var main_stat: int = 0      # Atributo principal (DEX para arqueiros, STR para guerreiros, INT para magos)
var main_stat_multiplier: float = 0.5  # Quanto o atributo principal contribui para o dano

# Modificadores
var damage_multiplier: float = 1.0
var armor_penetration: float = 0.0
var elemental_damage: Dictionary = {}  # tipo: valor
var additional_effects: Array = []
var dot_effects: Array = []

# Retorna o dano calculado com todos os modificadores
func calculate_damage() -> Dictionary:
	print("DmgCalculatorComponent.calculate_damage called")
	print("- base_damage: " + str(base_damage))
	print("- weapon_damage: " + str(weapon_damage))
	print("- main_stat: " + str(main_stat))
	print("- main_stat_multiplier: " + str(main_stat_multiplier))
	print("- damage_multiplier: " + str(damage_multiplier))
	
	# Cálculo base
	var total_damage = base_damage + weapon_damage
	print("- damage after weapon: " + str(total_damage))
	
	# Adiciona bonus do atributo principal
	total_damage += int(main_stat * main_stat_multiplier)
	print("- damage after main stat: " + str(total_damage))
	
	# Aplica multiplicadores
	total_damage = int(total_damage * damage_multiplier)
	print("- damage after multiplier: " + str(total_damage))
	
	# Garantia de dano mínimo
	total_damage = max(total_damage, 1)  # Sempre causa pelo menos 1 de dano
	
	# Pacote final de dano
	var damage_package = {
		"physical_damage": total_damage,
		"armor_penetration": armor_penetration,
		"elemental_damage": elemental_damage,
		"additional_effects": additional_effects,
		"dot_effects": dot_effects  # Adiciona os efeitos DoT ao pacote
	}
	
	print("- final damage package: " + str(damage_package))
	
	return damage_package

# Define os atributos base do projétil baseado no atirador
func initialize_from_shooter(shooter):
	if shooter.has_method("get_main_stat"):
		main_stat = shooter.get_main_stat()
		print("DmgCalculator: main_stat inicializado para " + str(main_stat))
	else:
		print("DmgCalculator: Atirador não tem método get_main_stat")
	
	if shooter.has_method("get_weapon_damage"):
		weapon_damage = shooter.get_weapon_damage()
		print("DmgCalculator: weapon_damage inicializado para " + str(weapon_damage))
	else:
		print("DmgCalculator: Atirador não tem método get_weapon_damage")

# Adiciona modificadores de dano (usado pelas estratégias)
# No DmgCalculatorComponent, método add_damage_modifier
func add_damage_modifier(modifier_type: String, value):
	match modifier_type:
		"elemental_damage":
			# value deve ser um dicionário {tipo: valor}
			for element in value:
				if element in elemental_damage:
					elemental_damage[element] += value[element]
				else:
					elemental_damage[element] = value[element]
				
# Método para adicionar um efeito DoT
func add_dot_effect(damage: int, duration: float, interval: float, element_type: String = "generic"):
	dot_effects.append({
		"damage": damage,
		"duration": duration,
		"interval": interval,
		"type": element_type
	})
