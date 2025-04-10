extends Node
class_name DmgCalculatorComponent

# ======== ATRIBUTOS BÁSICOS ========
var base_damage: int = 10  # Valor base de dano (já deve vir calculado do atirador, incluindo crítico)
var main_stat: int = 0     # Atributo principal (DEX para arqueiros, STR para guerreiros, INT para magos)
var main_stat_multiplier: float = 0.5  # Quanto o atributo principal contribui para o dano

# ======== MODIFICADORES ========
var damage_multiplier: float = 1.0   # Multiplicador geral de dano (talentos, buffs, etc.)
var armor_penetration: float = 0.0   # Porcentagem de penetração de armadura
var elemental_damage: Dictionary = {} # tipo: valor (ex: "fire": 10)
var additional_effects: Array = []   # Efeitos adicionais
var dot_effects: Array = []          # Efeitos de dano ao longo do tempo

# ======== REFERÊNCIAS ========
var shooter = null                  # Referência ao atirador
var projectile = null               # Referência ao projétil

# ======== MÉTODOS PRINCIPAIS ========

# Retorna o dano calculado com todos os modificadores
func calculate_damage() -> Dictionary:
	# O cálculo é simplificado porque base_damage já inclui o dano base + crítico
	var total_damage = base_damage
	
	# Adiciona bônus do atributo principal
	# (este é um bônus adicional, não o bônus principal que já está incluído)
	total_damage += int(main_stat * main_stat_multiplier)
	
	# Aplica multiplicadores de dano de talentos/habilidades
	total_damage = int(total_damage * damage_multiplier)
	
	# Garantia de dano mínimo
	total_damage = max(total_damage, 1)
	
	# Pacote final de dano
	var damage_package = {
		"physical_damage": total_damage,
		"armor_penetration": armor_penetration,
		"elemental_damage": elemental_damage,
		"additional_effects": additional_effects,
		"dot_effects": dot_effects
	}
	
	# Adiciona informação de crítico se disponível
	if projectile and "is_crit" in projectile:
		damage_package["is_critical"] = projectile.is_crit
	elif get_parent() and "is_crit" in get_parent():
		damage_package["is_critical"] = get_parent().is_crit
	print("Debug - DmgCalculator calculation:")
	print("Base damage: ", base_damage)
	print("Main stat bonus: ", int(main_stat * main_stat_multiplier))
	print("Total before multiplier: ", base_damage + int(main_stat * main_stat_multiplier))
	print("Damage multiplier: ", damage_multiplier)
	print("Final physical damage: ", total_damage)
	return damage_package

# Inicializa o calculador com base no atirador
func initialize_from_shooter(shooter_ref):
	self.shooter = shooter_ref
	print("Debug - DmgCalculator initialization:")
	print("Initial base_damage: ", base_damage)
	print("Main stat: ", main_stat)
	print("Main stat multiplier: ", main_stat_multiplier)
	# Obtém o projétil (geralmente o nó pai)
	projectile = get_parent()
	
	# Obtém o atributo principal do atirador
	if shooter.has_method("get_main_stat"):
		main_stat = shooter.get_main_stat()
	else:
		print("DmgCalculator: Atirador não tem método get_main_stat")

# ======== MÉTODOS PARA MODIFICADORES ========

# Adiciona modificadores de dano (usado pelas estratégias)
func add_damage_modifier(modifier_type: String, value):
	match modifier_type:
		"damage_multiplier":
			damage_multiplier *= (1.0 + value)
		"armor_penetration":
			armor_penetration = min(armor_penetration + value, 1.0)
		"elemental_damage":
			# value deve ser um dicionário {tipo: valor}
			for element in value:
				if element in elemental_damage:
					elemental_damage[element] += value[element]
				else:
					elemental_damage[element] = value[element]
		"base_damage_bonus":
			# Bonus direto ao dano base
			base_damage += value
		"base_damage_percent":
			# Bonus percentual ao dano base
			base_damage = int(base_damage * (1.0 + value))
				
# Método para adicionar um efeito DoT
func add_dot_effect(damage: int, duration: float, interval: float, element_type: String = "generic"):
	dot_effects.append({
		"damage": damage,
		"duration": duration,
		"interval": interval,
		"type": element_type
	})

# ======== MÉTODOS DE DEBUG ========

# Método para debug do cálculo de dano
func debug_damage_calculation() -> String:
	var debug_info = "==== DAMAGE CALCULATION DEBUG ====\n"
	debug_info += "Base damage: " + str(base_damage) + "\n"
	debug_info += "Main stat bonus: " + str(int(main_stat * main_stat_multiplier)) + "\n"
	debug_info += "Damage multiplier: " + str(damage_multiplier) + "\n"
	debug_info += "Calculated damage: " + str(calculate_damage().get("physical_damage")) + "\n"
	
	# Informação de crítico
	if projectile and "is_crit" in projectile:
		debug_info += "Is critical: " + str(projectile.is_crit) + "\n"
	
	# Dano elemental
	if not elemental_damage.is_empty():
		debug_info += "Elemental damage: " + str(elemental_damage) + "\n"
	
	debug_info += "================================"
	
	return debug_info
