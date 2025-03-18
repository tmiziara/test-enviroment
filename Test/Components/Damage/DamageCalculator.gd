extends Node
class_name DamageCalculator

# Enum para tipos de dano
enum DamageType {
	PHYSICAL,
	FIRE,
	ICE,
	WIND,
	ELECTRIC,
	POISON,
	BLEED,
	MAGIC
}

# Estrutura para armazenar valores de dano por tipo
class DamagePacket:
	var damage_values = {
		DamageType.PHYSICAL: 0,
		DamageType.FIRE: 0,
		DamageType.ICE: 0,
		DamageType.WIND: 0,
		DamageType.ELECTRIC: 0,
		DamageType.POISON: 0,
		DamageType.BLEED: 0,
		DamageType.MAGIC: 0
	}
	
	var is_critical: bool = false
	var crit_multiplier: float = 2.0
	
	# Adiciona dano de um tipo específico
	func add_damage(type: int, amount: int) -> void:
		if damage_values.has(type):
			damage_values[type] += amount
	
	# Obtém o dano total de todos os tipos
	func get_total_damage() -> int:
		var total = 0
		for type in damage_values:
			total += damage_values[type]
		return total
	
	# Aplica multiplicador de crítico a todos os tipos de dano
	func apply_critical_multiplier() -> void:
		for type in damage_values:
			damage_values[type] = int(damage_values[type] * crit_multiplier)
	
	# Obtém um dicionário com nomes de tipo e valores
	func get_damage_breakdown() -> Dictionary:
		var breakdown = {}
		for type in damage_values:
			var type_name = DamageType.keys()[type]
			breakdown[type_name] = damage_values[type]
		return breakdown

# Classe para gerenciar resistências e vulnerabilidades
class DefenseProfile:
	var resistances = {
		DamageType.PHYSICAL: 0.0,
		DamageType.FIRE: 0.0,
		DamageType.ICE: 0.0,
		DamageType.WIND: 0.0,
		DamageType.ELECTRIC: 0.0,
		DamageType.POISON: 0.0,
		DamageType.BLEED: 0.0,
		DamageType.MAGIC: 0.0
	}
	
	var vulnerabilities = {
		DamageType.PHYSICAL: 0.0,
		DamageType.FIRE: 0.0,
		DamageType.ICE: 0.0,
		DamageType.WIND: 0.0,
		DamageType.ELECTRIC: 0.0,
		DamageType.POISON: 0.0,
		DamageType.BLEED: 0.0,
		DamageType.MAGIC: 0.0
	}
	
	# Define a resistência a um tipo de dano (0.25 = 25% de redução)
	func set_resistance(type: int, amount: float) -> void:
		if resistances.has(type):
			resistances[type] = clamp(amount, 0.0, 1.0)
	
	# Define a vulnerabilidade a um tipo de dano (0.5 = 50% de dano extra)
	func set_vulnerability(type: int, amount: float) -> void:
		if vulnerabilities.has(type):
			vulnerabilities[type] = max(0.0, amount)

# Status e efeitos de duração
class StatusEffect:
	var effect_type: int  # Tipo de efeito (usando o enum DamageType)
	var damage_per_tick: int
	var duration: float
	var interval: float
	var time_remaining: float
	var target: Node  # Alvo do efeito
	
	func _init(p_type: int, p_damage: int, p_duration: float, p_interval: float, p_target: Node):
		effect_type = p_type
		damage_per_tick = p_damage
		duration = p_duration
		interval = p_interval
		time_remaining = duration
		target = p_target
	
	# Aplica o efeito e retorna true se ainda está ativo
	func apply_tick(delta: float) -> bool:
		time_remaining -= delta
		if time_remaining <= 0:
			return false
		return true

# Função para calcular dano considerando resistências e vulnerabilidades
static func calculate_damage(damage_packet: DamagePacket, defense: DefenseProfile) -> DamagePacket:
	var result = DamagePacket.new()
	result.is_critical = damage_packet.is_critical
	result.crit_multiplier = damage_packet.crit_multiplier
	
	# Se for crítico, aplica o multiplicador
	if damage_packet.is_critical:
		damage_packet.apply_critical_multiplier()
	
	# Calcula o dano final para cada tipo
	for type in damage_packet.damage_values:
		var base_damage = damage_packet.damage_values[type]
		
		# Reduz por resistência
		var damage_after_resistance = base_damage * (1.0 - defense.resistances[type])
		
		# Aumenta por vulnerabilidade
		var final_damage = damage_after_resistance * (1.0 + defense.vulnerabilities[type])
		
		result.damage_values[type] = int(final_damage)
	
	return result

# Aplicar efeito de status (DoT - Damage over Time)
static func apply_status_effect(target: Node, effect_type: int, damage: int, duration: float, interval: float = 1.0) -> void:
	if target.has_node("HealthComponent"):
		var health_component = target.get_node("HealthComponent")
		
		# Adapta para usar o método existente apply_dot
		if health_component.has_method("apply_dot"):
			health_component.apply_dot(damage, duration, interval)
			
			# Se quiser aplicar efeitos visuais baseados no tipo
			match effect_type:
				DamageType.FIRE:
					print("Aplicando efeito visual de fogo")
					# Adicionar efeito visual de fogo aqui
				DamageType.POISON:
					print("Aplicando efeito visual de veneno")
					# Adicionar efeito visual de veneno aqui
				DamageType.BLEED:
					print("Aplicando efeito visual de sangramento")
					# Adicionar efeito visual de sangramento aqui
