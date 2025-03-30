extends Node
class_name ConsolidatedTalentSystem

# Cache para armazenar efeitos compilados
var compiled_effects: Dictionary = {}

# Referência ao archer
var archer: Soldier_Base

# Estrutura para armazenar efeitos consolidados
class CompiledEffects:
	# Efeitos básicos
	var damage_multiplier: float = 1.0
	var crit_chance_bonus: float = 0.0
	var crit_damage_multiplier: float = 1.0
	var armor_penetration: float = 0.0
	var range_multiplier: float = 1.0
	var attack_speed_multiplier: float = 1.0
	
	# Efeitos de dano elemental
	var fire_damage_percent: float = 0.0
	var fire_dot_damage_percent: float = 0.0
	var fire_dot_duration: float = 0.0
	var fire_dot_interval: float = 0.0
	var fire_dot_chance: float = 0.0
	
	# Efeitos de projétil
	var piercing_count: int = 0
	var can_chain: bool = false
	var chain_chance: float = 0.0
	var chain_range: float = 0.0
	var chain_damage_decay: float = 0.0
	var max_chains: int = 0
	
	# Efeitos de múltiplos projéteis
	var double_shot_enabled: bool = false
	var double_shot_angle: float = 0.0
	
	# Efeitos especiais de acerto
	var focused_shot_enabled: bool = false
	var focused_shot_bonus: float = 0.0
	var focused_shot_threshold: float = 0.0
	
	var mark_enabled: bool = false
	var mark_duration: float = 0.0
	var mark_crit_bonus: float = 0.0
	
	var bleed_on_crit: bool = false
	var bleed_damage_percent: float = 0.0
	var bleed_duration: float = 0.0
	var bleed_interval: float = 0.0
	
	var can_splinter: bool = false
	var splinter_count: int = 0
	var splinter_damage_percent: float = 0.0
	var splinter_range: float = 0.0
	
	# Efeitos de área
	var explosion_enabled: bool = false
	var explosion_damage_percent: float = 0.0
	var explosion_radius: float = 0.0
	
	var arrow_rain_enabled: bool = false
	var arrow_rain_count: int = 0
	var arrow_rain_damage_percent: float = 0.0
	var arrow_rain_radius: float = 0.0
	var arrow_rain_interval: int = 0
	
	# Efeito stackável do Bloodseeker
	var bloodseeker_enabled: bool = false
	var bloodseeker_bonus_per_stack: float = 0.0
	var bloodseeker_max_stacks: int = 0

# Inicializa o sistema para um arqueiro específico
func _init(archer_ref: Soldier_Base):
	archer = archer_ref

func compile_effects() -> CompiledEffects:
	var effects = CompiledEffects.new()
	
	# Validate archer reference
	if not archer:
		push_error("ConsolidatedTalentSystem: No archer reference")
		return effects
	
	# Limpa SEMPRE o cache para garantir valores atualizados
	compiled_effects.clear()
	
	# Processa cada estratégia e compila os efeitos
	print("Compilando efeitos a partir de ", archer.attack_upgrades.size(), " estratégias:")
	for strategy in archer.attack_upgrades:
		if strategy:
			var strategy_name = strategy.get_script().get_path().get_file().get_basename()
			print("- Processando estratégia: ", strategy_name)
			_apply_strategy_effects(strategy, effects)
	
	# Retorna os efeitos compilados
	return effects

# Gera uma chave única para o cache baseada nos talentos ativos
func _generate_cache_key() -> String:
	var key = ""
	for strategy in archer.attack_upgrades:
		if strategy:
			key += strategy.get_path() + ";"
	return key

# Replace your _apply_strategy_effects method with this more robust approach

func _apply_strategy_effects(strategy: BaseProjectileStrategy, effects: CompiledEffects) -> void:
	if not strategy:
		return
		
	# Get file name directly for precise matching
	var strategy_path = strategy.get_script().get_path()
	var file_name = strategy_path.get_file()
	var strategy_name = strategy.get_class()
	
	# Try to get a friendlier name if available
	if strategy.has_method("get_strategy_name"):
		strategy_name = strategy.call("get_strategy_name")
	
	print("Processing strategy: ", strategy_name)
	print("Strategy file: ", file_name)
	
	# Extract the talent number using regex
	var regex = RegEx.new()
	regex.compile("Talent_(\\d+)\\.gd")
	var result = regex.search(file_name)
	
	if result:
		var talent_id = int(result.get_string(1))
		print("Detected Talent ID: ", talent_id)
		
		# Process talents by their numeric ID
		match talent_id:
			1:  # Precise Aim
				var damage_bonus = strategy.get("damage_increase_percent")
				if damage_bonus != null:
					effects.damage_multiplier += damage_bonus
					
			2:  # Enhanced Range
				var range_bonus = strategy.get("range_increase_percentage")
				if range_bonus != null:
					effects.range_multiplier += range_bonus / 100.0
					
			3:  # Sharp Arrows
				var armor_pen = strategy.get("armor_penetration")
				if armor_pen != null:
					effects.armor_penetration += armor_pen
					
			4:  # Piercing Shot
				var pierce_count = strategy.get("piercing_count")
				if pierce_count != null:
					effects.piercing_count += pierce_count
					
			5:  # Focused Shot
				var bonus_percent = strategy.get("damage_bonus_percent")
				var threshold = strategy.get("health_threshold")
				
				if bonus_percent != null and threshold != null:
					effects.focused_shot_enabled = true
					effects.focused_shot_bonus = bonus_percent
					effects.focused_shot_threshold = threshold
					
			6:  # Flaming Arrows
				print("Processing Talent_6 (Flaming Arrows)")
				
				# Safely access properties using proper property names
				var fire_damage_percent = strategy.get("fire_damage_percent")
				var dot_percent_per_tick = strategy.get("dot_percent_per_tick")
				var dot_duration = strategy.get("dot_duration")
				var dot_interval = strategy.get("dot_interval")
				var dot_chance = strategy.get("dot_chance")  # Default 30% chance
				
				print("Flaming Arrows values retrieved:")
				print("- Fire damage percent: ", fire_damage_percent)
				print("- DoT damage per tick: ", dot_percent_per_tick)
				print("- DoT duration: ", dot_duration)
				print("- DoT interval: ", dot_interval)
				print("- DoT chance: ", dot_chance)
				
				# Apply fire damage effect
				effects.fire_damage_percent = fire_damage_percent
				
				# Apply fire DoT effect
				effects.fire_dot_damage_percent = dot_percent_per_tick
				effects.fire_dot_duration = dot_duration
				effects.fire_dot_interval = dot_interval
				effects.fire_dot_chance = dot_chance
				
				print("Flaming Arrows effect configured successfully")
				
			11:  # Double Shot
				var angle_spread = strategy.get("angle_spread")
				if angle_spread != null:
					effects.double_shot_enabled = true
					effects.double_shot_angle = angle_spread
					
			12:  # Chain Shot
				var chain_chance = strategy.get("chain_chance")
				var chain_range = strategy.get("chain_range")
				var chain_decay = strategy.get("chain_damage_decay")
				var max_chains = strategy.get("max_chains")
				
				if chain_chance != null and chain_range != null and chain_decay != null and max_chains != null:
					effects.can_chain = true
					effects.chain_chance = chain_chance
					effects.chain_range = chain_range
					effects.chain_damage_decay = chain_decay
					effects.max_chains = max_chains
					
			13:  # Arrow Rain
				var arrow_count = strategy.get("arrow_count")
				var damage_per_arrow = strategy.get("damage_per_arrow")
				var radius = strategy.get("radius")
				var attacks_threshold = strategy.get("attacks_threshold")
				
				if arrow_count != null and damage_per_arrow != null and radius != null and attacks_threshold != null:
					effects.arrow_rain_enabled = true
					effects.arrow_rain_count = arrow_count
					effects.arrow_rain_damage_percent = damage_per_arrow / 10.0
					effects.arrow_rain_radius = radius
					effects.arrow_rain_interval = attacks_threshold
					
			14:  # Splinter Arrows
				var splinter_count = strategy.get("splinter_count")
				var splinter_damage = strategy.get("splinter_damage_percent")
				var splinter_range = strategy.get("splinter_range")
				
				if splinter_count != null and splinter_damage != null and splinter_range != null:
					effects.can_splinter = true
					effects.splinter_count = splinter_count
					effects.splinter_damage_percent = splinter_damage
					effects.splinter_range = splinter_range
					
			15:  # Arrow Explosion
				var damage_percent = strategy.get("explosion_damage_percent")
				var radius = strategy.get("explosion_radius")
				
				if damage_percent != null and radius != null:
					effects.explosion_enabled = true
					effects.explosion_damage_percent = damage_percent
					effects.explosion_radius = radius
					
			16:  # Serrated Arrows (Bleeding)
				print("Processing Talent_16 (Serrated Arrows - Bleeding)")
				
				# Print all available properties to help diagnose the issue
				print("Available properties in strategy:")
				for property in strategy.get_property_list():
					print("- ", property.name, ": ", strategy.get(property.name) if strategy.get(property.name) != null else "null")
				
				# Use the correct property names from your Talent_16 class
				var bleed_damage = strategy.bleeding_damage_percent
				var bleed_duration = strategy.bleeding_duration
				var bleed_interval = strategy.dot_interval  # This should match the property name in Talent_16
				
				print("Bleeding values retrieved from resource:")
				print("- Damage percent: ", bleed_damage)
				print("- Duration: ", bleed_duration)
				print("- Interval: ", bleed_interval)
				
				# Configure bleeding effect with the retrieved values
				effects.bleed_on_crit = true
				effects.bleed_damage_percent = bleed_damage
				effects.bleed_duration = bleed_duration
				effects.bleed_interval = bleed_interval
				
				print("Bleeding effect configured successfully")
					
			17:  # Marked for Death
				var mark_duration = strategy.get("mark_duration")
				var crit_bonus = strategy.get("crit_damage_bonus")
				
				if mark_duration != null and crit_bonus != null:
					effects.mark_enabled = true
					effects.mark_duration = mark_duration
					effects.mark_crit_bonus = crit_bonus
					
			18:  # Bloodseeker
				var damage_increase = strategy.get("damage_increase_per_stack")
				var max_stacks = strategy.get("max_stacks")
				
				if damage_increase != null and max_stacks != null:
					effects.bloodseeker_enabled = true
					print("ConsolidatedTalentSystem: effects ID=", effects.get_instance_id(), " bloodseeker_enabled=", effects.bloodseeker_enabled)
					print(Time.get_ticks_msec(), ": Definindo bloodseeker_enabled=true")
					effects.bloodseeker_bonus_per_stack = damage_increase
					effects.bloodseeker_max_stacks = max_stacks
					
			# Add additional talent cases as needed for talents 19-30
			_:
				print("Unhandled talent ID: ", talent_id)
				# You can add a default handling for talents not yet specifically implemented
				
	else:
		# Handle the case where the talent ID couldn't be extracted
		print("WARNING: Could not extract talent ID from: ", file_name)


func apply_compiled_effects(projectile: Node, effects: CompiledEffects) -> void:
	print("ConsolidatedTalentSystem: Applying compiled effects to projectile")
	
	# Apply basic stats with proper logging
	if "damage" in projectile:
		var original_damage = projectile.damage
		# Apply damage multiplier properly
		projectile.damage = int(original_damage * effects.damage_multiplier)
		print("Damage updated: " + str(original_damage) + " -> " + str(projectile.damage))
	
	if "crit_chance" in projectile:
		var original_crit = projectile.crit_chance
		projectile.crit_chance = min(projectile.crit_chance + effects.crit_chance_bonus, 1.0)
		print("Crit chance updated: " + str(original_crit) + " -> " + str(projectile.crit_chance))
	
	# CRITICAL: Update the DmgCalculator component
	if projectile.has_node("DmgCalculatorComponent"):
		var dmg_calc = projectile.get_node("DmgCalculatorComponent")
		
		# Apply damage multiplier to base_damage
		if "base_damage" in dmg_calc:
			var original_base = dmg_calc.base_damage
			dmg_calc.base_damage = int(original_base * effects.damage_multiplier)
			print("DmgCalc base damage updated: " + str(original_base) + " -> " + str(dmg_calc.base_damage))
		
		# Also set the damage_multiplier properly
		if "damage_multiplier" in dmg_calc:
			var original_mult = dmg_calc.damage_multiplier
			dmg_calc.damage_multiplier = effects.damage_multiplier
			print("DmgCalc multiplier updated: " + str(original_mult) + " -> " + str(dmg_calc.damage_multiplier))
		
		# Apply armor penetration
		if effects.armor_penetration > 0:
			dmg_calc.armor_penetration = effects.armor_penetration
			print("DmgCalc armor penetration set to: " + str(dmg_calc.armor_penetration))
			projectile.add_tag("armor_piercing")
	
	# Apply attack tags
	_ensure_tags_array(projectile)
	
	# No apply_compiled_effects
	if effects.fire_damage_percent > 0:
		projectile.add_tag("fire")
		if projectile.has_node("DmgCalculatorComponent"):
			var dmg_calc = projectile.get_node("DmgCalculatorComponent")
			var total_damage = dmg_calc.calculate_damage()
			
			# Adiciona dano elemental de fogo
			var fire_damage = int(total_damage["physical_damage"] * effects.fire_damage_percent)
			if "elemental_damage" in dmg_calc:
				if "fire" in dmg_calc.elemental_damage:
					dmg_calc.elemental_damage["fire"] += fire_damage
				else:
					dmg_calc.elemental_damage["fire"] = fire_damage
			
			# Configura dados de DoT como metadados para o sistema de DoT processar
			var dot_data = {
				"damage_per_tick": int(total_damage["physical_damage"] * effects.fire_dot_damage_percent),
				"duration": effects.fire_dot_duration,
				"interval": effects.fire_dot_interval,
				"chance": effects.fire_dot_chance,
				"type": "fire"
			}
			dmg_calc.set_meta("fire_dot_data", dot_data)
	
	# Aplica piercing
	if effects.piercing_count > 0:
		print("Applying piercing: ", effects.piercing_count)
		projectile.piercing = true
		projectile.set_meta("piercing_count", effects.piercing_count)
		projectile.add_tag("piercing")
		
		# Para projéteis físicos, desabilita colisão com inimigos
		if projectile is CharacterBody2D:
			print("Disabling collision with enemies for piercing")
			projectile.set_collision_mask_value(2, false)  # Layer 2 = enemy layer
	
	# Apply Chain Shot
	if effects.can_chain:
		_setup_chain_shot(projectile, effects)
		print("Chain Shot enabled: " + str(effects.chain_chance * 100) + "% chance, " + str(effects.max_chains) + " max chains")
	
	# Apply Focused Shot
	if effects.focused_shot_enabled:
		# Adiciona tag e meta para identificação
		projectile.add_tag("focused_shot")
		# Configurações do Focused Shot
		projectile.set_meta("focused_shot_enabled", true)
		projectile.set_meta("focused_shot_bonus", effects.focused_shot_bonus)
		projectile.set_meta("focused_shot_threshold", effects.focused_shot_threshold)
		
		print("Focused Shot enabled: " + str(effects.focused_shot_bonus * 100) + "% damage boost above " + str(effects.focused_shot_threshold * 100) + "% health")
	
	print("CRITICAL DEBUG: effects.bleed_on_crit=", effects.bleed_on_crit)
	
	if effects.bleed_on_crit:
		print("CRITICAL DEBUG: Applying bleeding metadata to projectile")
		
		# Force the metadata directly on the projectile
		projectile.set_meta("has_bleeding_effect", true)
		projectile.set_meta("bleeding_damage_percent", effects.bleed_damage_percent)
		projectile.set_meta("bleeding_duration", effects.bleed_duration)
		projectile.set_meta("bleeding_interval", effects.bleed_interval)
		
		# Add tag
		projectile.add_tag("bleeding")
		
		print("Bleeding metadata configured:")
		print("- has_bleeding_effect:", projectile.has_meta("has_bleeding_effect"))
		print("- bleeding_damage_percent:", projectile.get_meta("bleeding_damage_percent"))
		print("- bleeding_duration:", projectile.get_meta("bleeding_duration"))
		print("- bleeding_interval:", projectile.get_meta("bleeding_interval"))

	# Apply Marked for Death
	if effects.mark_enabled:
		projectile.set_meta("has_mark_effect", true)
		projectile.set_meta("mark_duration", effects.mark_duration)
		projectile.set_meta("mark_crit_bonus", effects.mark_crit_bonus)
		projectile.add_tag("marked_for_death")
	# Apply Explosion
	if effects.explosion_enabled:
		projectile.set_meta("has_explosion_effect", true)
		projectile.set_meta("explosion_damage_percent", effects.explosion_damage_percent)
		projectile.set_meta("explosion_radius", effects.explosion_radius)
		projectile.add_tag("explosive")
		print("Explosion enabled: " + str(effects.explosion_damage_percent * 100) + "% damage in " + str(effects.explosion_radius) + " radius")
	
	# Apply Splinter
	if effects.can_splinter:
		projectile.set_meta("has_splinter_effect", true)
		projectile.set_meta("splinter_count", effects.splinter_count)
		projectile.set_meta("splinter_damage_percent", effects.splinter_damage_percent)
		projectile.set_meta("splinter_range", effects.splinter_range)
		projectile.add_tag("splinter")
		print("Splinter enabled: " + str(effects.splinter_count) + " splinters, " + str(effects.splinter_damage_percent * 100) + "% damage each")
	
	# Apply Bloodseeker
	if effects.bloodseeker_enabled:
		projectile.set_meta("has_bloodseeker_effect", true)
		projectile.set_meta("damage_increase_per_stack", effects.bloodseeker_bonus_per_stack)
		projectile.set_meta("max_stacks", effects.bloodseeker_max_stacks)
		projectile.add_tag("bloodseeker")
		
		# Apply current bonus if archer has stacks
		if projectile.shooter and projectile.shooter.has_meta("bloodseeker_data"):
			var data = projectile.shooter.get_meta("bloodseeker_data")
			var stacks = data.get("stacks", 0)
			if stacks > 0:
				var bonus = effects.bloodseeker_bonus_per_stack * stacks
				var pre_bonus_damage = projectile.damage
				projectile.damage = int(projectile.damage * (1 + bonus))
				print("Applied Bloodseeker stacks: " + str(stacks) + " (" + str(pre_bonus_damage) + " -> " + str(projectile.damage) + ")")
				
				if projectile.has_node("DmgCalculatorComponent"):
					var dmg_calc = projectile.get_node("DmgCalculatorComponent")
					if "damage_multiplier" in dmg_calc:
						dmg_calc.damage_multiplier *= (1 + bonus)
						print("Applied Bloodseeker multiplier: " + str(dmg_calc.damage_multiplier))

# Setup chain shot functionality
func _setup_chain_shot(projectile, effects: CompiledEffects) -> void:
	if projectile is Arrow:
		projectile.chain_shot_enabled = true
		projectile.chain_chance = effects.chain_chance
		projectile.chain_range = effects.chain_range
		projectile.chain_damage_decay = effects.chain_damage_decay
		projectile.max_chains = effects.max_chains
		projectile.current_chains = 0
		projectile.hit_targets = []
		projectile.add_tag("chain_shot")
	else:
		# For non-Arrow projectiles, use metadata
		projectile.set_meta("chain_shot_enabled", true)
		projectile.set_meta("chain_chance", effects.chain_chance)
		projectile.set_meta("chain_range", effects.chain_range)
		projectile.set_meta("chain_damage_decay", effects.chain_damage_decay)
		projectile.set_meta("max_chains", effects.max_chains)
		projectile.set_meta("current_chains", 0)
		projectile.set_meta("hit_targets", [])
		projectile.add_tag("chain_shot")

# Helper to ensure tags array exists
func _ensure_tags_array(projectile: Node) -> void:
	if not "tags" in projectile:
		projectile.tags = []
	
	# Ensure projectile has add_tag method
	if not projectile.has_method("add_tag"):
		projectile.add_tag = func(tag_name: String) -> void:
			if not tag_name in projectile.tags:
				projectile.tags.append(tag_name)

# Spawns a double shot based on the original arrow
func spawn_double_shot(original_projectile: Node, effects: CompiledEffects) -> void:
	if not effects.double_shot_enabled:
		return
		
	var shooter = original_projectile.shooter
	if not shooter:
		return
		
	# Get references
	var direction = original_projectile.direction
	var start_position = original_projectile.global_position
	
	# Load arrow scene
	var arrow_scene = load("res://Test/Projectiles/Archer/Arrow.tscn")
	if not arrow_scene:
		print("ERROR: Could not load arrow scene for double shot")
		return
		
	# Create second arrow
	var second_arrow = arrow_scene.instantiate()
	
	# Configure position and direction with angle offset
	second_arrow.global_position = start_position
	var angle_offset = deg_to_rad(effects.double_shot_angle)
	var rotated_direction = direction.rotated(angle_offset)
	second_arrow.direction = rotated_direction
	second_arrow.rotation = rotated_direction.angle()
	
	# Set shooter (IMPORTANT: do this before adding to tree)
	second_arrow.shooter = shooter
	
	# Mark as second arrow to avoid recursion
	second_arrow.set_meta("is_second_arrow", true)
	
	# Apply all compiled effects (except double shot)
	var second_effects = effects.duplicate()
	second_effects.double_shot_enabled = false  # Prevent recursion
	apply_compiled_effects(second_arrow, second_effects)
	
	# Add to scene
	if shooter and shooter.get_parent():
		shooter.get_parent().call_deferred("add_child", second_arrow)
		
# Check and possibly trigger Arrow Rain
func check_arrow_rain(current_projectile: Node, effects: CompiledEffects) -> bool:
	if not effects.arrow_rain_enabled:
		return false
		
	var shooter = current_projectile.shooter
	if not shooter:
		return false
		
	# Initialize attack counter if needed
	if not shooter.has_meta("arrow_rain_counter"):
		shooter.set_meta("arrow_rain_counter", 0)
		
	# Increment counter
	var counter = shooter.get_meta("arrow_rain_counter")
	counter += 1
	shooter.set_meta("arrow_rain_counter", counter)
	
	# Check if threshold reached
	if counter >= effects.arrow_rain_interval:
		# Reset counter
		shooter.set_meta("arrow_rain_counter", 0)
		
		# Spawn arrow rain
		spawn_arrow_rain(current_projectile, effects)
		return true
	
	return false

# Spawn arrow rain based on original projectile
func spawn_arrow_rain(projectile: Node, effects: CompiledEffects) -> void:
	var shooter = projectile.shooter
	if not shooter:
		return
		
	# Define target position
	var target_position = Vector2.ZERO
	var target = null
	
	# Find target
	if shooter.has_method("get_current_target"):
		target = shooter.get_current_target()
	elif "current_target" in shooter:
		target = shooter.current_target
	
	# Set target position
	if target and is_instance_valid(target):
		target_position = target.global_position
	else:
		target_position = projectile.global_position + projectile.direction * 300
	
	# Load arrow scene
	var arrow_scene = load("res://Test/Projectiles/Archer/Arrow.tscn")
	if not arrow_scene:
		return
		
	# Remove double shot from rain arrows
	var rain_effects = effects.duplicate()
	rain_effects.double_shot_enabled = false
	
	# Spawn arrows
	for i in range(effects.arrow_rain_count):
		var arrow = arrow_scene.instantiate()
		
		# Fall position with dispersion
		var fall_position = target_position
		
		if effects.arrow_rain_count > 1:
			var angle = randf() * TAU
			var rand_radius = sqrt(randf()) * effects.arrow_rain_radius
			var random_offset = Vector2(cos(angle) * rand_radius, sin(angle) * rand_radius)
			fall_position += random_offset
		
		# Initial height for spawn
		var random_height = randf_range(200, 250)
		var horizontal_offset = randf_range(-50, 50)
		arrow.global_position = Vector2(fall_position.x + horizontal_offset, fall_position.y - random_height)
		
		# Base configuration
		arrow.damage = int(projectile.damage * effects.arrow_rain_damage_percent)
		arrow.crit_chance = projectile.crit_chance
		arrow.shooter = shooter
		arrow.speed = 500.0
		arrow.direction = (fall_position - arrow.global_position).normalized()
		arrow.rotation = arrow.direction.angle()
		
		# Add rain tag
		arrow.tags = []
		arrow.add_tag = func(tag_name: String) -> void:
			if not tag_name in arrow.tags:
				arrow.tags.append(tag_name)
		arrow.add_tag("rain_arrow")
		
		# Apply effects to arrow
		apply_compiled_effects(arrow, rain_effects)
		
		# Custom motion setup
		setup_custom_motion(arrow, fall_position)
		
		# Add to scene
		shooter.get_parent().add_child(arrow)
	
# Setup custom motion for arrow rain
func setup_custom_motion(arrow: Node, impact_position: Vector2) -> void:
	# Disable standard collisions
	if arrow.has_node("Hurtbox"):
		var hurtbox = arrow.get_node("Hurtbox")
		hurtbox.monitoring = false
		hurtbox.monitorable = false
	
	if arrow is CharacterBody2D:
		arrow.collision_layer = 0
		arrow.collision_mask = 0
		
		for child in arrow.get_children():
			if child is CollisionShape2D or child is CollisionPolygon2D:
				child.disabled = true
	
	# Calculate time for impact
	var fall_distance = arrow.global_position.distance_to(impact_position)
	var fall_time = fall_distance / arrow.speed
	
	# Store impact data
	arrow.set_meta("impact_position", impact_position)
	arrow.set_meta("fall_time", fall_time)
	
	# Create timer for impact
	var impact_timer = Timer.new()
	impact_timer.one_shot = true
	impact_timer.wait_time = fall_time
	arrow.add_child(impact_timer)
	
	# Create shadow
	var shadow = create_shadow(impact_position, arrow.get_parent())
	
	# Setup impact
	var arrow_ref = weakref(arrow)
	var shadow_ref = weakref(shadow)
	
	impact_timer.timeout.connect(func():
		var arrow_inst = arrow_ref.get_ref()
		var shadow_inst = shadow_ref.get_ref()
		
		if arrow_inst and is_instance_valid(arrow_inst):
			process_impact(arrow_inst, impact_position, shadow_inst)
	)
	impact_timer.start()
	
	# Safety timer
	var destroy_timer = Timer.new()
	destroy_timer.one_shot = true 
	destroy_timer.wait_time = fall_time + 0.5
	arrow.add_child(destroy_timer)
	
	destroy_timer.timeout.connect(func():
		var arrow_inst = arrow_ref.get_ref()
		if arrow_inst and is_instance_valid(arrow_inst):
			arrow_inst.queue_free()
	)
	destroy_timer.start()
	
	# Create processor script
	var custom_script = GDScript.new()
	custom_script.source_code = """
	extends Node
	
	var start_position: Vector2
	var impact_position: Vector2
	var total_time: float
	var elapsed_time: float = 0.0
	
	func _ready():
		var arrow = get_parent()
		start_position = arrow.global_position
		
		# Get stored properties
		if arrow.has_meta("impact_position"):
			impact_position = arrow.get_meta("impact_position")
		
		if arrow.has_meta("fall_time"):
			total_time = arrow.get_meta("fall_time")
			
		# Apply correct rotation
		var direction = (impact_position - start_position).normalized()
		arrow.direction = direction
		arrow.rotation = direction.angle()
	
	func _physics_process(delta):
		var arrow = get_parent()
		
		# Increment elapsed time
		elapsed_time += delta
		
		# Calculate progress (0 to 1)
		var progress = min(elapsed_time / total_time, 1.0)
		
		# Linear interpolation of position
		var new_position = start_position.lerp(impact_position, progress)
		
		# Add arc effect
		var arc_height = start_position.distance_to(impact_position) * 0.05
		var arc_offset = sin(progress * PI) * arc_height
		
		# Apply offset
		new_position.y -= arc_offset
		
		# Update position
		arrow.global_position = new_position
		
		# Calculate tangent direction for rotation
		var next_progress = min(progress + 0.01, 1.0)
		var next_position = start_position.lerp(impact_position, next_progress)
		
		# Add arc to next position
		var next_arc_offset = sin(next_progress * PI) * arc_height
		next_position.y -= next_arc_offset
		
		# Calculate direction
		var direction = (next_position - arrow.global_position).normalized()
		
		# Update direction and rotation
		if direction.length() > 0.1:
			arrow.direction = direction
			arrow.rotation = direction.angle()
		
		# End condition
		if progress >= 1.0:
			arrow.global_position = impact_position
			set_physics_process(false)
	"""
	
	var processor = Node.new()
	processor.name = "CustomPhysicsProcessor"
	processor.set_script(custom_script)
	arrow.add_child(processor)
	
	# Disable original physics
	arrow.set_physics_process(false)

# Create a shadow marker
func create_shadow(position: Vector2, parent: Node) -> Node2D:
	var shadow = Node2D.new()
	shadow.name = "ImpactShadow"
	
	# Create shadow sprite
	var shadow_sprite = Sprite2D.new()
	
	# Create shadow image
	var img = Image.create(16, 16, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	
	# Draw circle
	for x in range(16):
		for y in range(16):
			var dx = (x - 8) / 8.0
			var dy = (y - 8) / 8.0
			var dist = sqrt(dx*dx + dy*dy)
			
			if dist <= 1.0:
				var alpha = 0.4 * (1.0 - dist)
				img.set_pixel(x, y, Color(0, 0, 0, alpha))
	
	# Create texture
	var texture = ImageTexture.create_from_image(img)
	shadow_sprite.texture = texture
	
	# Set size
	shadow_sprite.scale = Vector2(0.8, 0.5)
	
	# Add to shadow
	shadow.add_child(shadow_sprite)
	
	# Position shadow
	shadow.global_position = position
	
	# Set low z_index
	shadow.z_index = -10
	
	# Add to scene
	parent.add_child(shadow)
	
	# Create pulse animation
	var tween = parent.create_tween()
	tween.tween_property(shadow_sprite, "modulate:a", 0.8, 0.2)
	tween.tween_property(shadow_sprite, "modulate:a", 0.3, 0.2)
	tween.set_loops(10)
	
	# Store tween reference
	shadow.set_meta("tween", tween)
	
	return shadow

# Process arrow impact
func process_impact(arrow: Node, impact_position: Vector2, shadow: Node = null) -> void:
	# Find targets in area
	var space_state = arrow.get_world_2d().direct_space_state
	
	var query = PhysicsShapeQueryParameters2D.new()
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = 25.0  # Impact radius
	query.shape = circle_shape
	query.transform = Transform2D(0, impact_position)
	query.collision_mask = 2  # Enemy layer
	
	var results = space_state.intersect_shape(query)
	
	# Apply damage to enemies
	for result in results:
		var body = result.collider
		if body.is_in_group("enemies") and body.has_node("HealthComponent"):
			var health = body.get_node("HealthComponent")
			
			# Get damage package if available
			if arrow.has_method("get_damage_package"):
				var damage_package = arrow.get_damage_package()
				health.take_complex_damage(damage_package)
			else:
				# Fallback to basic damage
				health.take_damage(arrow.damage, arrow.is_crit)
	
	# Create visual effect
	create_impact_effect(impact_position, arrow.get_parent())
	
	# Process effects that trigger on hit
	process_on_hit_effects(arrow, impact_position)
	
	# Clean up shadow
	if shadow and is_instance_valid(shadow):
		if shadow.has_meta("tween"):
			var tween = shadow.get_meta("tween")
			if tween and is_instance_valid(tween):
				tween.kill()
		shadow.queue_free()
	
	# Destroy arrow
	if arrow and is_instance_valid(arrow):
		arrow.queue_free()

# Create visual impact effect
func create_impact_effect(position: Vector2, parent: Node) -> void:
	# Create container
	var effect = Node2D.new()
	effect.name = "ImpactEffect"
	effect.position = position
	
	# Add particles
	var particles = CPUParticles2D.new()
	effect.add_child(particles)
	
	# Configure particles
	particles.emitting = true
	particles.one_shot = true
	particles.explosiveness = 0.8
	particles.amount = 10
	particles.lifetime = 0.5
	particles.direction = Vector2(0, -1)
	particles.spread = 180.0
	particles.gravity = Vector2.ZERO
	particles.initial_velocity_min = 20
	particles.initial_velocity_max = 40
	particles.scale_amount_min = 1.0
	particles.scale_amount_max = 2.0
	particles.color = Color(0.9, 0.9, 0.9, 0.8)
	
	# Add to scene
	parent.add_child(effect)
	
	# Auto-destruct timer
	var timer = Timer.new()
	effect.add_child(timer)
	timer.wait_time = 1.0
	timer.one_shot = true
	timer.timeout.connect(func(): effect.queue_free())
	timer.start()

# Process effects that trigger on hit
func process_on_hit_effects(arrow: Node, position: Vector2) -> void:
	# Get effects metadata
	var has_explosion = arrow.has_meta("has_explosion_effect")
	var has_splinter = arrow.has_meta("has_splinter_effect")
	
	# Find a valid target for effects
	var target = find_nearest_enemy(position, 25.0)
	
	# Process explosion
	if has_explosion and target:
		create_explosion(arrow, target, position)
		
	# Process splinter
	if has_splinter and target:
		create_splinters(arrow, target, position)

# Create explosion effect
func create_explosion(arrow: Node, target: Node, position: Vector2) -> void:
	# Get explosion data
	var damage_percent = arrow.get_meta("explosion_damage_percent", 0.5)
	var radius = arrow.get_meta("explosion_radius", 30.0)
	
	# Calculate damage
	var explosion_damage = int(arrow.damage * damage_percent)
	
	# Apply damage in area
	apply_area_damage(position, explosion_damage, radius, arrow)
	
	# Visual effect
	create_explosion_effect(position, radius, arrow.get_parent())

# Create explosion visual effect
func create_explosion_effect(position: Vector2, radius: float, parent: Node) -> void:
	# Create container
	var explosion = Node2D.new()
	explosion.name = "Explosion"
	explosion.position = position
	parent.add_child(explosion)
	
	# Create visual with GDScript
	var visual = Node2D.new()
	explosion.add_child(visual)
	
	var script = GDScript.new()
	script.source_code = """
	extends Node2D
	
	var radius = 30.0
	var current_radius = 0.0
	var max_radius = 0.0
	var alpha = 1.0
	var color = Color(1.0, 0.5, 0.1, 1.0)
	
	func _ready():
		max_radius = radius
	
	func _process(delta):
		if current_radius < max_radius:
			current_radius += max_radius * 5 * delta
		else:
			alpha -= delta * 2
			
		if alpha <= 0:
			queue_free()
			
		queue_redraw()
	
	func _draw():
		if alpha > 0:
			draw_circle(Vector2.ZERO, current_radius, Color(color.r, color.g, color.b, alpha * 0.3))
			var inner_radius = max(0, current_radius * 0.7)
			draw_circle(Vector2.ZERO, inner_radius, Color(1.0, 0.8, 0.0, alpha * 0.7))
	"""
	
	visual.set_script(script)
	visual.set("radius", radius)
	
	# Auto-destroy timer
	var timer = Timer.new()
	explosion.add_child(timer)
	timer.wait_time = 1.0
	timer.one_shot = true
	timer.timeout.connect(func(): explosion.queue_free())
	timer.start()

# Apply damage in an area
func apply_area_damage(position: Vector2, damage: int, radius: float, source: Node) -> void:
	# Find enemies in area
	var space_state = source.get_world_2d().direct_space_state
	
	var query = PhysicsShapeQueryParameters2D.new()
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = radius
	query.shape = circle_shape
	query.transform = Transform2D(0, position)
	query.collision_mask = 2  # Enemy layer
	
	var results = space_state.intersect_shape(query)
	
	# Apply damage to each enemy
	for result in results:
		var body = result.collider
		if body.is_in_group("enemies") and body.has_node("HealthComponent"):
			var health = body.get_node("HealthComponent")
			
			# Try to construct damage package
			if source.has_node("DmgCalculatorComponent"):
				var dmg_calc = source.get_node("DmgCalculatorComponent")
				var is_crit = source.is_crit if "is_crit" in source else false
				
				var damage_package = {
					"physical_damage": damage,
					"is_critical": is_crit
				}
				
				# Add elemental damage if any
				if "elemental_damage" in dmg_calc:
					damage_package["elemental_damage"] = {}
					for element in dmg_calc.elemental_damage:
						damage_package["elemental_damage"][element] = int(dmg_calc.elemental_damage[element] * 0.5)
				
				health.take_complex_damage(damage_package)
			else:
				# Fallback to simple damage
				health.take_damage(damage, false, "explosion")

# Create splinter effects
func create_splinters(arrow: Node, target: Node, position: Vector2) -> void:
	# Get splinter data
	var count = arrow.get_meta("splinter_count", 2)
	var damage_percent = arrow.get_meta("splinter_damage_percent", 0.25)
	var range_value = arrow.get_meta("splinter_range", 100.0)
	
	# Calculate splinter damage
	var splinter_damage = int(arrow.damage * damage_percent)
	
	# Find nearby targets
	var nearby_targets = find_nearby_enemies(position, range_value, [target])
	
	# Limit to available targets or max count
	var actual_count = min(count, nearby_targets.size())
	
	# Create splinters
	for i in range(actual_count):
		if i < nearby_targets.size():
			var enemy = nearby_targets[i]
			create_splinter_effect(position, enemy.global_position, splinter_damage, arrow)

# Create a visual splinter effect
func create_splinter_effect(from_pos: Vector2, to_pos: Vector2, damage: int, source: Node) -> void:
	# Get parent
	var parent = source.get_parent()
	
	# Create visual effect
	var splinter = Line2D.new()
	splinter.name = "SplinterEffect"
	splinter.points = [Vector2.ZERO, to_pos - from_pos]
	splinter.width = 2.0
	splinter.default_color = Color(1.0, 0.8, 0.2, 0.8)
	splinter.position = from_pos
	
	parent.add_child(splinter)
	
	# Fade animation
	var tween = splinter.create_tween()
	tween.tween_property(splinter, "modulate", Color(1, 1, 1, 0), 0.3)
	tween.tween_callback(splinter.queue_free)
	
	# Find target at position
	var target = find_nearest_enemy(to_pos, 20.0)
	if target and target.has_node("HealthComponent"):
		var health = target.get_node("HealthComponent")
		
		# Apply damage
		if source.has_node("DmgCalculatorComponent"):
			var dmg_calc = source.get_node("DmgCalculatorComponent")
			var is_crit = source.is_crit if "is_crit" in source else false
			
			var damage_package = {
				"physical_damage": damage,
				"is_critical": is_crit
			}
			
			# Add elemental damage if any (reduced)
			if "elemental_damage" in dmg_calc:
				damage_package["elemental_damage"] = {}
				# Use 0.25 as the default reduction for splinters if not specified
				var damage_reduction = source.get_meta("splinter_damage_percent", 0.25)
				for element in dmg_calc.elemental_damage:
					damage_package["elemental_damage"][element] = int(dmg_calc.elemental_damage[element] * damage_reduction)
			
			health.take_complex_damage(damage_package)
		else:
			# Fallback to simple damage
			health.take_damage(damage, false, "splinter")

# Find the nearest enemy to a position
func find_nearest_enemy(position: Vector2, max_distance: float) -> Node:
	var space_state = get_tree().get_root().get_world_2d().direct_space_state
	
	var query = PhysicsShapeQueryParameters2D.new()
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = max_distance
	query.shape = circle_shape
	query.transform = Transform2D(0, position)
	query.collision_mask = 2  # Enemy layer
	
	var results = space_state.intersect_shape(query)
	
	var closest_enemy = null
	var closest_dist = INF
	
	for result in results:
		var body = result.collider
		if body.is_in_group("enemies"):
			var dist = body.global_position.distance_to(position)
			if dist < closest_dist:
				closest_dist = dist
				closest_enemy = body
	
	return closest_enemy

# Find nearby enemies excluding a list
func find_nearby_enemies(position: Vector2, range_value: float, exclude: Array = []) -> Array:
	var space_state = get_tree().get_root().get_world_2d().direct_space_state
	
	var query = PhysicsShapeQueryParameters2D.new()
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = range_value
	query.shape = circle_shape
	query.transform = Transform2D(0, position)
	query.collision_mask = 2  # Enemy layer
	
	var results = space_state.intersect_shape(query)
	
	var enemies = []
	
	for result in results:
		var body = result.collider
		if body.is_in_group("enemies") and not body in exclude:
			enemies.append(body)
	
	# Sort by distance
	enemies.sort_custom(func(a, b): 
		return a.global_position.distance_to(position) < b.global_position.distance_to(position)
	)
	
	return enemies

# Helper function to convert degrees to radians
func deg_to_rad(degrees: float) -> float:
	return degrees * (PI / 180.0)
