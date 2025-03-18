extends Node
class_name StatusEffectComponent

# Sinais
signal status_applied(type, duration)
signal status_removed(type)
signal dot_damage_applied(type, damage)

# Dados de efeitos ativos
var active_effects = {}

# Referência ao dono do componente
var owner_entity: Node

# Constantes para tipos de efeitos
enum EffectType {
	NONE,
	BURNING,
	FROZEN,
	POISONED,
	BLEEDING,
	SHOCKED,
	STUNNED,
	SLOWED,
	WEAKENED
}

# Mapeamento para tipos de dano
var effect_to_damage_type = {
	EffectType.BURNING: DamageCalculator.DamageType.FIRE,
	EffectType.FROZEN: DamageCalculator.DamageType.ICE,
	EffectType.POISONED: DamageCalculator.DamageType.POISON,
	EffectType.BLEEDING: DamageCalculator.DamageType.BLEED,
	EffectType.SHOCKED: DamageCalculator.DamageType.ELECTRIC
}

# Outros componentes para interação
@export var health_component_path: NodePath = "../HealthComponent"
@export var damage_receiver_path: NodePath = "../DamageReceiverComponent"

# Efeitos visuais para cada tipo de efeito
@export var burning_effect_scene: PackedScene
@export var frozen_effect_scene: PackedScene
@export var poison_effect_scene: PackedScene
@export var bleeding_effect_scene: PackedScene
@export var shock_effect_scene: PackedScene

# Componentes de referência
var health_component
var damage_receiver

func _ready():
	owner_entity = get_parent()
	
	# Obtém referências para outros componentes
	if has_node(health_component_path):
		health_component = get_node(health_component_path)
	
	if has_node(damage_receiver_path):
		damage_receiver = get_node(damage_receiver_path)
		# Conecta ao sinal de dano recebido para possível aplicação de efeitos
		damage_receiver.connect("damage_received", _on_damage_received)

# Aplica um efeito de status
func apply_status(effect_type: EffectType, duration: float, params: Dictionary = {}) -> bool:
	# Verifica se já tem este efeito ativo
	if active_effects.has(effect_type):
		# Atualiza a duração se a nova for maior
		if duration > active_effects[effect_type]["time_remaining"]:
			active_effects[effect_type]["time_remaining"] = duration
		
		# Atualiza outros parâmetros se fornecidos
		if params.has("damage"):
			active_effects[effect_type]["damage"] = params["damage"]
		if params.has("tick_interval"):
			active_effects[effect_type]["tick_interval"] = params["tick_interval"]
		
		return false  # Não é um novo efeito
	
	# Verifica incompatibilidades
	if effect_type == EffectType.FROZEN and active_effects.has(EffectType.BURNING):
		# Cancela ambos efeitos
		remove_status(EffectType.BURNING)
		return false
	
	if effect_type == EffectType.BURNING and active_effects.has(EffectType.FROZEN):
		# Cancela ambos efeitos
		remove_status(EffectType.FROZEN)
		return false
	
	# Cria um novo efeito
	active_effects[effect_type] = {
		"time_remaining": duration,
		"damage": params.get("damage", 0),
		"tick_interval": params.get("tick_interval", 1.0),
		"tick_time": 0.0,
		"visual_effect": null
	}
	
	# Aplica efeito visual
	_apply_visual_effect(effect_type)
	
	# Aplica modificadores de status
	_apply_status_modifiers(effect_type, true)
	
	# Exibe texto de status
	if effect_to_damage_type.has(effect_type):
		var damage_type = effect_to_damage_type[effect_type]
		EnhancedDamageNumbers.display_status_effect(damage_type, owner_entity.global_position - Vector2(0, 30))
	
	# Emite sinal
	emit_signal("status_applied", effect_type, duration)
	
	return true  # Novo efeito aplicado

# Remove um efeito de status
func remove_status(effect_type: EffectType) -> void:
	if active_effects.has(effect_type):
		# Remove modificadores de status
		_apply_status_modifiers(effect_type, false)
		
		# Remove efeito visual
		if active_effects[effect_type]["visual_effect"] != null:
			active_effects[effect_type]["visual_effect"].queue_free()
		
		# Remove do dicionário
		active_effects.erase(effect_type)
		
		# Emite sinal
		emit_signal("status_removed", effect_type)

# Atualiza os efeitos ativos
func _process(delta: float) -> void:
	var effects_to_remove = []
	
	# Processa cada efeito ativo
	for effect_type in active_effects:
		# Reduz o tempo restante
		active_effects[effect_type]["time_remaining"] -= delta
		
		# Verifica se o efeito expirou
		if active_effects[effect_type]["time_remaining"] <= 0:
			effects_to_remove.append(effect_type)
			continue
		
		# Processa tick de dano (DoT)
		if active_effects[effect_type]["damage"] > 0:
			active_effects[effect_type]["tick_time"] += delta
			
			# Verifica se é hora de aplicar dano
			if active_effects[effect_type]["tick_time"] >= active_effects[effect_type]["tick_interval"]:
				# Reseta o contador
				active_effects[effect_type]["tick_time"] = 0
				
				# Aplica o dano DoT
				_apply_dot_damage(effect_type)
	
	# Remove efeitos expirados
	for effect_type in effects_to_remove:
		remove_status(effect_type)

# Aplica o dano de DoT
func _apply_dot_damage(effect_type: EffectType) -> void:
	if health_component and health_component.has_method("take_damage"):
		var damage = active_effects[effect_type]["damage"]
		
		# Aplica o dano
		health_component.take_damage(damage, false, true)
		
		# Mostra o número de dano
		if effect_to_damage_type.has(effect_type):
			var damage_type = effect_to_damage_type[effect_type]
			EnhancedDamageNumbers.display_dot_damage(damage, damage_type, owner_entity.global_position - Vector2(0, 15))
			
		# Emite sinal
		emit_signal("dot_damage_applied", effect_type, damage)

# Aplica modificadores de status baseados no efeito
func _apply_status_modifiers(effect_type: EffectType, apply: bool) -> void:
	var modifier = 1.0 if apply else -1.0
	
	match effect_type:
		EffectType.FROZEN:
			# Reduz velocidade em 80%
			if owner_entity.has_method("modify_speed"):
				owner_entity.modify_speed(-0.8 * modifier)
		EffectType.SLOWED:
			# Reduz velocidade em 40%
			if owner_entity.has_method("modify_speed"):
				owner_entity.modify_speed(-0.4 * modifier)
		EffectType.STUNNED:
			# Aplica stun completo
			if owner_entity.has_method("set_stunned"):
				owner_entity.set_stunned(apply)
		EffectType.WEAKENED:
			# Reduz dano em 30%
			if owner_entity.has_node("DamageDealerComponent"):
				var dealer = owner_entity.get_node("DamageDealerComponent")
				dealer.base_damage -= int(dealer.base_damage * 0.3 * modifier)

# Aplica efeitos visuais baseados no tipo de efeito
func _apply_visual_effect(effect_type: EffectType) -> void:
	var effect_instance = null
	
	# Cria o efeito visual baseado no tipo
	match effect_type:
		EffectType.BURNING:
			if burning_effect_scene:
				effect_instance = burning_effect_scene.instantiate()
		EffectType.FROZEN:
			if frozen_effect_scene:
				effect_instance = frozen_effect_scene.instantiate()
		EffectType.POISONED:
			if poison_effect_scene:
				effect_instance = poison_effect_scene.instantiate()
		EffectType.BLEEDING:
			if bleeding_effect_scene:
				effect_instance = bleeding_effect_scene.instantiate()
		EffectType.SHOCKED:
			if shock_effect_scene:
				effect_instance = shock_effect_scene.instantiate()
		_:
			# Efeito visual genérico para outros tipos
			effect_instance = _create_generic_effect(effect_type)
	
	# Se criou algum efeito, adiciona à cena
	if effect_instance:
		owner_entity.add_child(effect_instance)
		active_effects[effect_type]["visual_effect"] = effect_instance

# Cria um efeito visual genérico (partículas) quando não há uma cena específica
func _create_generic_effect(effect_type: EffectType) -> Node:
	var particles = CPUParticles2D.new()
	particles.amount = 10
	particles.lifetime = 1.0
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = 10.0
	
	# Define a cor baseada no tipo de efeito
	match effect_type:
		EffectType.BURNING:
			particles.color = Color(1.0, 0.5, 0.0, 0.8)  # Laranja
		EffectType.FROZEN:
			particles.color = Color(0.5, 0.8, 1.0, 0.8)  # Azul claro
		EffectType.POISONED:
			particles.color = Color(0.3, 0.8, 0.1, 0.7)  # Verde
		EffectType.BLEEDING:
			particles.color = Color(0.8, 0.0, 0.0, 0.8)  # Vermelho
		EffectType.SHOCKED:
			particles.color = Color(1.0, 1.0, 0.2, 0.8)  # Amarelo
		EffectType.STUNNED:
			particles.color = Color(0.9, 0.9, 0.2, 0.8)  # Amarelo
			particles.emit_above_parent = true
		EffectType.SLOWED:
			particles.color = Color(0.5, 0.5, 0.8, 0.7)  # Azul acinzentado
		EffectType.WEAKENED:
			particles.color = Color(0.5, 0.0, 0.5, 0.7)  # Roxo
	
	particles.emitting = true
	return particles

# Callback quando a entidade recebe dano (para aplicação automática de efeitos)
func _on_damage_received(damage_packet: DamageCalculator.DamagePacket) -> void:
	# Verifica se algum tipo de dano elemental está acima do limiar para aplicar efeito
	for damage_type in damage_packet.damage_values:
		var damage = damage_packet.damage_values[damage_type]
		
		if damage < 5:  # Limiar mínimo para aplicar efeito
			continue
			
		# Chance de aplicar efeito baseada no dano
		var chance = min(0.8, damage / 50.0)  # Máximo de 80% de chance
		
		if randf() <= chance:
			match damage_type:
				DamageCalculator.DamageType.FIRE:
					apply_status(EffectType.BURNING, 3.0, {"damage": damage / 4, "tick_interval": 0.5})
				DamageCalculator.DamageType.ICE:
					apply_status(EffectType.FROZEN, 2.0)
				DamageCalculator.DamageType.POISON:
					apply_status(EffectType.POISONED, 5.0, {"damage": damage / 5, "tick_interval": 1.0})
				DamageCalculator.DamageType.BLEED:
					apply_status(EffectType.BLEEDING, 4.0, {"damage": damage / 5, "tick_interval": 1.0})
				DamageCalculator.DamageType.ELECTRIC:
					apply_status(EffectType.SHOCKED, 1.0)
