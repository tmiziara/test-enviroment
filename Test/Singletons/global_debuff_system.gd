# global_debuff_system.gd
extends Node

# Tipos de debuffs predefinidos
enum DebuffType {
	BURNING,
	FREEZING,
	STUNNED,
	KNOCKED,
	SLOWED,
	BLEEDING,
	POISONED,
	MARKED_FOR_DEATH,
	NONE
}

# Estrutura de dados de um debuff
class DebuffData:
	var type: DebuffType
	var duration: float
	var dot_interval: float
	var stack_count: int = 1
	var max_stacks: int = 1
	var data: Dictionary = {}

# Funções globais de interação de debuffs
static func process_debuff_interactions(entity, damage_type: String, damage_amount: int) -> int:
	var modified_damage = damage_amount
	
	# Exemplo de interação de debuffs
	if entity.has_method("get_debuff_manager"):
		var debuff_manager = entity.get_debuff_manager()
		
		# Interação de burning
		if debuff_manager.has_debuff(DebuffType.BURNING):
			modified_damage += _create_burning_explosion(entity)
		
		# Outras interações de debuffs podem ser adicionadas aqui
	
	return modified_damage

# Lógica de explosão para burning
static func _create_burning_explosion(entity) -> int:
	var explosion_damage = 10  # Dano base de explosão
	
	# Lógica de área de explosão
	var space_state = entity.get_world_2d().direct_space_state
	var query = PhysicsShapeQueryParameters2D.new()
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = 50.0
	query.shape = circle_shape
	query.transform = Transform2D(0, entity.global_position)
	query.collision_mask = 2
	
	var results = space_state.intersect_shape(query)
	
	for result in results:
		var target = result.collider
		if target.has_method("take_damage"):
			target.take_damage(explosion_damage)
	
	return explosion_damage

# Função para mapear de DoT para DebuffType
static func map_dot_to_debuff_type(dot_type: String) -> int:
	match dot_type:
		"fire":
			return DebuffType.BURNING
		"bleeding":
			return DebuffType.BLEEDING
		"poison":
			return DebuffType.POISONED
		_:  # Caso padrão para qualquer outro valor
			return DebuffType.NONE
			
# Função inversa para mapear de DebuffType para DoT
static func map_debuff_to_dot_type(debuff_type: int) -> String:
	match debuff_type:
		DebuffType.BURNING:
			return "fire"
		DebuffType.BLEEDING:
			return "bleeding"
		DebuffType.POISONED:
			return "poison"
		_:
			return "generic"

# Adicione este método para ajudar no processamento de interações
static func process_movement_control_interactions(entity, damage_type: String, damage_amount: int) -> int:
	var modified_damage = damage_amount
	
	# Verifica se a entidade tem MovementControlComponent
	var movement_control = entity.get_node_or_null("MovementControlComponent")
	if not movement_control:
		return modified_damage
		
	# Exemplos de interações:
	# 1. Dano de fogo tem 20% de chance de stunnar por 1 segundo
	if damage_type == "fire" and randf() <= 0.2:
		movement_control.apply_stun(1.0)
	
	# 2. Dano de gelo tem 50% de chance de knockback
	if damage_type == "ice" and randf() <= 0.5:
		# Calcula direção do knockback (afastando da fonte do dano)
		var direction = Vector2.RIGHT  # Substitua pela direção adequada
		movement_control.apply_knockback(direction, min(damage_amount * 10, 200))
		
	return modified_damage
