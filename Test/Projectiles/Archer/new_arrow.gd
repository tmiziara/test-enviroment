extends NewProjectileBase
class_name NewArrow

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
	# If this is a pooled arrow being reused, skip standard initialization
	if is_pooled() and has_meta("initialized"):
		return
		
	super._ready()
	if shooter and "crit_chance" in shooter:
		crit_chance = shooter.crit_chance
		print("Setting crit_chance from shooter: ", crit_chance)
	# Initialize hit_targets array if not already done
	if not hit_targets:
		hit_targets = []
		
	# Mark as initialized for pooled objects
	if is_pooled():
		set_meta("initialized", true)

# Override get_damage_package to handle special arrow effects
func get_damage_package() -> Dictionary:
	# Log the current damage values for debugging
	print("NewArrow.get_damage_package - Current damage: " + str(damage))
	# Call parent's method to create base damage package
	var damage_package = super.get_damage_package()
	# Log the package for debugging
	print("Base damage package: " + str(damage_package))
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
		
	print("Final damage package: " + str(damage_package))
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
	print("Arrow process_on_hit called")
	print("Pooled status: ", is_pooled())
	print("Shooter: ", shooter)
	print("Piercing: ", piercing)
	
	# Variável para controlar destruição da flecha - garante que será destruída por padrão
	var should_destroy = true
	
	# Define o alvo atual para cálculos de dano
	set_meta("current_target", target)
	
	# Se já estiver processando um ricochet, ignora este hit
	if is_processing_ricochet:
		print("Already processing ricochet - ignoring hit")
		return
	
	# Adiciona o alvo à lista de alvos atingidos
	if not target in hit_targets:
		hit_targets.append(target)
	
	# Calcula e aplica dano
	if target.has_node("HealthComponent"):
		var health_component = target.get_node("HealthComponent")
		
		# Obtém o pacote de dano específico para este alvo
		var damage_package = get_damage_package()
		
		# Process talent effects from metadata and add to damage package
		if has_node("DmgCalculatorComponent"):
			var dmg_calc = get_node("DmgCalculatorComponent")
			
			# Process fire DoT if configured - either through damage package or the DoTManager
			if dmg_calc.has_meta("fire_dot_data"):
				var dot_data = dmg_calc.get_meta("fire_dot_data")
				var dot_chance = dot_data.get("chance", 0.0)
				
				# Roll for DoT chance
				if randf() <= dot_chance:
					if "dot_effects" not in damage_package:
						damage_package["dot_effects"] = []
					
					# FIXED: Calculate damage based on the TOTAL damage
					# Get the base damage from the damage package or the arrow's damage
					var total_damage = damage_package.get("physical_damage", damage)
					
					# Add elemental damage if any
					var elemental_damage = damage_package.get("elemental_damage", {})
					for element_type in elemental_damage:
						total_damage += elemental_damage[element_type]
					
					# Get DoT percentage or use default
					var dot_percent = dot_data.get("percent_per_tick", 0.05)  # Default to 5% if not specified
					
					# Calculate DoT damage from total damage
					var dot_damage = int(total_damage * dot_percent)
					
					# Ensure minimum damage of 1
					dot_damage = max(1, dot_damage)
					
					print("Calculating fire DoT based on total damage: ", total_damage)
					print("DoT damage per tick: ", dot_damage)
					
					# Add DoT effect to package
					damage_package["dot_effects"].append({
						"damage": dot_damage,
						"duration": dot_data.get("duration", 3.0),
						"interval": dot_data.get("interval", 0.5),
						"type": dot_data.get("type", "fire")
					})
					
					print("Added fire DoT to damage package with damage: ", dot_damage)
		
		# Apply damage with complete package - centralized approach
		health_component.take_complex_damage(damage_package)
		
		# Process special DoT effects like bleeding using DoTManager
		process_special_dot_effects(damage_package, target)
	
	# Emite sinal para sistemas de talentos
	emit_signal("on_hit", target, self)
	
	# Processa efeitos de talentos (exceto DoTs que agora são centralizados no DoTManager)
	process_talent_effects(target)
	
	# Desabilita temporariamente a colisão para evitar múltiplos hits
	if has_node("Hurtbox"):
		var hurtbox = get_node("Hurtbox")
		hurtbox.set_deferred("monitoring", false)
		hurtbox.set_deferred("monitorable", false)
	
	# Verifica Chain Shot
	if chain_shot_enabled and current_chains < max_chains:
		print("Chain shot enabled and can ricochet")
		if not chain_calculated:
			var roll = randf()
			will_chain = (roll <= chain_chance)
			chain_calculated = true
		
		if will_chain:
			print("Arrow will chain")
			is_processing_ricochet = true
			call_deferred("find_chain_target", target)
			should_destroy = false  # Permite que a flecha continue
	
	# Verifica Piercing
	if piercing:
		print("Piercing enabled")
		var current_pierce_count = hit_targets.size() - 1
		var max_pierce = 1
		
		if has_meta("piercing_count"):
			max_pierce = get_meta("piercing_count")
			
		print("Pierce count: ", current_pierce_count, "/", max_pierce)    
		if current_pierce_count < max_pierce:
			# Prepara para próximo hit
			if has_node("Hurtbox"):
				var hurtbox = get_node("Hurtbox")
				# Reabilitamos apenas se for continuar com piercing
				hurtbox.set_deferred("monitoring", true)
				hurtbox.set_deferred("monitorable", true)
			
			# Move a flecha ligeiramente para frente para evitar ficar preso
			global_position += direction * 10
			
			# Mantém a velocidade e direção originais
			velocity = direction * speed
			
			should_destroy = false  # Permite que a flecha continue
		else:
			print("Max pierce count reached")
	
	# Destruição final
	if should_destroy:
		print("Arrow should be destroyed")
		
		# Desabilita física e visibilidade imediatamente
		set_physics_process(false)
		visible = false
		
		# Desabilita colisões completamente usando set_deferred
		if has_node("Hurtbox"):
			var hurtbox = get_node("Hurtbox")
			hurtbox.set_deferred("monitoring", false)
			hurtbox.set_deferred("monitorable", false)
		
		# Desabilita completamente colisões de corpo
		set_deferred("collision_layer", 0)
		set_deferred("collision_mask", 0)
		velocity = Vector2.ZERO
		
		# Retorna ao pool com pequeno delay ou destrói
		if is_pooled():
			print("Returning to pool")
			get_tree().create_timer(0.1).timeout.connect(func():
				return_to_pool()
			)
		else:
			print("Queuing free")
			queue_free()
			
# Versão corrigida para o método process_special_dot_effects
func process_special_dot_effects(damage_package: Dictionary, target: Node) -> void:
	# Check if DoTManager singleton is available
	var dot_manager = get_node_or_null("/root/DoTManager")
	if not dot_manager:
		print("DoTManager not available, DoT effects will be processed by health component")
		return
	
	# Verify the dot_manager has the apply_dot method
	if not dot_manager.has_method("apply_dot"):
		print("DoTManager singleton not properly initialized")
		return
	
	# Calculate TOTAL damage before armor reduction
	var total_damage = damage_package.get("physical_damage", damage)
	var elemental_damage = damage_package.get("elemental_damage", {})
	
	# Add all elemental damage components
	for element_type in elemental_damage:
		total_damage += elemental_damage[element_type]
	
	print("Total damage before armor reduction for DoT calculation: ", total_damage)
	
	# Check for bleeding effect on critical hit
	if is_crit and has_meta("has_bleeding_effect") and damage_package.get("is_critical", false):
		print("Critical hit + bleeding effect detected - applying bleeding via DoTManager")
		
		# Get bleeding metadata from arrow
		var damage_percent = get_meta("bleeding_damage_percent", 0.3)
		var duration = get_meta("bleeding_duration", 4.0)
		var interval = get_meta("bleeding_interval", 0.5)
		
		# FIXED: Calculate bleeding damage based on TOTAL damage before armor reduction
		var bleed_damage_per_tick = int(total_damage * damage_percent)
		
		# Ensure minimum damage of 1
		bleed_damage_per_tick = max(1, bleed_damage_per_tick)
		
		print("Applying bleeding DoT via DoTManager:")
		print("- Damage per tick:", bleed_damage_per_tick)
		print("- Duration:", duration)
		print("- Interval:", interval)
		
		# Apply bleeding via DoTManager
		var dot_id = dot_manager.apply_dot(
			target,
			bleed_damage_per_tick,
			duration,
			interval,
			"bleeding",
			self  # Source is this arrow
		)
		
		if dot_id:
			print("Successfully applied bleeding via DoTManager:", dot_id)
		else:
			print("Failed to apply bleeding via DoTManager")
	
	# Process fire DoT directly via DoTManager if not already added to damage package
	if has_node("DmgCalculatorComponent"):
		var dmg_calc = get_node("DmgCalculatorComponent")
		
		if dmg_calc.has_meta("fire_dot_data") and not "dot_effects" in damage_package:
			var dot_data = dmg_calc.get_meta("fire_dot_data")
			var dot_chance = dot_data.get("chance", 0.0)
			
			# Roll for chance
			if randf() <= dot_chance:
				# FIXED: Calculate fire DoT damage based on TOTAL damage
				var base_dot_damage = dot_data.get("damage_per_tick", 1)
				var dot_percent = dot_data.get("percent", 0.05)  # Default to 5% if not specified
				
				# Calculate based on percentage of total damage if percent is specified
				var dot_damage = base_dot_damage
				if dot_percent > 0:
					dot_damage = int(total_damage * dot_percent)
				
				# Ensure minimum damage of 1
				dot_damage = max(1, dot_damage)
				
				var dot_duration = dot_data.get("duration", 3.0)
				var dot_interval = dot_data.get("interval", 0.5)
				
				print("Applying fire DoT directly via DoTManager:")
				print("- Total damage reference:", total_damage)
				print("- Damage per tick:", dot_damage)
				print("- Duration:", dot_duration)
				print("- Interval:", dot_interval)
				
				# Apply fire DoT via DoTManager
				var dot_id = dot_manager.apply_dot(
					target,
					dot_damage,
					dot_duration,
					dot_interval,
					"fire",
					self  # Source is this arrow
				)
				
				if dot_id:
					print("Successfully applied fire DoT via DoTManager:", dot_id)
				else:
					print("Failed to apply fire DoT via DoTManager")
	
	# Any other specialized DoT effects can be added here
	
	# Any other specialized DoT effects can be added here
# Process effects from talents that trigger on hit
func process_talent_effects(target: Node) -> void:
	print("Processing Talent Effects")
	# Process splinter effect
	if has_meta("has_splinter_effect"):
		print("Splinter effect detected - processing splinters")
		process_splinter_effect(target)
	
	# Process explosion effect
	if has_meta("has_explosion_effect"):
		print("Explosion effect detected - processing explosion")
		process_explosion_effect(target)
	else:
		print("Bleeding not applied. Conditions:")
		print("- Is Critical: ", is_crit)
		print("- Has Bleeding Effect Meta: ", has_meta("has_bleeding_effect"))
		print("- Target has HealthComponent: ", target.has_node("HealthComponent"))
		

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
		
		# Clean up arrow
		if is_pooled():
			return_to_pool()
		else:
			queue_free()

func reset_for_reuse() -> void:
	# Save bleeding metadata before clearing
	var bleeding_meta = {
		"has_bleeding_effect": get_meta("has_bleeding_effect") if has_meta("has_bleeding_effect") else null,
		"bleeding_damage_percent": get_meta("bleeding_damage_percent") if has_meta("bleeding_damage_percent") else null,
		"bleeding_duration": get_meta("bleeding_duration") if has_meta("bleeding_duration") else null,
		"bleeding_interval": get_meta("bleeding_interval") if has_meta("bleeding_interval") else null
	}
	# Clear all states
	current_chains = 0
	chain_calculated = false
	will_chain = false
	is_processing_ricochet = false
	hit_targets.clear()
	
	# Don't clear tags yet - will be repopulated by talents
	velocity = Vector2.ZERO
	
	# Reset damage to base value
	damage = 10  # Use your base arrow damage
	
	# Reset DmgCalculator
	if has_node("DmgCalculatorComponent"):
		var dmg_calc = get_node("DmgCalculatorComponent")
		# Reset apenas os valores que NÃO vêm do atirador
		dmg_calc.base_damage = 10  # Base damage padrão
		dmg_calc.damage_multiplier = 1.0
		dmg_calc.armor_penetration = 0.0
		dmg_calc.elemental_damage = {}
		dmg_calc.additional_effects = []
		dmg_calc.dot_effects = []
	
	# Reset collision properties safely
	if has_node("Hurtbox"):
		var hurtbox = get_node("Hurtbox")
		hurtbox.set_deferred("monitoring", true)
		hurtbox.set_deferred("monitorable", true)
	
	# Reset collision layers
	set_deferred("collision_layer", 4)  # Projectile layer
	set_deferred("collision_mask", 2)   # Enemy layer
	
	# Reset physics processing
	set_physics_process(true)
	
	# Clear all metadata EXCEPT certain keys
	var meta_list = get_meta_list()
	for prop in meta_list:
		# Preserve certain important metadata
		if prop != "pooled" and prop != "initialized":
			remove_meta(prop)
			
	# After clearing metadata, restore the bleeding metadata
	for key in bleeding_meta:
		if bleeding_meta[key] != null:
			set_meta(key, bleeding_meta[key])
			
	# We'll recalculate critical hit AFTER shooter is set
	tags.clear()  # Now clear tags after preserving important metadata
	
# Helper method to check if arrow is from pool
func is_pooled() -> bool:
	return has_meta("pooled") and get_meta("pooled") == true

# Helper method to return arrow to pool
func return_to_pool() -> void:
	print("Attempting to return arrow to pool")
	print("Is pooled: ", is_pooled())
	print("Shooter: ", shooter)
	print("Shooter type: ", typeof(shooter))
	print("Shooter has instance method: ", shooter.has_method("get_instance_id"))
	
	if not is_pooled() or not shooter:
		print("Cannot return to pool - queuing free")
		queue_free()
		return
	
	# Log de verificação do pool
	print("ProjectilePool exists: ", ProjectilePool != null)
	print("ProjectilePool instance exists: ", ProjectilePool.instance != null)
	
	# Return to appropriate pool
	if ProjectilePool and ProjectilePool.instance:
		print("Attempting to return arrow via pool method")
		ProjectilePool.instance.return_arrow_to_pool(self)
	else:
		print("No pool instance - queuing free")
		queue_free()
