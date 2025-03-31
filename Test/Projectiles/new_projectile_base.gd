extends CharacterBody2D
class_name NewProjectileBase

@export var damage: int = 10
@export var speed: float = 400.0
@export var piercing: bool = false

var is_crit: bool = false  # Calculated when instantiated
var direction: Vector2 = Vector2.ZERO
var shooter = null  # Reference to the shooter (archer)
var dmg_calculator: DmgCalculatorComponent
var tags: Array = []  # Array to store tags like "fire", "ice", etc.
var crit_chance: float = 0.1  # Default value, overridden by shooter's value

var initial_position: Vector2
var max_travel_distance: float = 500.0  # Distância máxima de viagem
var max_lifetime: float = 5.0  # Tempo máximo de vida da flecha

signal on_hit(target, projectile)  # Signal emitted when hitting a target

func _ready():
	initial_position = global_position
	# Inicia um timer para destruição
	var lifetime_timer = Timer.new()
	lifetime_timer.wait_time = max_lifetime
	lifetime_timer.one_shot = true
	lifetime_timer.timeout.connect(_on_lifetime_expired)
	add_child(lifetime_timer)
	lifetime_timer.start()
	# Skip initialization if this is a pooled object being reused
	# The pool system will handle initialization for reused objects
	if has_meta("pooled") and get_meta("pooled") and has_meta("initialized"):
		return
		
	# Get critical chance from shooter if available
	if shooter and "crit_chance" in shooter:
		crit_chance = shooter.crit_chance
	
	# Cálculo de crítico
	is_crit = is_critical_hit(crit_chance)
	# Get or create damage calculator
	dmg_calculator = $DmgCalculatorComponent
	if not dmg_calculator:
		dmg_calculator = DmgCalculatorComponent.new()
		add_child(dmg_calculator)
	
	# Initialize damage calculator
	dmg_calculator.base_damage = damage  # Set base damage
	
	# Initialize with shooter if available
	if shooter:
		dmg_calculator.initialize_from_shooter(shooter)
		
	# Mark as initialized to avoid duplicate initialization
	if has_meta("pooled") and get_meta("pooled"):
		set_meta("initialized", true)

func _physics_process(delta):
		# Check if homing is enabled
	if has_meta("enable_homing") and get_meta("enable_homing") and has_meta("homing_target"):
		var target = get_meta("homing_target")
		
		# Only apply homing if target is valid
		if is_instance_valid(target):
			var homing_strength = get_meta("homing_strength", 3.0)
			
			# Calculate distance to target
			var target_position = target.global_position
			var distance = global_position.distance_to(target_position)
			
			# Increase homing strength as we get closer to ensure hit
			var adaptive_strength = homing_strength * (1.0 + (500.0 / max(distance, 50.0)))
			
			# Calculate ideal direction to target
			var ideal_direction = (target_position - global_position).normalized()
			
			# Smoothly adjust current direction toward ideal direction
			direction = direction.lerp(ideal_direction, delta * adaptive_strength).normalized()
			
			# Update rotation and velocity
			rotation = direction.angle()
			velocity = direction * speed
			
			# Optional: Increase speed slightly for chain shots to catch up to targets
			speed += delta * 50.0
			
			# Debug visualization
			if Engine.is_editor_hint() or OS.is_debug_build():
				queue_redraw()  # For custom drawing
				
	velocity = direction * speed
	move_and_slide()
	# Calcula distância percorrida com valor absoluto

func _on_lifetime_expired():
	# Método chamado quando o tempo máximo de vida é atingido
	if is_pooled():
		return_to_pool()
	else:
		queue_free()

# Helper method to return arrow to pool
func return_to_pool() -> void:
	if not is_pooled() or not shooter:
		queue_free()
		return
	# Return to appropriate pool
	if ProjectilePool and ProjectilePool.instance:
		ProjectilePool.instance.return_arrow_to_pool(self)
	else:
		queue_free()


# Função existente, manteremos
func is_critical_hit(crit_chance: float) -> bool:
	var roll = randf()
	return roll < crit_chance

# Cálculo de acerto crítico centralizado
func calculate_critical_hit() -> bool:
	# Calcular apenas uma vez
	if has_meta("crit_calculated"):
		return is_crit
		
	# Obter chance base do atirador ou padrão
	var base_chance = 0.1  # Padrão 10%
	if shooter and "crit_chance" in shooter:
		base_chance = shooter.crit_chance
	
	# Aplicar modificadores de talentos
	var final_chance = base_chance
	if has_meta("crit_chance_bonus"):
		final_chance += get_meta("crit_chance_bonus")
	
	# Limite de 100%
	final_chance = min(final_chance, 1.0)
	
	# Reusa a função existente
	is_crit = is_critical_hit(final_chance)
	
	# Marca como calculado
	set_meta("crit_calculated", true)
	
	return is_crit

# Aplicar multiplicador de dano crítico de forma centralizada
func apply_critical_multiplier(base_damage: int) -> int:
	if not is_crit:
		return base_damage
		
	# Obter multiplicador base
	var crit_multi = 2.0  # Padrão
	if shooter and "crit_multi" in shooter:
		crit_multi = shooter.crit_multi
	
	# Aplicar bônus de talentos
	if has_meta("crit_damage_bonus"):
		crit_multi += get_meta("crit_damage_bonus")
	
	# Calcular dano final
	var final_damage = int(base_damage * crit_multi)
	
	return final_damage
	
# In NewProjectileBase.gd - updated get_damage_package
func get_damage_package() -> Dictionary:
	# Calculate critical hit first
	var is_critical = calculate_critical_hit()
	
	# Get base damage from calculator or direct value
	var physical_damage = damage
	var elemental_damages = {}
	
	if dmg_calculator:
		var calc_package = dmg_calculator.calculate_damage()
		physical_damage = calc_package.get("physical_damage", damage)
		elemental_damages = calc_package.get("elemental_damage", {})
	
	# Apply critical multiplier to physical damage
	if is_critical:
		physical_damage = apply_critical_multiplier(physical_damage)
		
		# Also apply to elemental damages
		for element in elemental_damages.keys():
			elemental_damages[element] = apply_critical_multiplier(elemental_damages[element])
	
	# Create final package
	var damage_package = {
		"physical_damage": physical_damage,
		"is_critical": is_critical,
		"tags": tags.duplicate()
	}
	
	# Add elemental damage if any
	if not elemental_damages.is_empty():
		damage_package["elemental_damage"] = elemental_damages
	
	# Add armor penetration if any
	if dmg_calculator and dmg_calculator.armor_penetration > 0:
		damage_package["armor_penetration"] = dmg_calculator.armor_penetration
	
	# Add DoT effects if any
	if dmg_calculator and not dmg_calculator.dot_effects.is_empty():
		damage_package["dot_effects"] = dmg_calculator.dot_effects.duplicate(true)
	
	return damage_package

# Add a tag to the projectile if it doesn't already exist
func add_tag(tag_name: String) -> void:
	if not tag_name in tags:
		tags.append(tag_name)
		
# Process hit event - base implementation that can be overridden
func process_on_hit(target: Node) -> void:
	# Emit signal for talent systems
	emit_signal("on_hit", target, self)
	
	# Basic hit logic
	if target.has_node("HealthComponent"):
		var health_component = target.get_node("HealthComponent")
		
		# Apply damage package
		var damage_package = get_damage_package()
		if health_component.has_method("take_complex_damage"):
			health_component.take_complex_damage(damage_package)
		else:
			health_component.take_damage(damage_package["physical_damage"], 
										 damage_package["is_critical"])
	
	# Handle piercing (base implementation)
	if not piercing:
		# Check if using pooling
		if ProjectilePool and ProjectilePool.instance and is_pooled():
			ProjectilePool.instance.return_arrow_to_pool(self)
		else:
			queue_free()
			
# Method to check if projectile is from pool
func is_pooled() -> bool:
	return has_meta("pooled") and get_meta("pooled") == true

# Reset projectile for reuse from pool
func reset_for_reuse() -> void:
	# Reset critical hit status
	if shooter and "crit_chance" in shooter:
		crit_chance = shooter.crit_chance
		is_crit = is_critical_hit(crit_chance)
	else:
		crit_chance = 0.1  # Default value
		is_crit = false
	
	# Reset velocity and direction
	velocity = Vector2.ZERO
	
	# Clear tags
	tags.clear()
	
	# Reset DmgCalculatorComponent
	if dmg_calculator:
		dmg_calculator.base_damage = damage
		dmg_calculator.damage_multiplier = 1.0
		dmg_calculator.armor_penetration = 0.0
		dmg_calculator.elemental_damage = {}
		dmg_calculator.additional_effects = []
		dmg_calculator.dot_effects = []
		
		# Reinitialize with shooter if available
		if shooter:
			dmg_calculator.initialize_from_shooter(shooter)
	
	# Disconnect any signal connections
	var connections = get_signal_connection_list("on_hit")
	for connection in connections:
		disconnect("on_hit", connection.callable)
	
	# Reset collision behavior
	if has_node("Hurtbox"):
		var hurtbox = get_node("Hurtbox")
		hurtbox.monitoring = true
		hurtbox.monitorable = true
	
	# Reset collision layers
	collision_layer = 4  # Projectile layer
	collision_mask = 2   # Enemy layer
	
	# Reset physics
	set_physics_process(true)
	
	# Keep metadata "pooled" but remove other metadata
	var meta_list = get_meta_list()
	for meta in meta_list:
		if meta != "pooled" and meta != "initialized":
			remove_meta(meta)
