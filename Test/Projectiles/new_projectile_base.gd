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

signal on_hit(target, projectile)  # Signal emitted when hitting a target

func _ready():
	# Skip initialization if this is a pooled object being reused
	# The pool system will handle initialization for reused objects
	if has_meta("pooled") and get_meta("pooled") and has_meta("initialized"):
		return
		
	# Get critical chance from shooter if available
	if shooter and "crit_chance" in shooter:
		crit_chance = shooter.crit_chance
	
	# Determine if this shot is critical
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
	velocity = direction * speed
	move_and_slide()

# Check if attack will be critical
func is_critical_hit(crit_chance: float) -> bool:
	var roll = randf()
	return roll < crit_chance
	
# Return calculated damage package
func get_damage_package() -> Dictionary:
	if not dmg_calculator:
		print("ERROR: Trying to calculate damage without DmgCalculatorComponent!")
		return {
			"physical_damage": damage,
			"is_critical": is_crit,
			"tags": tags
		}
	
	var damage_package = dmg_calculator.calculate_damage()
	
	# Apply critical if needed
	if is_crit:
		var crit_multi = 2.0  # Default multiplier
		if shooter and "crit_multi" in shooter:
			crit_multi = shooter.crit_multi
			
		damage_package["physical_damage"] = int(damage_package["physical_damage"] * crit_multi)
		damage_package["is_critical"] = true
	else:
		damage_package["is_critical"] = false
	
	# Add projectile tags to damage package
	damage_package["tags"] = tags
		
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
