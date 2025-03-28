extends NewProjectileBase
class_name NewArrow

# Signals
signal on_hit(target, projectile)

# Arrow Storm properties
var arrow_storm_enabled: bool = false
var arrow_storm_trigger_chance: float = 0.1
var arrow_storm_additional_arrows: int = 2
var arrow_storm_spread_angle: float = 30.0

# Method to configure Arrow Storm
func configure_arrow_storm(is_enabled: bool, trigger_chance: float, additional_arrows: int, spread_angle: float) -> void:
	arrow_storm_enabled = is_enabled
	arrow_storm_trigger_chance = trigger_chance
	arrow_storm_additional_arrows = additional_arrows
	arrow_storm_spread_angle = spread_angle
	
# Focused Shot properties
var focused_shot_enabled: bool = false
var focused_shot_bonus: float = 0.0
var focused_shot_threshold: float = 0.75  # Default 75%

# Method to configure Focused Shot
func configure_focused_shot(is_enabled: bool, bonus: float, threshold: float = 0.75) -> void:
	focused_shot_enabled = is_enabled
	focused_shot_bonus = bonus
	focused_shot_threshold = threshold

# Chain Shot properties
var chain_shot_enabled: bool = false
var chain_chance: float = 0.3        # 30% chance to ricochet
var chain_range: float = 150.0       # Maximum range for finding targets
var chain_damage_decay: float = 0.2  # 20% damage reduction for chained hit
var max_chains: int = 1              # Maximum number of ricochets
var current_chains: int = 0          # Current number of ricochet jumps performed
var hit_targets = []                 # Array to track which targets we've hit
var is_processing_ricochet: bool = false  # Flag to prevent multiple hits during ricochet
var will_chain: bool = false         # Flag to store if this arrow will chain
var chain_calculated: bool = false   # Flag to track if chain chance has been calculated

func _ready():
	super._ready()
	
	# Initialize hit_targets array if not already done
	if not hit_targets:
		hit_targets = []

# Override get_damage_package to handle special arrow effects
func get_damage_package() -> Dictionary:
	# Call parent's method to create base damage package
	var damage_package = super.get_damage_package()
	
	# Find current target for effects
	var current_target = null
	if has_meta("current_target"):
		current_target = get_meta("current_target")
	elif shooter and shooter.has_method("get_current_target"):
		current_target = shooter.get_current_target()
	
	# Process Focused Shot if enabled via metadata
	if has_meta("focused_shot_enabled") and current_target and is_instance_valid(current_target):
		damage_package = apply_focused_shot_bonus(damage_package, current_target)
	
	# Process Marked for Death effect for critical hits
	if current_target and is_instance_valid(current_target) and damage_package.get("is_critical", false):
		damage_package = apply_mark_bonus(damage_package, current_target)
	
	return damage_package
	
# Apply Focused Shot bonus to damage package
func apply_focused_shot_bonus(damage_package: Dictionary, target: Node) -> Dictionary:
	# Use metadata to get Focused Shot parameters
	if not has_meta("focused_shot_enabled") or not target.has_node("HealthComponent"):
		return damage_package
	
	var health_component = target.get_node("HealthComponent")
	
	# Get Focused Shot parameters from metadata
	var focused_shot_threshold = get_meta("focused_shot_threshold", 0.75)
	var focused_shot_bonus = get_meta("focused_shot_bonus", 0.3)
	
	# Check if target meets health threshold
	var health_percent = float(health_component.current_health) / health_component.max_health
	if health_percent >= focused_shot_threshold:
		# Apply bonus to physical damage
		if "physical_damage" in damage_package:
			var bonus_physical = int(damage_package["physical_damage"] * focused_shot_bonus)
			damage_package["physical_damage"] += bonus_physical
			print("Focused Shot: Physical damage increased by ", bonus_physical)
		
		# Apply to elemental damage
		if "elemental_damage" in damage_package:
			for element in damage_package["elemental_damage"]:
				var bonus_elem = int(damage_package["elemental_damage"][element] * focused_shot_bonus)
				damage_package["elemental_damage"][element] += bonus_elem
				print("Focused Shot: Elemental damage for ", element, " increased by ", bonus_elem)
		
		# Add tag
		if "tags" not in damage_package:
			damage_package["tags"] = []
		if "focused_shot" not in damage_package["tags"]:
			damage_package["tags"].append("focused_shot")
	
	return damage_package

# Apply Mark for Death bonus to critical hits
func apply_mark_bonus(damage_package: Dictionary, target: Node) -> Dictionary:
	# Check if target has mark debuff
	var has_mark = false
	var mark_bonus = 1.0
	
	if target.has_node("DebuffComponent"):
		var debuff_component = target.get_node("DebuffComponent")
		has_mark = debuff_component.has_debuff(GlobalDebuffSystem.DebuffType.MARKED_FOR_DEATH)
		
		if has_mark:
			# Get mark bonus from target
			mark_bonus = target.get_meta("mark_crit_bonus", 1.0)
			
			# Apply bonus to physical damage
			var base_crit_damage = damage_package["physical_damage"]
			var bonus_damage = int(base_crit_damage * mark_bonus)
			damage_package["physical_damage"] += bonus_damage
			
			# Apply to elemental damage
			if "elemental_damage" in damage_package:
				for element in damage_package["elemental_damage"]:
					var base_elem_crit = damage_package["elemental_damage"][element]
					var bonus_elem = int(base_elem_crit * mark_bonus)
					damage_package["elemental_damage"][element] += bonus_elem
			
			# Set damage type
			damage_package["damage_type"] = "marked_for_death"
	
	return damage_package

# Override the process_on_hit method for advanced arrow functionality
func process_on_hit(target: Node) -> void:
	# Set current target for damage calculations
	set_meta("current_target", target)
	
	# If already processing a ricochet, ignore this hit
	if is_processing_ricochet:
		return
	
	# Track this target
	if not target in hit_targets:
		hit_targets.append(target)
	
	# Calculate and apply damage
	if target.has_node("HealthComponent"):
		var health_component = target.get_node("HealthComponent")
		
		# Get damage package specific to this target
		var damage_package = get_damage_package()
		
		# Process DoT effects from fire arrows
		if has_node("DmgCalculatorComponent"):
			var dmg_calc = get_node("DmgCalculatorComponent")
			
			# Apply fire DoT if configured
			if dmg_calc.has_meta("fire_dot_data"):
				var dot_data = dmg_calc.get_meta("fire_dot_data")
				var dot_chance = dot_data.get("chance", 0.0)
				
				# Roll for DoT chance
				if randf() <= dot_chance:
					if "dot_effects" not in damage_package:
						damage_package["dot_effects"] = []
					
					# Add DoT effect
					damage_package["dot_effects"].append({
						"damage": dot_data.get("damage_per_tick", 1),
						"duration": dot_data.get("duration", 3.0),
						"interval": dot_data.get("interval", 0.5),
						"type": dot_data.get("type", "fire")
					})
		
		# Apply damage with the complete package
		health_component.take_complex_damage(damage_package)
	
	# Emit signal for talent systems
	emit_signal("on_hit", target, self)
	
	# Process talent effects
	process_talent_effects(target)
	
	# Handle Chain Shot
	if chain_shot_enabled and current_chains < max_chains:
		# Calculate chain chance only once on first hit
		if not chain_calculated:
			var roll = randf()
			will_chain = (roll <= chain_chance)
			chain_calculated = true
		
		# If arrow will chain
		if will_chain:
			is_processing_ricochet = true
			call_deferred("find_chain_target", target)
			return
	
	# Handle Piercing
	if piercing:
		var current_pierce_count = hit_targets.size() - 1
		var max_pierce = 1
		
		if has_meta("piercing_count"):
			max_pierce = get_meta("piercing_count")
			
		# Check if piercing limit reached
		if current_pierce_count >= max_pierce:
			queue_free()
	else:
		# No chain shot or piercing, destroy arrow
		queue_free()

# Process effects from talents that trigger on hit
func process_talent_effects(target: Node) -> void:
	# Process bleeding effect on critical
	if is_crit and has_meta("has_bleeding_effect") and target.has_node("HealthComponent"):
		apply_bleeding_effect(target)
	
	# Process splinter effect
	if has_meta("has_splinter_effect"):
		process_splinter_effect(target)
	
	# Process explosion effect
	if has_meta("has_explosion_effect"):
		process_explosion_effect(target)

# Apply bleeding on critical hits
func apply_bleeding_effect(target: Node) -> void:
	if not has_meta("bleeding_damage_percent") or not target.has_node("HealthComponent"):
		return
		
	var health_component = target.get_node("HealthComponent")
	var damage_percent = get_meta("bleeding_damage_percent", 0.3)
	var duration = get_meta("bleeding_duration", 4.0)
	var interval = get_meta("bleeding_interval", 0.5)
	
	# Calculate bleeding damage based on base damage
	var base_damage = damage
	if has_node("DmgCalculatorComponent"):
		var dmg_calc = get_node("DmgCalculatorComponent")
		if "base_damage" in dmg_calc:
			base_damage = dmg_calc.base_damage
	
	var bleed_damage_per_tick = int(base_damage * damage_percent)
	
	# Apply DoT
	health_component.apply_dot(
		bleed_damage_per_tick,
		duration,
		interval,
		"bleeding"
	)

# Process splinter arrow effect
func process_splinter_effect(target: Node) -> void:
	# Implementation would go here - this would be called by process_talent_effects
	# We're using a placeholder as the full implementation would be lengthy
	if has_meta("splinter_strategy"):
		var strategy_ref = get_meta("splinter_strategy")
		var strategy = strategy_ref.get_ref() if strategy_ref is WeakRef else strategy_ref
		
		if strategy and strategy.has_method("create_splinters"):
			strategy.create_splinters(self, target)

# Process explosion arrow effect
func process_explosion_effect(target: Node) -> void:
	# Implementation would go here - this would be called by process_talent_effects
	# We're using a placeholder as the full implementation would be lengthy
	if has_meta("explosion_strategy"):
		var strategy_ref = get_meta("explosion_strategy")
		var strategy = strategy_ref.get_ref() if strategy_ref is WeakRef else strategy_ref
		
		if strategy and strategy.has_method("create_explosion"):
			strategy.create_explosion(self, target)

# Find a new target to chain to
func find_chain_target(original_target) -> void:
	# Wait a frame to ensure hit processing is complete
	await get_tree().process_frame
	
	# Find nearby enemies we haven't hit yet
	var potential_targets = []
	var space_state = get_world_2d().direct_space_state
	
	# Create circle query
	var query = PhysicsShapeQueryParameters2D.new()
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = chain_range
	query.shape = circle_shape
	query.transform = Transform2D(0, global_position)
	query.collision_mask = 2  # Enemy layer
	
	# Execute query
	var results = space_state.intersect_shape(query)
	
	# Filter valid targets
	for result in results:
		var body = result.collider
		
		# Skip original target and already hit targets
		if body == original_target or body in hit_targets:
			continue
			
		# Check if it's an enemy with health
		if (body.is_in_group("enemies") or body.get_collision_layer_value(2)) and body.has_node("HealthComponent"):
			potential_targets.append(body)
	
	# If we found at least one valid target
	if potential_targets.size() > 0:
		# Choose random target
		var next_target = potential_targets[randi() % potential_targets.size()]
		
		# Apply damage reduction
		if has_node("DmgCalculatorComponent"):
			var dmg_calc = get_node("DmgCalculatorComponent")
			
			if "base_damage" in dmg_calc:
				dmg_calc.base_damage = int(dmg_calc.base_damage * (1.0 - chain_damage_decay))
				
			if "elemental_damage" in dmg_calc:
				for element_type in dmg_calc.elemental_damage.keys():
					dmg_calc.elemental_damage[element_type] = int(dmg_calc.elemental_damage[element_type] * (1.0 - chain_damage_decay))
		
		# Reduce direct damage
		damage = int(damage * (1.0 - chain_damage_decay))
		
		# Get new trajectory
		var new_direction = (next_target.global_position - global_position).normalized()
		
		# Update direction
		direction = new_direction
		rotation = direction.angle()
		
		# Reset collision
		if has_node("Hurtbox"):
			var hurtbox = get_node("Hurtbox")
			hurtbox.set_deferred("monitoring", true)
			hurtbox.set_deferred("monitorable", true)
		
		# Re-enable collision
		collision_layer = 4
		collision_mask = 2
		
		# Reposition to avoid immediate collision
		global_position += direction * 10
		
		# Increment chain counter
		current_chains += 1
		
		# Reset velocity for proper movement
		velocity = direction * speed
		
		# Allow hits to be processed again
		is_processing_ricochet = false
	else:
		# If arrow also has piercing, let it continue
		if piercing:
			var current_pierce_count = 0
			if has_meta("current_pierce_count"):
				current_pierce_count = get_meta("current_pierce_count")
			
			var max_pierce = 1
			if has_meta("piercing_count"):
				max_pierce = get_meta("piercing_count")
			
			if current_pierce_count <= max_pierce:
				is_processing_ricochet = false
				return
		
		# Otherwise destroy arrow
		queue_free()
