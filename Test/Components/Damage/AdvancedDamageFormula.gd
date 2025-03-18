extends Node
class_name AdvancedDamageFormula

# Classe para armazenar atributos de ataque
class AttackStats:
	var base_damage: int = 0
	var attack_power: float = 0.0
	var penetration: Dictionary = {}
	var crit_chance: float = 0.0
	var crit_damage: float = 2.0
	var elemental_bonus: Dictionary = {}
	var skill_modifiers: Dictionary = {}

# Classe para armazenar atributos de defesa
class DefenseStats:
	var armor: float = 0.0
	var magic_resist: float = 0.0
	var resistances: Dictionary = {}
	var vulnerabilities: Dictionary = {}
	var damage_reduction: float = 0.0

# Calcula o dano considerando múltiplos fatores
static func calculate_damage(attack: AttackStats, defense: DefenseStats, damage_packet: DamageCalculator.DamagePacket) -> DamageCalculator.DamagePacket:
	var result = DamageCalculator.DamagePacket.new()
	result.is_critical = damage_packet.is_critical
	
	# Se for crítico, ajusta o multiplicador baseado nas estatísticas de ataque
	if result.is_critical:
		result.crit_multiplier = attack.crit_damage
	
	# Para cada tipo de dano
	for damage_type in damage_packet.damage_values:
		var base_damage = damage_packet.damage_values[damage_type]
		if base_damage <= 0:
			continue
		
		# 1. Aplica multiplicador de poder de ataque
		var modified_damage = base_damage * (1.0 + attack.attack_power / 100.0)
		
		# 2. Aplica bônus elementais (específicos do tipo de dano)
		if attack.elemental_bonus.has(damage_type):
			modified_damage *= (1.0 + attack.elemental_bonus[damage_type] / 100.0)
		
		# 3. Calcula redução por resistência, considerando penetração
		var effective_resistance = 0.0
		if defense.resistances.has(damage_type):
			# Resistência reduzida pela penetração
			var penetration_value = 0.0
			if attack.penetration.has(damage_type):
				penetration_value = attack.penetration[damage_type]
			
			effective_resistance = max(0.0, defense.resistances[damage_type] - penetration_value)
			modified_damage *= (1.0 - effective_resistance)
		
		# 4. Aplica vulnerabilidades
		if defense.vulnerabilities.has(damage_type):
			modified_damage *= (1.0 + defense.vulnerabilities[damage_type])
		
		# 5. Aplica redução geral de dano baseada no tipo
		if damage_type == DamageCalculator.DamageType.PHYSICAL:
			# Armadura física
			var damage_reduction = calculate_armor_reduction(defense.armor)
			modified_damage *= (1.0 - damage_reduction)
		elif damage_type == DamageCalculator.DamageType.MAGIC:
			# Resistência mágica
			var damage_reduction = calculate_magic_reduction(defense.magic_resist)
			modified_damage *= (1.0 - damage_reduction)
		
		# 6. Aplica redução geral de dano percentual (efeitos especiais)
		modified_damage *= (1.0 - defense.damage_reduction)
		
		# 7. Aplica modificadores especiais de habilidades
		if attack.skill_modifiers.has("flat_damage_bonus"):
			modified_damage += attack.skill_modifiers["flat_damage_bonus"]
		
		if attack.skill_modifiers.has("percent_damage_bonus"):
			modified_damage *= (1.0 + attack.skill_modifiers["percent_damage_bonus"] / 100.0)
		
		# Arredonda para um valor inteiro
		result.damage_values[damage_type] = int(round(modified_damage))
	
	return result

# Cálculo de redução de dano baseado em armadura física
static func calculate_armor_reduction(armor: float) -> float:
	# Fórmula de exemplo: 
	# Cada ponto de armadura reduz 0.5% do dano, até o máximo de 80%
	var reduction = armor * 0.005
	return clamp(reduction, 0.0, 0.8)

# Cálculo de redução de dano baseado em resistência mágica
static func calculate_magic_reduction(magic_resist: float) -> float:
	# Fórmula de exemplo:
	# Cada ponto de resistência mágica reduz 0.75% do dano, até o máximo de 75%
	var reduction = magic_resist * 0.0075
	return clamp(reduction, 0.0, 0.75)

# Cria um pacote de dano a partir de estatísticas de ataque
static func create_damage_packet_from_stats(attack: AttackStats, is_critical: bool = false) -> DamageCalculator.DamagePacket:
	var packet = DamageCalculator.DamagePacket.new()
	packet.is_critical = is_critical
	packet.crit_multiplier = attack.crit_damage
	
	# Determina distribuição de dano base em diferentes tipos
	# Exemplo: 70% físico, 30% do tipo elemental dominante
	
	var dominant_element = DamageCalculator.DamageType.PHYSICAL
	var highest_bonus = 0.0
	
	# Encontra o elemento com maior bônus
	for element_type in attack.elemental_bonus:
		if attack.elemental_bonus[element_type] > highest_bonus:
			highest_bonus = attack.elemental_bonus[element_type]
			dominant_element = element_type
	
	# Distribui o dano base entre físico e o elemento dominante
	var physical_portion = 0.7
	var elemental_portion = 0.3
	
	if highest_bonus <= 0:
		# Se não houver bônus elemental, todo o dano é físico
		physical_portion = 1.0
		elemental_portion = 0.0
	
	packet.damage_values[DamageCalculator.DamageType.PHYSICAL] = int(attack.base_damage * physical_portion)
	
	if elemental_portion > 0:
		packet.damage_values[dominant_element] = int(attack.base_damage * elemental_portion)
	
	return packet

# Cria um objeto de estatísticas de ataque para um personagem
static func create_attack_stats_from_character(character: Node) -> AttackStats:
	var stats = AttackStats.new()
	
	# Lê as estatísticas do personagem
	# Este é apenas um exemplo - adapte para seu sistema
	if character.has_meta("base_damage"):
		stats.base_damage = character.get_meta("base_damage")
	else:
		stats.base_damage = 10  # Valor padrão
	
	if character.has_meta("attack_power"):
		stats.attack_power = character.get_meta("attack_power")
	
	if character.has_meta("crit_chance"):
		stats.crit_chance = character.get_meta("crit_chance")
	
	if character.has_meta("crit_damage"):
		stats.crit_damage = character.get_meta("crit_damage")
	
	# Lê modificadores elementais
	if character.has_meta("elemental_bonuses"):
		stats.elemental_bonus = character.get_meta("elemental_bonuses")
	
	# Lê valores de penetração
	if character.has_meta("penetration"):
		stats.penetration = character.get_meta("penetration")
	
	# Lê modificadores de habilidades
	if character.has_meta("skill_modifiers"):
		stats.skill_modifiers = character.get_meta("skill_modifiers")
	
	return stats

# Cria um objeto de estatísticas de defesa para um personagem
static func create_defense_stats_from_character(character: Node) -> DefenseStats:
	var stats = DefenseStats.new()
	
	# Lê as estatísticas de defesa do personagem
	if character.has_meta("armor"):
		stats.armor = character.get_meta("armor")
	
	if character.has_meta("magic_resist"):
		stats.magic_resist = character.get_meta("magic_resist")
	
	# Lê resistências e vulnerabilidades
	if character.has_meta("resistances"):
		stats.resistances = character.get_meta("resistances")
	
	if character.has_meta("vulnerabilities"):
		stats.vulnerabilities = character.get_meta("vulnerabilities")
	
	if character.has_meta("damage_reduction"):
		stats.damage_reduction = character.get_meta("damage_reduction")
	
	return stats
