extends Node
class_name DefenseComponent

# Estatísticas de defesa
@export var armor: int = 0
@export_range(0.0, 1.0) var resistance_fire: float = 0.0
@export_range(0.0, 1.0) var resistance_ice: float = 0.0
@export_range(0.0, 1.0) var resistance_poison: float = 0.0
@export_range(0.0, 1.0) var resistance_generic: float = 0.0

# Constantes para cálculos
const ARMOR_FACTOR = 0.01  # Ajustado para um valor menor para lidar com valores altos de armadura
const MAX_ARMOR_REDUCTION = 0.75  # Máximo de 75% de redução por armadura

# Dicionário de debuffs ativos
var active_debuffs = {}

# Método simples para reduzir um valor de dano único
func reduce_damage(amount: int, damage_type: String = "") -> int:
	var final_amount = amount
	
	# Redução baseada no tipo de dano
	match damage_type:
		"": # Dano físico
			var reduction = calculate_armor_reduction(armor)
			final_amount = int(amount * (1.0 - reduction))
		"fire":
			final_amount = int(amount * (1.0 - resistance_fire))
		"ice": 
			final_amount = int(amount * (1.0 - resistance_ice))
		"poison":
			final_amount = int(amount * (1.0 - resistance_poison))
		_: # Qualquer outro tipo de dano
			final_amount = int(amount * (1.0 - resistance_generic))
	return max(1, final_amount) # Garante pelo menos 1 de dano

# Fórmula de redução de armadura com diminuição de retorno para altos valores
func calculate_armor_reduction(armor_value: float) -> float:
	# Usando a fórmula: Redução = 1 - (1 / (1 + armor * fator))
	# Isso dá uma curva com diminuição de retorno que nunca ultrapassa 100%
	var reduction = 1.0 - (1.0 / (1.0 + (armor_value * ARMOR_FACTOR)))
	# Limitamos ao máximo definido
	return min(reduction, MAX_ARMOR_REDUCTION)

# Método específico para reduzir dano de DoT
func reduce_dot_damage(amount: int, dot_type: String = "generic") -> int:
	var final_amount = amount
	
	# Redução baseada no tipo de dano
	match dot_type:
		"fire":
			final_amount = int(amount * (1.0 - resistance_fire))
		"ice": 
			final_amount = int(amount * (1.0 - resistance_ice))
		"poison":
			final_amount = int(amount * (1.0 - resistance_poison))
		_: # Qualquer outro tipo de DoT
			final_amount = int(amount * (1.0 - resistance_generic))
	
	# Garante que o dano mínimo para DoTs seja 1 se o dano original for maior que 0
	if amount > 0:
		final_amount = max(1, final_amount)
	
	return final_amount

# Aplica reduções a um pacote completo de dano
func apply_reductions(damage_package: Dictionary) -> Dictionary:
	var result = damage_package.duplicate(true)
	# Redução de dano físico por armadura
	if "physical_damage" in result:
		var original_damage = result.physical_damage
		var pen = result.get("armor_penetration", 0.0)
		
		# Armadura efetiva após penetração
		var effective_armor = max(0, armor * (1.0 - pen))
		
		# Calcula a redução usando a nova fórmula
		var reduction = calculate_armor_reduction(effective_armor)
		
		# Aplica a redução
		result.physical_damage = int(result.physical_damage * (1.0 - reduction))
	# Redução de dano elemental por resistências
	if "elemental_damage" in result:
		for element_type in result.elemental_damage.keys():
			var original_damage = result.elemental_damage[element_type]
			var resistance_value = 0.0
			
			# Obtém a resistência apropriada com base no tipo de elemento
			match element_type:
				"fire":
					resistance_value = resistance_fire
				"ice":
					resistance_value = resistance_ice
				"poison":
					resistance_value = resistance_poison
				_:
					resistance_value = resistance_generic
			
			# Aplica a redução com base na resistência
			var reduced_damage = int(original_damage * (1.0 - resistance_value))
			
			# Garante que o dano mínimo seja 1 se o dano original for maior que 0
			if original_damage > 0:
				reduced_damage = max(1, reduced_damage)
				
			result.elemental_damage[element_type] = reduced_damage
	# Retorna o pacote de dano com reduções aplicadas
	return result

# Aplica um debuff no personagem
func apply_debuff(debuff_name: String, duration: float, effect_func: Callable):
	if debuff_name in active_debuffs:
		return  # Evita reaplicar um debuff já ativo

	active_debuffs[debuff_name] = get_tree().create_timer(duration)
	active_debuffs[debuff_name].timeout.connect(func():
		active_debuffs.erase(debuff_name)  # Remove o debuff após o tempo
	)
	effect_func.call()  # Aplica o efeito imediato

# Método para adicionar temporariamente resistência
func add_temporary_resistance(resistance_type: String, amount: float, duration: float):
	var original_value = 0.0
	
	# Obtém o valor original
	match resistance_type:
		"armor":
			original_value = armor
			armor += amount
		"fire":
			original_value = resistance_fire
			resistance_fire = min(resistance_fire + amount, 1.0)
		"ice":
			original_value = resistance_ice
			resistance_ice = min(resistance_ice + amount, 1.0)
		"poison":
			original_value = resistance_poison
			resistance_poison = min(resistance_poison + amount, 1.0)
		"generic":
			original_value = resistance_generic
			resistance_generic = min(resistance_generic + amount, 1.0)
	
	# Cria um timer para remover o buff
	var timer = get_tree().create_timer(duration)
	timer.timeout.connect(func():
		match resistance_type:
			"armor":
				armor = original_value
			"fire":
				resistance_fire = original_value
			"ice":
				resistance_ice = original_value
			"poison":
				resistance_poison = original_value
			"generic":
				resistance_generic = original_value
	)
