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
	# Add the missing piercing_count property
	var piercing_count: int = 0
	# Efeitos de dano elemental
	var fire_damage_percent: float = 0.0
	var fire_dot_damage_percent: float = 0.0
	var fire_dot_duration: float = 0.0
	var fire_dot_interval: float = 0.0
	var fire_dot_chance: float = 0.0
	
	# Chain Shot properties
	var can_chain: bool = false
	var chain_chance: float = 0.0
	var chain_range: float = 0.0
	var chain_damage_decay: float = 0.0
	var max_chains: int = 0
	
	# Efeitos de múltiplos projéteis
	var double_shot_enabled: bool = false
	var double_shot_angle: float = 0.0
	var second_arrow_damage_modifier: float = 1.0
	
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

	var pressure_wave_enabled: bool = false
	var knockback_force: float = 0.0
	var slow_percent: float = 0.0
	var slow_duration: float = 0.0
	var arrow_rain_area_multiplier: float = 1.0
	var wave_visual_enabled: bool = false
	var ground_duration: float = 3.0  # Add this new property

	# Creates a copy of this CompiledEffects instance
	func copy() -> CompiledEffects:
		var new_effects = CompiledEffects.new()
		
		# Basic stats
		new_effects.damage_multiplier = self.damage_multiplier
		new_effects.crit_chance_bonus = self.crit_chance_bonus
		new_effects.crit_damage_multiplier = self.crit_damage_multiplier
		new_effects.armor_penetration = self.armor_penetration
		new_effects.range_multiplier = self.range_multiplier
		new_effects.attack_speed_multiplier = self.attack_speed_multiplier
		
		new_effects.pressure_wave_enabled = self.pressure_wave_enabled
		new_effects.knockback_force = self.knockback_force
		new_effects.slow_percent = self.slow_percent
		new_effects.slow_duration = self.slow_duration
		new_effects.arrow_rain_area_multiplier = self.arrow_rain_area_multiplier
		new_effects.wave_visual_enabled = self.wave_visual_enabled
		new_effects.ground_duration = self.ground_duration  # Copy the new property
		
		# Elemental effects
		new_effects.fire_damage_percent = self.fire_damage_percent
		new_effects.fire_dot_damage_percent = self.fire_dot_damage_percent
		new_effects.fire_dot_duration = self.fire_dot_duration
		new_effects.fire_dot_interval = self.fire_dot_interval
		new_effects.fire_dot_chance = self.fire_dot_chance
		
		# Projectile effects
		new_effects.piercing_count = self.piercing_count
		new_effects.can_chain = self.can_chain
		new_effects.chain_chance = self.chain_chance
		new_effects.chain_range = self.chain_range
		new_effects.chain_damage_decay = self.chain_damage_decay
		new_effects.max_chains = self.max_chains
		
		# Multi-projectile effects
		new_effects.double_shot_enabled = self.double_shot_enabled
		new_effects.double_shot_angle = self.double_shot_angle
		new_effects.second_arrow_damage_modifier = self.second_arrow_damage_modifier
		
		# Arrow rain effects
		new_effects.arrow_rain_enabled = self.arrow_rain_enabled
		new_effects.arrow_rain_count = self.arrow_rain_count
		new_effects.arrow_rain_damage_percent = self.arrow_rain_damage_percent
		new_effects.arrow_rain_radius = self.arrow_rain_radius
		new_effects.arrow_rain_interval = self.arrow_rain_interval
		
		# Special hit effects
		new_effects.focused_shot_enabled = self.focused_shot_enabled
		new_effects.focused_shot_bonus = self.focused_shot_bonus
		new_effects.focused_shot_threshold = self.focused_shot_threshold
		
		new_effects.mark_enabled = self.mark_enabled
		new_effects.mark_duration = self.mark_duration
		new_effects.mark_crit_bonus = self.mark_crit_bonus
		
		new_effects.bleed_on_crit = self.bleed_on_crit
		new_effects.bleed_damage_percent = self.bleed_damage_percent
		new_effects.bleed_duration = self.bleed_duration
		new_effects.bleed_interval = self.bleed_interval
		
		new_effects.can_splinter = self.can_splinter
		new_effects.splinter_count = self.splinter_count
		new_effects.splinter_damage_percent = self.splinter_damage_percent
		new_effects.splinter_range = self.splinter_range
		
		new_effects.explosion_enabled = self.explosion_enabled
		new_effects.explosion_damage_percent = self.explosion_damage_percent
		new_effects.explosion_radius = self.explosion_radius
		
		# Bloodseeker effect
		new_effects.bloodseeker_enabled = self.bloodseeker_enabled
		new_effects.bloodseeker_bonus_per_stack = self.bloodseeker_bonus_per_stack
		new_effects.bloodseeker_max_stacks = self.bloodseeker_max_stacks
		
		# Add any other properties here as they are added to the class
	
		return new_effects
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
	for strategy in archer.attack_upgrades:
		if strategy:
			var strategy_name = strategy.get_script().get_path().get_file().get_basename()
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
	# Extract the talent number using regex
	var regex = RegEx.new()
	regex.compile("Talent_(\\d+)\\.gd")
	var result = regex.search(file_name)
	
	if result:
		var talent_id = int(result.get_string(1))
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
				# Safely access properties using proper property names
				var fire_damage_percent = strategy.get("fire_damage_percent")
				var dot_percent_per_tick = strategy.get("dot_percent_per_tick")
				var dot_duration = strategy.get("dot_duration")
				var dot_interval = strategy.get("dot_interval")
				var dot_chance = strategy.get("dot_chance")  # Default 30% chance
				# Apply fire damage effect
				effects.fire_damage_percent = fire_damage_percent
				# Apply fire DoT effect
				effects.fire_dot_damage_percent = dot_percent_per_tick
				effects.fire_dot_duration = dot_duration
				effects.fire_dot_interval = dot_interval
				effects.fire_dot_chance = dot_chance

			11:  # Double Shot
				
				# Get angle spread parameter
				var angle_spread = strategy.get("angle_spread")
				if angle_spread != null:
					effects.double_shot_enabled = true
					effects.double_shot_angle = angle_spread
					
				# Get damage modifier for second arrow if specified
				var damage_mod = strategy.get("second_arrow_damage_modifier")
				if damage_mod != null:
					effects.second_arrow_damage_modifier = damage_mod
				
					
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
					effects.arrow_rain_damage_percent = damage_per_arrow
					effects.arrow_rain_radius = radius
					effects.arrow_rain_interval = attacks_threshold
					
			14:  # Arrow Storm - melhoria para o Arrow Rain com novo efeito de onda de pressão
				# Obtém os parâmetros da estratégia
				var knockback_force = strategy.get("knockback_force")
				var slow_percent = strategy.get("slow_percent")
				var slow_duration = strategy.get("slow_duration")
				var area_multiplier = strategy.get("area_multiplier")
				var wave_visual = strategy.get("wave_visual_enabled")
				var ground_duration = strategy.get("ground_duration")
				
				effects.pressure_wave_enabled = true
				if knockback_force != null:
					effects.knockback_force = knockback_force
				if slow_percent != null:
					effects.slow_percent = slow_percent
				if slow_duration != null:
					effects.slow_duration = slow_duration
				if area_multiplier != null:
					effects.arrow_rain_area_multiplier = area_multiplier
				if wave_visual != null:
					effects.wave_visual_enabled = wave_visual
				if ground_duration != null:
					effects.ground_duration = ground_duration
					
			15:  # Arrow Explosion
				var damage_percent = strategy.get("explosion_damage_percent")
				var radius = strategy.get("explosion_radius")
				
				if damage_percent != null and radius != null:
					effects.explosion_enabled = true
					effects.explosion_damage_percent = damage_percent
					effects.explosion_radius = radius
					
			16:  # Serrated Arrows (Bleeding)
				
					# Use the correct property names from your Talent_16 class
				var bleed_damage = strategy.bleeding_damage_percent
				var bleed_duration = strategy.bleeding_duration
				var bleed_interval = strategy.dot_interval  # This should match the property name in Talent_16
	
				# Configure bleeding effect with the retrieved values
				effects.bleed_on_crit = true
				effects.bleed_damage_percent = bleed_damage
				effects.bleed_duration = bleed_duration
				effects.bleed_interval = bleed_interval
					
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
	# Apply basic stats with proper logging
	if "damage" in projectile:
		var original_damage = projectile.damage
		# Apply damage multiplier properly
		projectile.damage = int(original_damage * effects.damage_multiplier)
	
	if "crit_chance" in projectile:
		var original_crit = projectile.crit_chance
		projectile.crit_chance = min(projectile.crit_chance + effects.crit_chance_bonus, 1.0)
	
	# CRITICAL: Update the DmgCalculator component
	if projectile.has_node("DmgCalculatorComponent"):
		var dmg_calc = projectile.get_node("DmgCalculatorComponent")
		if dmg_calc.has_meta("fire_dot_data"):
			var dot_data = dmg_calc.get_meta("fire_dot_data")
		# Apply damage multiplier to base_damage
		if "base_damage" in dmg_calc:
			var original_base = dmg_calc.base_damage
			dmg_calc.base_damage = int(original_base * effects.damage_multiplier)
		
		# Also set the damage_multiplier properly
		if "damage_multiplier" in dmg_calc:
			var original_mult = dmg_calc.damage_multiplier
			dmg_calc.damage_multiplier = effects.damage_multiplier
		
		# Apply armor penetration
		if effects.armor_penetration > 0:
			dmg_calc.armor_penetration = effects.armor_penetration
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
		projectile.piercing = true
		projectile.set_meta("piercing_count", effects.piercing_count)
		projectile.add_tag("piercing")
		
		# Para projéteis físicos, desabilita colisão com inimigos
		if projectile is CharacterBody2D:
			projectile.set_collision_mask_value(2, false)  # Layer 2 = enemy layer
			
	# Apply Double Shot 
	if effects.double_shot_enabled:
		projectile.set_meta("double_shot_enabled", true)
		projectile.set_meta("double_shot_angle", effects.double_shot_angle)
		projectile.set_meta("second_arrow_damage_modifier", effects.second_arrow_damage_modifier)
		projectile.add_tag("double_shot")
		
		# Apply Chain Shot
	if effects.can_chain:
		_setup_chain_shot(projectile, effects)
	
	# Apply Focused Shot
	if effects.focused_shot_enabled:
		# Adiciona tag e meta para identificação
		projectile.add_tag("focused_shot")
		# Configurações do Focused Shot
		projectile.set_meta("focused_shot_enabled", true)
		projectile.set_meta("focused_shot_bonus", effects.focused_shot_bonus)
		projectile.set_meta("focused_shot_threshold", effects.focused_shot_threshold)
		
	if effects.bleed_on_crit:
		# Force the metadata directly on the projectile
		projectile.set_meta("has_bleeding_effect", true)
		projectile.set_meta("bleeding_damage_percent", effects.bleed_damage_percent)
		projectile.set_meta("bleeding_duration", effects.bleed_duration)
		projectile.set_meta("bleeding_interval", effects.bleed_interval)
		# Add tag
		projectile.add_tag("bleeding")
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
	
	# Apply Splinter
	if effects.can_splinter:
		projectile.set_meta("has_splinter_effect", true)
		projectile.set_meta("splinter_count", effects.splinter_count)
		projectile.set_meta("splinter_damage_percent", effects.splinter_damage_percent)
		projectile.set_meta("splinter_range", effects.splinter_range)
		projectile.add_tag("splinter")
	
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
				
				if projectile.has_node("DmgCalculatorComponent"):
					var dmg_calc = projectile.get_node("DmgCalculatorComponent")
					if "damage_multiplier" in dmg_calc:
						dmg_calc.damage_multiplier *= (1 + bonus)
						
	# Augment Arrow Rain radius
	if projectile.has_meta("arrow_rain_radius") and effects.arrow_rain_area_multiplier > 1.0:
		var current_radius = projectile.get_meta("arrow_rain_radius")
		projectile.set_meta("arrow_rain_radius", current_radius * effects.arrow_rain_area_multiplier)

	if effects.pressure_wave_enabled and (projectile.has_meta("arrow_rain_enabled") or projectile.has_meta("is_rain_arrow")):
		projectile.set_meta("pressure_wave_enabled", true)
		projectile.set_meta("knockback_force", effects.knockback_force)
		projectile.set_meta("slow_percent", effects.slow_percent)
		projectile.set_meta("slow_duration", effects.slow_duration)
		projectile.set_meta("wave_visual_enabled", effects.wave_visual_enabled)
		projectile.set_meta("ground_duration", effects.ground_duration)  # Set the new property
		projectile.add_tag("pressure_wave")
		
		# Augment Arrow Rain radius
		if projectile.has_meta("arrow_rain_radius") and effects.arrow_rain_area_multiplier > 1.0:
			var current_radius = projectile.get_meta("arrow_rain_radius")
			projectile.set_meta("arrow_rain_radius", current_radius * effects.arrow_rain_area_multiplier)
		
func _setup_chain_shot(projectile, effects: CompiledEffects) -> void:
	# Skip setup if this projectile shouldn't use chain shot
	if projectile.has_meta("no_chain_shot") or projectile.has_meta("is_rain_arrow"):
		return
		
	if projectile is NewArrow:
		# Enable chain shot with proper settings
		projectile.chain_shot_enabled = true
		projectile.chain_chance = effects.chain_chance
		projectile.chain_range = effects.chain_range
		projectile.chain_damage_decay = effects.chain_damage_decay
		projectile.max_chains = effects.max_chains
		projectile.current_chains = 0
		
		# Ensure hit_targets is initialized properly
		if projectile.hit_targets == null:
			projectile.hit_targets = []
		else:
			projectile.hit_targets.clear()
		
		# Initial state for chain shot
		projectile.will_chain = false
		projectile.chain_calculated = false
		projectile.is_processing_ricochet = false
		
		# Add detailed metadata for debugging
		projectile.set_meta("chain_shot_setup", {
			"timestamp": Time.get_ticks_msec(),
			"max_chains": effects.max_chains,
			"chain_chance": effects.chain_chance
		})
		
		# Add tag for identification
		projectile.add_tag("chain_shot")
	else:
		# For non-Arrow projectiles, use metadata
		projectile.set_meta("chain_shot_enabled", true)
		projectile.set_meta("chain_chance", effects.chain_chance)
		projectile.set_meta("chain_range", effects.chain_range)
		projectile.set_meta("chain_damage_decay", effects.chain_damage_decay)
		projectile.set_meta("max_chains", effects.max_chains)
		projectile.set_meta("current_chains", 0)
		projectile.set_meta("will_chain", null)  # Not yet determined
		projectile.set_meta("hit_targets", [])
		
		# Add tag for identification
		if projectile.has_method("add_tag"):
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
				
# Place this function in the ConsolidatedTalentSystem class
func spawn_double_shot(original_projectile: Node, effects: CompiledEffects) -> void:
	if not effects.double_shot_enabled:
		return
		
	var shooter = original_projectile.shooter
	if not shooter or not is_instance_valid(shooter):
		return
		
	# CRITICAL: Create a new arrow from scratch every time
	# This completely avoids parent conflicts by never reusing arrow instances
	var arrow_scene = load("res://Test/Projectiles/Archer/Arrow.tscn")
	if not arrow_scene:
		return
		
	var second_arrow = arrow_scene.instantiate()
	
	# Get the exact position and direction from the original
	var direction = original_projectile.direction
	var start_position = original_projectile.global_position
	
	# Calculate offset direction
	var angle_offset = deg_to_rad(-effects.double_shot_angle)  # Negative for opposite direction
	var rotated_direction = direction.rotated(angle_offset)
	
	# Configure arrow
	second_arrow.global_position = start_position
	second_arrow.direction = rotated_direction
	second_arrow.rotation = rotated_direction.angle()
	second_arrow.shooter = shooter
	second_arrow.initial_position = start_position  # Important for distance calculation
	
	# Mark as pooled but avoid actual pooling for double shot arrows
	second_arrow.set_meta("pooled", true)
	second_arrow.set_meta("is_second_arrow", true)
	second_arrow.set_meta("no_double_shot", true)  # Prevent cascading double shots
	second_arrow.set_meta("disposable", true)  # Mark to be destroyed rather than pooled
	
	# Set basic properties
	second_arrow.damage = original_projectile.damage
	if "is_crit" in original_projectile and "is_crit" in second_arrow:
		second_arrow.is_crit = original_projectile.is_crit
	if "crit_chance" in original_projectile and "crit_chance" in second_arrow:
		second_arrow.crit_chance = original_projectile.crit_chance
	
	# Temporarily disable double shot for this arrow
	var original_double_shot_value = effects.double_shot_enabled
	effects.double_shot_enabled = false
	
	# Apply all the talent effects
	apply_compiled_effects(second_arrow, effects)
	
	# Restore double shot setting
	effects.double_shot_enabled = original_double_shot_value
	
	# Copy relevant DmgCalculator settings with damage modifier applied
	if original_projectile.has_node("DmgCalculatorComponent") and second_arrow.has_node("DmgCalculatorComponent"):
		var original_calc = original_projectile.get_node("DmgCalculatorComponent")
		var second_calc = second_arrow.get_node("DmgCalculatorComponent")
		
		# Set damage with modifier
		second_calc.base_damage = int(original_calc.base_damage * effects.second_arrow_damage_modifier)
		second_arrow.damage = int(original_projectile.damage * effects.second_arrow_damage_modifier)
		
		# Copy other relevant attributes
		second_calc.damage_multiplier = original_calc.damage_multiplier
		second_calc.weapon_damage = original_calc.weapon_damage
		second_calc.main_stat = original_calc.main_stat
		second_calc.main_stat_multiplier = original_calc.main_stat_multiplier
		second_calc.armor_penetration = original_calc.armor_penetration
		
		# Copy elemental effects
		if "elemental_damage" in original_calc:
			second_calc.elemental_damage = original_calc.elemental_damage.duplicate()
		
		# Copy DoT effects
		if "dot_effects" in original_calc:
			second_calc.dot_effects = []
			for dot in original_calc.dot_effects:
				second_calc.dot_effects.append(dot.duplicate())
	
	# Copy any tags
	if "tags" in original_projectile and "tags" in second_arrow:
		second_arrow.tags = original_projectile.tags.duplicate()
		# Add special tag for tracking
		second_arrow.add_tag("double_shot_arrow")
	
	# Add to scene
	if shooter and shooter.get_parent():
		shooter.get_parent().add_child(second_arrow)
	else:
		print("ERROR: Invalid shooter parent for second arrow")
		second_arrow.queue_free()
		
# Helper method to safely reset the lifetime timer
func _reset_secondary_arrow_timer(arrow: Node) -> void:
	# Make sure arrow is valid and in the tree
	if not arrow or not is_instance_valid(arrow) or not arrow.is_inside_tree():
		return
	# Find and reset the lifetime timer
	var found_timer = false
	for child in arrow.get_children():
		if child is Timer and child.has_signal("timeout") and arrow.has_method("_on_lifetime_expired"):
			if child.timeout.is_connected(arrow._on_lifetime_expired):
				child.stop()
				child.start()
				found_timer = true
				break
	# If we didn't find a connected timer, look for any likely lifetime timer
	if not found_timer:
		for child in arrow.get_children():
			if child is Timer and child.one_shot and child.wait_time > 1.0:
				child.stop()
				child.start()
 
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

func spawn_arrow_rain(current_projectile: Node, effects: CompiledEffects) -> void:
	var shooter = current_projectile.shooter
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
		# If no target, use a position in front of the shooter
		target_position = current_projectile.global_position + current_projectile.direction * 300
	
	# IMPORTANT: Save bleeding effect metadata from original projectile
	var has_bleeding = current_projectile.has_meta("has_bleeding_effect")
	var bleeding_data = {}
	
	if has_bleeding:
		bleeding_data = {
			"has_bleeding_effect": true,
			"bleeding_damage_percent": current_projectile.get_meta("bleeding_damage_percent", 0.3),
			"bleeding_duration": current_projectile.get_meta("bleeding_duration", 4.0),
			"bleeding_interval": current_projectile.get_meta("bleeding_interval", 0.5)
		}
	
	# Calculate fall positions using smart targeting
	var fall_positions = _get_smart_fall_positions(target_position, effects, shooter, effects.arrow_rain_count)
	
	# Generate a unique batch ID for this spawn_arrow_rain call
	var batch_id = str(Time.get_ticks_msec()) + "_" + str(randi() % 1000)
	
	# Count how many valid arrows we process
	var success_count = 0
	
	# Spawn rain arrows
	for i in range(effects.arrow_rain_count):
		var arrow = null
		
		# Try to get from pool first
		if ProjectilePool and ProjectilePool.instance:
			arrow = ProjectilePool.instance.get_arrow_for_archer(shooter)
			
			# Ensure the pooled arrow has a clean state
			if arrow and arrow.is_pooled():
				# Force reinitialization of pooled arrow - LIMPA COMPLETAMENTE
				if arrow.has_method("reset_for_reuse"):
					arrow.reset_for_reuse()
					
					# ADICIONADO: Garante que qualquer processador existente seja removido
					for child in arrow.get_children():
						if child.get_class() == "RainArrowProcessor" or (child.get_script() and "RainArrowProcessor" in child.get_script().get_path()):
							child.queue_free()
							
					# ADICIONADO: Remove qualquer metadado de processador existente
					if arrow.has_meta("active_rain_processor_id"):
						arrow.remove_meta("active_rain_processor_id")
		
		# Fallback to instantiation if pool failed
		if not arrow:
			var arrow_scene = load("res://Test/Projectiles/Archer/Arrow.tscn")
			if not arrow_scene:
				continue
			arrow = arrow_scene.instantiate()
		
		# Make sure we have a valid arrow
		if not arrow:
			continue
		
		# Get the specific fall position for this arrow
		var fall_position = fall_positions[i]
		
		# Basic configuration
		arrow.damage = int(current_projectile.damage * effects.arrow_rain_damage_percent)
		arrow.shooter = shooter
		arrow.speed = 500.0  # Arrow flight speed
		
		# Initial position set to shooter
		arrow.global_position = shooter.global_position
		
		# Ensure critical hit status is independent
		if "is_crit" in current_projectile and "is_crit" in arrow:
			if "crit_chance" in current_projectile:
				arrow.crit_chance = current_projectile.crit_chance
				arrow.is_crit = arrow.is_critical_hit(arrow.crit_chance)
			else:
				arrow.is_crit = randf() < 0.1  # Default 10% chance
		
		# Apply bleeding effect if original had it
		if has_bleeding:
			arrow.set_meta("has_bleeding_effect", bleeding_data.has_bleeding_effect)
			arrow.set_meta("bleeding_damage_percent", bleeding_data.bleeding_damage_percent)
			arrow.set_meta("bleeding_duration", bleeding_data.bleeding_duration)
			arrow.set_meta("bleeding_interval", bleeding_data.bleeding_interval)
			
			# Add bleeding tag
			if arrow.has_method("add_tag"):
				arrow.add_tag("bleeding")
		
		# Add rain tag to distinguish from normal arrows
		if arrow.has_method("add_tag"):
			arrow.add_tag("rain_arrow")
		else:
			arrow.tags = ["rain_arrow"]
			arrow.add_tag = func(tag_name: String) -> void:
				if not tag_name in arrow.tags:
					arrow.tags.append(tag_name)
		
		# Disable features that shouldn't trigger for rain arrows
		arrow.set_meta("is_rain_arrow", true)
		arrow.set_meta("no_double_shot", true)
		arrow.set_meta("no_chain_shot", true)
		
		# Configure rain arrow specifics with unique timestamps to avoid collisions
		arrow.set_meta("rain_start_pos", shooter.global_position)
		arrow.set_meta("rain_target_pos", fall_position)
		arrow.set_meta("rain_arc_height", randf_range(200, 300))
		arrow.set_meta("rain_time", 1.0 + (i * 0.05))  # Slight variation in timing
		
		# Create a modified copy of effects with disabled problematic abilities
		var rain_effects = effects.copy()
		rain_effects.double_shot_enabled = false
		rain_effects.can_chain = false
		
		# Apply the modified effects
		apply_compiled_effects(arrow, rain_effects)
		
		# Add to the scene
		if not arrow.get_parent():
			shooter.get_parent().add_child(arrow)
		
		# MUDANÇA CRUCIAL: Criar o processador diretamente, sem deferred call
		var processor = RainArrowProcessor.new()
		processor.name = "RainArrowProcessor"
		arrow.add_child(processor)
		
		# Track successful arrow creation
		success_count += 1
	
	print("Created ", success_count, " rain arrows, all with processors attached")

# Helper method to safely apply effects with proper timing
func _delayed_apply_effects(arrow: Node, effects: CompiledEffects) -> void:
	if not arrow or not is_instance_valid(arrow):
		return
		
	# Apply effects to the arrow
	apply_compiled_effects(arrow, effects)
	
	# Use a small timer instead of await physics_frame
	var timer = Timer.new()
	timer.wait_time = 0.05  # Short delay
	timer.one_shot = true
	timer.autostart = true
	
	# Add the timer to arrow and connect its timeout signal
	arrow.add_child(timer)
	timer.timeout.connect(func():
		# Cleanup the timer itself
		timer.queue_free()
		
		# Verify arrow is still valid
		if not is_instance_valid(arrow):
			return
			
		# Only add the processor if the arrow doesn't already have one
		if not arrow.has_meta("active_rain_processor_id"):
			# Create rain arrow processor after all other processing
			var processor = RainArrowProcessor.new()
			processor.name = "RainArrowProcessor"
			arrow.add_child(processor)
		else:
			print("WARNING: Arrow already has a processor, skipping processor creation")
	)

func setup_rain_arrow_trajectory(arrow: Node, impact_position: Vector2, parent_node: Node) -> void:
	# Disable standard physics and collisions initially
	arrow.set_physics_process(false)
	
	if arrow.has_node("Hurtbox"):
		var hurtbox = arrow.get_node("Hurtbox")
		hurtbox.set_deferred("monitoring", false)
		hurtbox.set_deferred("monitorable", false)
	
	# Calculate flight time
	var distance = arrow.global_position.distance_to(impact_position)
	var flight_time = distance / arrow.speed
	
	# Store parameters as metadata
	arrow.set_meta("rain_start_pos", arrow.global_position)
	arrow.set_meta("rain_target_pos", impact_position)
	arrow.set_meta("rain_time", flight_time)
	
	# Add the processor
	var processor = RainArrowProcessor.new()
	processor.name = "RainArrowProcessor"
	arrow.add_child(processor)
	
	# Add safety cleanup timer
	var safety_timer = Timer.new()
	safety_timer.name = "SafetyCleanupTimer"
	safety_timer.one_shot = true
	safety_timer.wait_time = flight_time + 2.0  # Extra time for safety
	arrow.add_child(safety_timer)
	
	# Store references for cleanup using weak references
	var arrow_ref = weakref(arrow)
	
	safety_timer.timeout.connect(func():
		var arrow_inst = arrow_ref.get_ref()
		if arrow_inst and is_instance_valid(arrow_inst):
			if ProjectilePool and ProjectilePool.instance and arrow_inst.is_pooled():
				ProjectilePool.instance.return_arrow_to_pool(arrow_inst)
			else:
				arrow_inst.queue_free()
	)
	safety_timer.start()


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

# Encontra inimigos na área para direcionamento inteligente
func _find_enemies_in_area(center: Vector2, search_radius: float, shooter) -> Array:
	var enemies = []
	
	# Verifica se o mundo 2D está disponível
	if not shooter or not is_instance_valid(shooter):
		return enemies
	
	var space_state = shooter.get_world_2d().direct_space_state
	
	# Configura a query de física
	var query = PhysicsShapeQueryParameters2D.new()
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = search_radius * 1.5  # Raio aumentado para encontrar mais inimigos
	query.shape = circle_shape
	query.transform = Transform2D(0, center)
	query.collision_mask = 2  # Layer de inimigos
	
	# Executa a query
	var results = space_state.intersect_shape(query)
	
	# Filtra e classifica os resultados
	for result in results:
		var body = result.collider
		if (body.is_in_group("enemies") or body.get_collision_layer_value(2)) and body.has_node("HealthComponent"):
			enemies.append(body)
	
	# Ordena por distância ao centro
	enemies.sort_custom(func(a, b): 
		return a.global_position.distance_to(center) < b.global_position.distance_to(center)
	)
	
	return enemies

# Na função spawn_arrow_rain, substitua o cálculo de fall_position por:
func _get_smart_fall_positions(target_position: Vector2, effects, shooter, arrow_count: int) -> Array:
	var fall_positions = []
	
	# Raio de busca expansivo - quanto mais flechas, maior a área de busca
	var search_radius = effects.arrow_rain_radius * (1.0 + (arrow_count * 0.05))
	
	# Encontra inimigos na área para priorizar
	var enemies_in_area = _find_enemies_in_area(target_position, search_radius, shooter)
	
	# Estratégia baseada no número de inimigos encontrados
	if enemies_in_area.size() == 0:
		# Sem inimigos: padrão de área padrão deslocado para trás
		for i in range(arrow_count):
			var angle = randf() * TAU
			var rand_radius = sqrt(randf()) * effects.arrow_rain_radius * 1.2
			var random_offset = Vector2(cos(angle) * rand_radius, sin(angle) * rand_radius)
			var back_offset = Vector2(0, -effects.arrow_rain_radius * 0.4)
			fall_positions.append(target_position + random_offset + back_offset)
	
	elif enemies_in_area.size() <= 2:
		# Poucos inimigos: foco maior nos inimigos com algumas flechas de cobertura
		# 70% das flechas nos inimigos, 30% em cobertura de área
		var enemy_focus_count = int(arrow_count * 0.7)
		var area_count = arrow_count - enemy_focus_count
		
		# Direciona flechas para os inimigos, com ligeira distribuição
		for i in range(enemy_focus_count):
			var enemy_idx = i % enemies_in_area.size()
			var enemy_pos = enemies_in_area[enemy_idx].global_position
			
			# Pequena variação ao redor do inimigo para aumentar chance de acerto
			var variation = Vector2(
				randf_range(-15, 15),
				randf_range(-15, 15)
			)
			
			# Adiciona posição para o inimigo com pequena variação
			fall_positions.append(enemy_pos + variation)
			
			# Adiciona posições extras atrás do inimigo (zona de movimento provável)
			if i < enemy_focus_count / 2:
				var behind_offset = (enemy_pos - target_position).normalized() * 30
				fall_positions.append(enemy_pos + behind_offset + variation)
		
		# Adiciona flechas de cobertura de área
		for i in range(area_count):
			var angle = randf() * TAU
			var rand_radius = sqrt(randf()) * effects.arrow_rain_radius * 1.5
			var random_offset = Vector2(cos(angle) * rand_radius, sin(angle) * rand_radius)
			fall_positions.append(target_position + random_offset)
			
	else:
		# Múltiplos inimigos: distribuição inteligente
		# 50% dos inimigos, 30% em agrupamentos, 20% cobertura
		
		# Direciona flechas para inimigos individuais
		var enemies_to_target = min(enemies_in_area.size(), int(arrow_count * 0.5))
		for i in range(enemies_to_target):
			var enemy_pos = enemies_in_area[i].global_position
			
			# Pequena variação para aumentar chance de acerto
			var variation = Vector2(
				randf_range(-20, 20),
				randf_range(-20, 20)
			)
			
			fall_positions.append(enemy_pos + variation)
		
		# Identifica clusters de inimigos para cobertura de área
		var cluster_centers = _find_enemy_clusters(enemies_in_area)
		var cluster_count = min(cluster_centers.size(), int(arrow_count * 0.3))
		
		for i in range(cluster_count):
			if i < cluster_centers.size():
				fall_positions.append(cluster_centers[i])
		
		# Flechas restantes distribuídas em padrão de cobertura
		var remaining = arrow_count - fall_positions.size()
		for i in range(remaining):
			var angle = randf() * TAU
			var rand_radius = sqrt(randf()) * effects.arrow_rain_radius * 1.6
			var random_offset = Vector2(cos(angle) * rand_radius, sin(angle) * rand_radius)
			# Deslocamento para trás (considerando que inimigos vêm do norte)
			var back_bias = Vector2(0, -effects.arrow_rain_radius * 0.25)
			fall_positions.append(target_position + random_offset + back_bias)
	
	# Se por algum motivo temos menos posições que flechas, completa com posições adicionais
	while fall_positions.size() < arrow_count:
		var angle = randf() * TAU
		var rand_radius = sqrt(randf()) * effects.arrow_rain_radius
		var random_offset = Vector2(cos(angle) * rand_radius, sin(angle) * rand_radius)
		fall_positions.append(target_position + random_offset)
	
	# Se temos mais posições que flechas, mantém apenas o necessário
	if fall_positions.size() > arrow_count:
		fall_positions = fall_positions.slice(0, arrow_count)
	
	return fall_positions

# Encontra clusters (agrupamentos) de inimigos para cobertura de área eficiente
func _find_enemy_clusters(enemies: Array, cluster_radius: float = 80.0) -> Array:
	if enemies.size() <= 1:
		if enemies.size() == 1:
			return [enemies[0].global_position]
		return []
	
	var clusters = []
	var processed = []
	
	for enemy in enemies:
		if enemy in processed:
			continue
			
		var cluster_members = [enemy]
		processed.append(enemy)
		
		# Encontra todos os inimigos próximos
		for other in enemies:
			if other == enemy or other in processed:
				continue
				
			if enemy.global_position.distance_to(other.global_position) <= cluster_radius:
				cluster_members.append(other)
				processed.append(other)
		
		# Se encontramos um cluster, calcula seu centro
		if cluster_members.size() > 1:
			var center = Vector2.ZERO
			for member in cluster_members:
				center += member.global_position
			center /= cluster_members.size()
			
			clusters.append(center)
		elif cluster_members.size() == 1:
			# Inimigo isolado
			clusters.append(enemy.global_position)
	
	return clusters


# Helper function to convert degrees to radians
func deg_to_rad(degrees: float) -> float:
	return degrees * (PI / 180.0)
