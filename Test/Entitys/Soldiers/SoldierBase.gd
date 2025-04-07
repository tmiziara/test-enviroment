extends CharacterBody2D
class_name SoldierBase

# ======== STATS EXPORTADOS ========
@export_category("Base Stats")
@export var max_health: int = 100
@export var base_damage: int = 10
@export var base_attack_range: float = 200.0
@export var base_attack_cooldown: float = 1.0
@export var base_move_speed: float = 100.0

@export_category("Advanced Stats")
@export var main_stat: int = 10            # Atributo principal (DEX/STR/INT)
@export var main_stat_type: String
@export var crit_chance: float = 0.1
@export var crit_multi: float = 2.0
@export var armor_penetration: float = 0.0
@export var armor: int = 0
@export var damage_reduction: float = 0.0

@export_category("Elemental Stats")
@export var fire_damage_modifier: float = 0.0
@export var ice_damage_modifier: float = 0.0
@export var poison_damage_modifier: float = 0.0

@export_category("Animation Settings")
@export var animation_blend_speed: float = 5.0
@export var attack_animation_speed: float = 1.0
@export var icon_texture: Texture

# ======== STATS CALCULADOS ========
var current_health: int
var attack_damage: int
var attack_range: float
var attack_cooldown: float
var move_speed: float

# ======== MODIFICADORES DE STATS ========
var damage_multiplier: float = 1.0
var range_multiplier: float = 1.0
var cooldown_multiplier: float = 1.0
var speed_multiplier: float = 1.0

# ======== ESTADOS ========
var is_attacking: bool = false
var current_target = null
var team: String = "ally"  # Used for friendly fire detection
var equipment_slots = {}

# ======== COMPONENTES ========
var health_component: HealthComponent
var hurtbox: HurtboxComponent
var attack_timer: Timer
var animation_tree: AnimationTree

# ======== SINAIS ========
signal target_change(new_target)
signal attack_started
signal attack_finished
signal animation_blend_changed(blend_position)

func _ready():
	# Initialize health
	current_health = max_health
	
	# Find and set up components
	health_component = $HealthComponent
	if health_component:
		health_component.max_health = max_health
		health_component.died.connect(_on_death)
	
	hurtbox = $HurtboxComponent
	if hurtbox:
		hurtbox.hit_received.connect(_on_hit_received)
	
	animation_tree = $AnimationTree
	
	# Create attack timer
	attack_timer = Timer.new()
	attack_timer.name = "AttackTimer"
	attack_timer.wait_time = attack_cooldown
	attack_timer.one_shot = false
	attack_timer.timeout.connect(_on_attack_timeout)
	add_child(attack_timer)
	
	# Calculate initial stats
	recalculate_stats()
	
	# Additional initialization
	_init_soldier()

# Virtual method for child classes to initialize
func _init_soldier() -> void:
	pass

func _physics_process(delta):
	# Basic movement handling
	_handle_movement(delta)
	
	# Target tracking
	_update_target()
	
	# Update animations based on movement
	update_animation_blend(delta)

# ======== MÉTODOS DE MOVIMENTO E DIREÇÃO ========

# Handle soldier movement - override in child classes
func _handle_movement(delta: float) -> void:
	# Base implementation does nothing
	pass

# Update current target if needed
func _update_target() -> void:
	# Override in child classes
	pass

# Select the closest valid target
func select_closest_target() -> Node:
	# Base implementation returns null
	# Override in child classes
	return null

# Check if target is in range
func is_target_in_range(target: Node) -> bool:
	if not target:
		return false
	
	var distance = global_position.distance_to(target.global_position)
	return distance <= attack_range

# ======== MÉTODOS DE ATAQUE ========

# Attack timer callback
func _on_attack_timeout() -> void:
	if current_target and is_target_in_range(current_target):
		start_attack()

# Start the attack sequence
func start_attack() -> void:
	if is_attacking:
		return
	
	is_attacking = true
	emit_signal("attack_started")
	
	# Implement actual attack in child classes
	_perform_attack()

# Perform the actual attack - override in child classes
func _perform_attack() -> void:
	# After attack is complete, reset state
	reset_attack()

# Reset attack state
func reset_attack() -> void:
	is_attacking = false
	emit_signal("attack_finished")

# ======== MÉTODOS DE ANIMAÇÃO ========

# Update animation blend position based on current velocity
func update_animation_blend(delta: float) -> void:
	if not animation_tree:
		return
	
	# Only update if we have velocity
	if velocity.length() > 0.1:
		var blend_position = Vector2(velocity.x, velocity.y).normalized()
		
		# Set the blend position with smooth transition
		var current_blend = animation_tree.get("parameters/Idle/blend_position")
		var new_blend = lerp(current_blend, blend_position, delta * animation_blend_speed)
		
		update_animation_blend_position(new_blend)
		
		# Set movement animation
		animation_tree.set("parameters/StateMachine/conditions/idle", false)
		animation_tree.set("parameters/StateMachine/conditions/is_moving", true)
		animation_tree.set("parameters/StateMachine/conditions/shooting", false)
	else:
		# Set idle animation
		animation_tree.set("parameters/StateMachine/conditions/idle", true)
		animation_tree.set("parameters/StateMachine/conditions/is_moving", false)
		animation_tree.set("parameters/StateMachine/conditions/shooting", false)

# Update the animation blend position
func update_animation_blend_position(blend_position: Vector2) -> void:
	if not animation_tree:
		return
		
	animation_tree.set("parameters/Idle/blend_position", blend_position)
	animation_tree.set("parameters/Move/blend_position", blend_position)
	animation_tree.set("parameters/Shoot/blend_position", blend_position)
	
	emit_signal("animation_blend_changed", blend_position)

# Update animation blend position to face a target
func update_animation_blend_position_to_target(target_position: Vector2) -> void:
	if not animation_tree:
		return
		
	var direction = (target_position - global_position).normalized()
	update_animation_blend_position(direction)

# Update animation speed
func update_animation_speed() -> void:
	if not animation_tree:
		return
		
	animation_tree.set("parameters/Shoot/TimeScale/scale", attack_animation_speed)

# Get the active blend animation
func get_active_blend_animation() -> String:
	if not animation_tree:
		return ""
	
	# Detect which animation state is active
	if animation_tree.get("parameters/StateMachine/conditions/shooting"):
		return "Shoot"
	elif animation_tree.get("parameters/StateMachine/conditions/is_moving"):
		return "Move"
	else:
		return "Idle"

# Get animation duration
func get_animation_duration(animation_name: String) -> float:
	if not animation_tree:
		return 0.5
	
	# Base duration logic - override in child classes for specific durations
	match animation_name:
		"Shoot":
			return 0.5
		"Move":
			return 0.3
		"Idle":
			return 0.3
		_:
			return 0.3

# Play death animation
func _play_death_animation() -> void:
	# Base implementation - override in child classes
	# Example:
	if animation_tree:
		animation_tree.set("parameters/StateMachine/conditions/dead", true)
		# Allow animation to play before queuing free
		await get_tree().create_timer(1.0).timeout
	
	queue_free()

# ======== MÉTODOS DE DANO E VIDA ========

# When hit by an attack
func _on_hit_received(hitbox: HitboxComponent, hit_data: Dictionary) -> void:
	# Base implementation does nothing special
	pass

# When the soldier dies
func _on_death() -> void:
	# Disable physics and interactions
	set_physics_process(false)
	
	if hurtbox:
		hurtbox.set_active(false)
	
	# Play death animation
	_play_death_animation()

# ======== MÉTODOS DE RECÁLCULO E ESTATÍSTICAS ========

# Get weapon damage for calculations
func get_weapon_damage() -> int:
	# Check equipment system
	if "Weapons" in equipment_slots and equipment_slots["Weapons"] != null:
		return equipment_slots["Weapons"].damage
	
	# Default value
	return attack_damage

# Get main attribute value for damage calculations
func get_main_stat() -> int:
	return main_stat

# Get current target
func get_current_target() -> Node:
	return current_target

# Set a new target
func set_target(target: Node) -> void:
	if target != current_target:
		current_target = target
		emit_signal("target_change", target)

# Recalculate all modified stats from base stats
func recalculate_stats() -> void:
	# Basic calculations
	attack_damage = int(base_damage * damage_multiplier)
	attack_range = base_attack_range * range_multiplier
	attack_cooldown = base_attack_cooldown * cooldown_multiplier
	move_speed = base_move_speed * speed_multiplier
	
	# Add main stat contribution
	attack_damage += int(main_stat * 0.5)
	
	# Update the attack timer
	if attack_timer:
		attack_timer.wait_time = attack_cooldown
	
	# Update health if health component exists
	if health_component and health_component.max_health != max_health:
		# Preserve health percentage
		var health_percent = float(health_component.current_health) / health_component.max_health
		health_component.max_health = max_health
		health_component.current_health = int(max_health * health_percent)
