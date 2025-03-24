extends ProjectileBase
class_name Arrow

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
	
	print("Arrow Storm configurado:")
	print("  - Habilitado: ", is_enabled)
	print("  - Chance de Trigger: ", trigger_chance * 100, "%")
	print("  - Flechas Adicionais: ", additional_arrows)
	print("  - Ângulo de Dispersão: ", spread_angle, " graus")
	
# Focused Shot properties (directly in the class instead of using meta)
var focused_shot_enabled: bool = false
var focused_shot_bonus: float = 0.0
var focused_shot_threshold: float = 0.75  # Padrão de 75%

# Método para configurar o Focused Shot diretamente
func configure_focused_shot(is_enabled: bool, bonus: float, threshold: float = 0.75) -> void:
	focused_shot_enabled = is_enabled
	focused_shot_bonus = bonus
	focused_shot_threshold = threshold
	print("Focused Shot configurado:")
	print("  - Habilitado: ", is_enabled)
	print("  - Bônus de Dano: ", bonus * 100, "%")
	print("  - Limiar de Vida: ", threshold * 100, "%")

# Chain Shot properties (restante do código original)
var chain_shot_enabled: bool = false
var chain_chance: float = 0.3        # 30% chance to ricochet
var chain_range: float = 150.0       # Maximum range for finding targets
var chain_damage_decay: float = 0.2  # 20% damage reduction for the chained hit
var max_chains: int = 1              # Maximum number of ricochets (1 = one ricochet after initial hit)
var current_chains: int = 0          # Current number of ricochet jumps performed
var hit_targets = []                 # Array to track which targets we've hit (to avoid hitting the same target)
var is_processing_ricochet: bool = false  # Flag to prevent multiple hits during ricochet processing
var will_chain: bool = false         # Flag to store if this arrow will chain (calculated only once)
var chain_calculated: bool = false   # Flag to track if the chain chance has been calculated

func _ready():
	super._ready()
	
	# Initialize hit_targets array if not already done
	if not hit_targets:
		hit_targets = []

# Modifica o método get_damage_package() para melhorar o Focused Shot

func get_damage_package() -> Dictionary:
	# Call the parent's method to create the base damage package
	var damage_package = super.get_damage_package()
	
	# Debug: Print all relevant information
	print("=== FOCUSED SHOT DEBUG START ===")
	print("Focused Shot Enabled: ", focused_shot_enabled)
	print("Focused Shot Bonus: ", focused_shot_bonus)
	print("Focused Shot Threshold: ", focused_shot_threshold)
	
	# Check if Focused Shot is enabled
	if focused_shot_enabled:
		# Try to find the current target
		var current_target = null
		if shooter and shooter.has_method("get_current_target"):
			current_target = shooter.get_current_target()
		elif has_meta("current_target"):
			current_target = get_meta("current_target")
		
		# If there's a valid target
		if current_target and current_target.has_node("HealthComponent"):
			var health_component = current_target.get_node("HealthComponent")
			
			# Check if the health component has the necessary methods
			if "current_health" in health_component and "max_health" in health_component:
				# Calculate health percentage
				var health_percent = float(health_component.current_health) / float(health_component.max_health)
				
				print("Target Health:")
				print("  - Current Health: ", health_component.current_health)
				print("  - Max Health: ", health_component.max_health)
				print("  - Health Percent: ", health_percent * 100, "%")
				print("  - Threshold: ", focused_shot_threshold * 100, "%")
				
				# If health is above threshold, apply bonus
				if health_percent >= focused_shot_threshold:
					print("FOCUSED SHOT ACTIVATED!")
					
					# Increase physical damage
					if "physical_damage" in damage_package:
						var bonus_physical_damage = int(damage_package["physical_damage"] * focused_shot_bonus)
						damage_package["physical_damage"] += bonus_physical_damage
						print("Physical Damage Increased:")
						print("  - Original: ", damage_package["physical_damage"] - bonus_physical_damage)
						print("  - Bonus: ", bonus_physical_damage)
						print("  - New Total: ", damage_package["physical_damage"])
					
					# Increase elemental damage
					if "elemental_damage" in damage_package:
						for element in damage_package["elemental_damage"]:
							var bonus_elem_damage = int(damage_package["elemental_damage"][element] * focused_shot_bonus)
							damage_package["elemental_damage"][element] += bonus_elem_damage
							print("Elemental Damage Increased:")
							print("  - Element: ", element)
							print("  - Original: ", damage_package["elemental_damage"][element] - bonus_elem_damage)
							print("  - Bonus: ", bonus_elem_damage)
							print("  - New Total: ", damage_package["elemental_damage"][element])
						
					# Add Focused Shot tag
					if "tags" not in damage_package:
						damage_package["tags"] = []
					if "focused_shot" not in damage_package["tags"]:
						damage_package["tags"].append("focused_shot")
				else:
					print("FOCUSED SHOT NOT ACTIVATED - Health below threshold")
			else:
				print("ERROR: Health component missing required properties")
		else:
			print("ERROR: Invalid target or no HealthComponent")
	
	print("=== FOCUSED SHOT DEBUG END ===")
	
	return damage_package

# Method called by Hurtbox when the arrow hits a target
func process_on_hit(target: Node) -> void:
	set_meta("current_target", target)
	print("Arrow.process_on_hit called - is_processing_ricochet: ", is_processing_ricochet)
	
	# If we're already processing a ricochet, ignore this hit
	if is_processing_ricochet:
		print("Ignoring hit during ricochet processing")
		return
	
	# Track this target to avoid hitting it again with ricochets
	if not target in hit_targets:
		hit_targets.append(target)
	
	# APPLY DAMAGE! Calculate and apply damage to the target
	if target.has_node("HealthComponent"):
		var health_component = target.get_node("HealthComponent")
		var damage_package = get_damage_package()
		
		print("Aplicando dano ao alvo: ", damage_package)
		
		# Apply damage with the complete package (including DoTs)
		if health_component.has_method("take_complex_damage"):
			health_component.take_complex_damage(damage_package)
		else:
			# Fallback to old method if necessary
			health_component.take_damage(damage_package.get("physical_damage", damage), 
										damage_package.get("is_critical", is_crit))
	
	# Check if Focused Shot is enabled on this arrow
	if focused_shot_enabled:
		apply_focused_shot(target)
	
	# Emit signal that can be used by other systems
	emit_signal("on_hit", target, self)
	
	# Get the current pierce count if this is a piercing projectile
	var current_pierce_count = 0
	if piercing and has_meta("current_pierce_count"):
		current_pierce_count = get_meta("current_pierce_count")
	
	# Get the maximum number of piercings
	var max_pierce = 1
	if has_meta("piercing_count"):
		max_pierce = get_meta("piercing_count")
	
	# Update piercing count if this is a piercing projectile
	if piercing:
		current_pierce_count += 1
		set_meta("current_pierce_count", current_pierce_count)
		print("Arrow pierced ", current_pierce_count, " of ", max_pierce + 1, " possible enemies")
	
	# Check if this arrow should ricochet (Chain Shot)
	if chain_shot_enabled and current_chains < max_chains:
		# Calculate chain chance only once on the first hit
		if not chain_calculated:
			var roll = randf()
			will_chain = (roll <= chain_chance)
			chain_calculated = true
			print("Chain shot chance calculated once: ", roll, " <= ", chain_chance, " = ", will_chain)
		
		# If the arrow will chain (determined on first hit)
		if will_chain:
			# Set the processing flag to prevent multiple hits during ricochet calculation
			is_processing_ricochet = true
			print("Setting is_processing_ricochet to true")
			
			# Try to find a new target to chain to
			call_deferred("find_chain_target", target)
			# Ricochet takes priority over piercing
			return
		else:
			print("Arrow will not chain (determined on first hit)")
			
			# If it has piercing, check if it should continue
			if piercing:
				# Check if piercing limit is reached
				if current_pierce_count > max_pierce:
					print("Piercing limit reached, destroying arrow")
					queue_free()
				else:
					print("Continuing with piercing")
					# Don't destroy the arrow, let it continue
			else:
				# No piercing, destroy the arrow
				print("No piercing, destroying arrow")
				queue_free()
	else:
		# No chain shot capability or max chains reached, check if it has piercing
		if not chain_shot_enabled:
			print("No chain shot capability")
		elif current_chains >= max_chains:
			print("Max chains reached")
			
		if piercing:
			# Check if piercing limit is reached
			if current_pierce_count > max_pierce:
				print("Piercing limit reached, destroying arrow")
				queue_free()
			else:
				print("Continuing with piercing")
				# Don't destroy the arrow, let it continue
		else:
			# No chain shot or piercing, destroy the arrow
			print("No piercing capability, destroying arrow")
			queue_free()

# Function that implements Focused Shot logic
func apply_focused_shot(target: Node) -> void:
	# Verifica se o Focused Shot está habilitado
	if not focused_shot_enabled:
		return
	
	# Store original damage values to restore later
	var original_damage = damage
	var original_base_damage = 0
	var original_elemental_damage = {}
	
	if has_node("DmgCalculatorComponent"):
		var dmg_calc = get_node("DmgCalculatorComponent")
		if "base_damage" in dmg_calc:
			original_base_damage = dmg_calc.base_damage
		if "elemental_damage" in dmg_calc:
			original_elemental_damage = dmg_calc.elemental_damage.duplicate()
	
	# Check if target has a health component
	if target.has_node("HealthComponent"):
		var health_component = target.get_node("HealthComponent")
		
		# Check health percentage
		var health_percent = 0.0
		if "current_health" in health_component and "max_health" in health_component:
			health_percent = float(health_component.current_health) / health_component.max_health
		else:
			print("ERROR: HealthComponent doesn't have current_health or max_health")
			return
		
		# If health is above threshold, apply bonus
		if health_percent >= focused_shot_threshold:
			# Apply temporary bonus to projectile damage
			damage = int(original_damage * (1.0 + focused_shot_bonus))
			print("Focused Shot activated! Damage increased from ", original_damage, " to ", damage, 
				  " (target with ", health_percent * 100, "% health)")
			
			# Apply bonus to DmgCalculator if available
			if has_node("DmgCalculatorComponent"):
				var dmg_calc = get_node("DmgCalculatorComponent")
				
				# Apply bonus to base damage
				if "base_damage" in dmg_calc:
					dmg_calc.base_damage = int(original_base_damage * (1.0 + focused_shot_bonus))
					print("Calculator base damage increased from ", original_base_damage, " to ", dmg_calc.base_damage)
				
				# Also apply bonus to all elemental damages
				if "elemental_damage" in dmg_calc:
					for element_type in original_elemental_damage.keys():
						if element_type in dmg_calc.elemental_damage:
							var orig_elem_dmg = original_elemental_damage[element_type]
							dmg_calc.elemental_damage[element_type] = int(orig_elem_dmg * (1.0 + focused_shot_bonus))
		
	# Schedule restoration of original values after hit processing
	call_deferred("reset_focused_shot_bonuses", original_damage, original_base_damage, original_elemental_damage)

# Method to restore original values after applying Focused Shot bonus
func reset_focused_shot_bonuses(orig_damage: int, orig_base_damage: int, orig_elemental_damage: Dictionary) -> void:
	# Restore original projectile damage
	damage = orig_damage
	
	# Restore original values in DmgCalculator
	if has_node("DmgCalculatorComponent"):
		var dmg_calc = get_node("DmgCalculatorComponent")
		
		if "base_damage" in dmg_calc:
			dmg_calc.base_damage = orig_base_damage
		
		if "elemental_damage" in dmg_calc:
			for element_type in orig_elemental_damage.keys():
				if element_type in dmg_calc.elemental_damage:
					dmg_calc.elemental_damage[element_type] = orig_elemental_damage[element_type]
	
	print("Damage values restored after Focused Shot application")

# Finds a new target to chain to after hitting an enemy
func find_chain_target(original_target) -> void:
	print("Finding chain target...")
	
	# Wait a frame to make sure hit processing is complete
	await get_tree().process_frame
	
	# Find nearby enemies that we haven't hit yet
	var potential_targets = []
	var space_state = get_world_2d().direct_space_state
	
	# Create a circle shape query to find potential targets
	var query = PhysicsShapeQueryParameters2D.new()
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = chain_range
	query.shape = circle_shape
	query.transform = Transform2D(0, global_position)
	query.collision_mask = 2  # Mask for enemies - adjust if needed
	
	# Execute the shape query
	var results = space_state.intersect_shape(query)
	
	# Filter to find valid targets
	for result in results:
		var body = result.collider
		
		# Skip the original target and any already hit targets
		if body == original_target or body in hit_targets:
			continue
			
		# Check if it's an enemy with a health component
		if (body.is_in_group("enemies") or body.get_collision_layer_value(2)) and body.has_node("HealthComponent"):
			potential_targets.append(body)
	
	# If we found at least one valid target
	if potential_targets.size() > 0:
		# Choose a random target from the valid ones
		var next_target = potential_targets[randi() % potential_targets.size()]
		print("Chain Shot target found! Ricocheting to new target.")
		
		# Apply damage reduction for chained shots if we have DmgCalculatorComponent
		if has_node("DmgCalculatorComponent"):
			var dmg_calc = get_node("DmgCalculatorComponent")
			if "base_damage" in dmg_calc:
				dmg_calc.base_damage = int(dmg_calc.base_damage * (1.0 - chain_damage_decay))
				
			if "elemental_damage" in dmg_calc:
				for element_type in dmg_calc.elemental_damage.keys():
					dmg_calc.elemental_damage[element_type] = int(dmg_calc.elemental_damage[element_type] * (1.0 - chain_damage_decay))
		
		# Also reduce the direct damage
		damage = int(damage * (1.0 - chain_damage_decay))
		
		# Get the new trajectory vector
		var new_direction = (next_target.global_position - global_position).normalized()
		
		# Update direction to the new target
		direction = new_direction
		rotation = direction.angle()
		
		# Reset any collision flags/state that might be causing the arrow to pass through
		if has_node("Hurtbox"):
			var hurtbox = get_node("Hurtbox")
			# Re-enable the hurtbox monitoring and monitorable properties
			hurtbox.set_deferred("monitoring", true)
			hurtbox.set_deferred("monitorable", true)
		
		# Make sure our collision is enabled
		collision_layer = 4  # Make sure this matches your projectile layer
		collision_mask = 2   # Make sure this matches your enemy layer
		
		# Enable any collision shapes that might have been disabled
		for child in get_children():
			if child is CollisionShape2D or child is CollisionPolygon2D:
				child.set_deferred("disabled", false)
		
		# Reposition arrow slightly away from the hit point to avoid immediate collision
		global_position += direction * 10
		
		# Increment the chain counter
		current_chains += 1
		
		# Reset velocity for proper movement
		velocity = direction * speed
		
		# Allow hits to be processed again
		is_processing_ricochet = false
		print("Setting is_processing_ricochet back to false")
		
		# For debugging the position
		print("Repositioned arrow at: ", global_position, " heading toward: ", next_target.global_position)
	else:
		print("No valid chain targets found within range.")
		# If the arrow also has piercing, let it continue its path
		if piercing:
			var current_pierce_count = 0
			if has_meta("current_pierce_count"):
				current_pierce_count = get_meta("current_pierce_count")
			
			var max_pierce = 1
			if has_meta("piercing_count"):
				max_pierce = get_meta("piercing_count")
			
			if current_pierce_count <= max_pierce:
				print("No chain targets, but continuing with piercing")
				is_processing_ricochet = false
				return
		
		# Otherwise destroy the arrow
		print("No chain targets and no piercing, destroying arrow")
		queue_free()
# Método opcional para tentar spawnar flechas adicionais
func try_spawn_additional_arrows(target) -> Array:
	# Verifica se o Arrow Storm está habilitado
	if not arrow_storm_enabled or randf() > arrow_storm_trigger_chance:
		return [self]
	
	print("Arrow Storm TRIGGERED!")
	var additional_projectiles = []
	
	# Calcula direções para as flechas adicionais
	var base_direction = direction
	var half_spread = arrow_storm_spread_angle / 2.0
	
	# Cria flechas adicionais
	for i in range(arrow_storm_additional_arrows):
		# Calcula ângulo de deslocamento (de -half_spread a +half_spread)
		var angle_offset = lerp(-half_spread, half_spread, float(i) / (arrow_storm_additional_arrows - 1))
		
		# Rotaciona a direção base
		var rotated_direction = base_direction.rotated(deg_to_rad(angle_offset))
		
		# Clona o projétil original
		var new_projectile = duplicate()
		
		# Configura nova direção
		new_projectile.direction = rotated_direction
		new_projectile.rotation = rotated_direction.angle()
		
		# Reseta velocidade com nova direção
		new_projectile.velocity = rotated_direction * speed
		
		# Adiciona tag de identificação
		if has_method("add_tag"):
			new_projectile.add_tag("arrow_storm")
		elif "tags" in new_projectile:
			if not "arrow_storm" in new_projectile.tags:
				new_projectile.tags.append("arrow_storm")
		
		# Adiciona à lista de projéteis
		additional_projectiles.append(new_projectile)
	
	# Retorna lista com projétil original + projéteis adicionais
	print("Arrow Storm: ", additional_projectiles.size() + 1, " arrows spawned")
	return [self] + additional_projectiles

# Método auxiliar para conversão de graus para radianos
func deg_to_rad(degrees: float) -> float:
	return degrees * (PI / 180.0)
