extends Node
class_name ArcherTalentManager

# Reference to the archer
var archer: Soldier_Base

# Talent system reference
var talent_system: ConsolidatedTalentSystem

# Attack counter
var attack_counter: int = 0

# Store compiled effects
var current_effects

func _init(archer_ref: Soldier_Base = null):
	if archer_ref:
		archer = archer_ref
		
func _ready():
	# If archer wasn't set in _init, try to get from parent
	if not archer:
		var parent = get_parent()
		if parent is Soldier_Base:
			archer = parent
			
	# Validate archer reference and initialize talent system
	if archer:
		initialize_talent_system()
	else:
		push_error("ArcherTalentManager: No archer reference provided")


# Separate method for talent system initialization
func initialize_talent_system():
	if archer and not talent_system:
		talent_system = ConsolidatedTalentSystem.new(archer)
		# Initial compilation of effects
		if talent_system:
			current_effects = talent_system.compile_effects()
		
# Call this when upgrading the archer with new talents
func refresh_talents():
	if not archer:
		push_error("ArcherTalentManager: Cannot refresh talents - archer is null")
		return
		
	if not talent_system:
		initialize_talent_system()
		
	if not talent_system:
		push_error("ArcherTalentManager: Cannot refresh talents - failed to initialize talent system")
		return
	if talent_system:
		current_effects = talent_system.compile_effects()
	# Update talent effects
	archer.set_meta("talents_updated", true)
	
	# Try to get compiled effects
	current_effects = talent_system.compile_effects()
	
	# Apply range multiplier immediately if available
	if current_effects and "range_multiplier" in current_effects:
		if current_effects.range_multiplier != 1.0:
			archer.attack_range *= current_effects.range_multiplier
	
	# Check for Double Shot and update archer accordingly
	if current_effects and "double_shot_enabled" in current_effects and current_effects.double_shot_enabled:
		archer.set_meta("has_double_shot", true)
		archer.set_meta("double_shot_active", true)
		archer.set_meta("double_shot_angle", current_effects.double_shot_angle)
		archer.set_meta("double_shot_damage_modifier", current_effects.second_arrow_damage_modifier)
	else:
		# Ensure Double Shot is disabled if not available
		if archer.has_meta("double_shot_active"):
			archer.set_meta("double_shot_active", false)

func apply_talents_to_projectile(projectile: Node) -> Node:
	# Check for valid archer
	if not archer:
		return projectile
	
	# Ensure talent system is initialized
	if not talent_system:
		initialize_talent_system()
	
	# IMPORTANT: Always recompile effects to ensure they're current
	current_effects = talent_system.compile_effects()
	
	# Apply the compiled effects using the talent system
	if current_effects:
		talent_system.apply_compiled_effects(projectile, current_effects)
		
		# Check for arrow rain counter
		if "arrow_rain_enabled" in current_effects and current_effects.arrow_rain_enabled:
			# Skip for double shot arrows
			if projectile.has_meta("is_double_shot"):
				return projectile
				
			# Skip for rain arrows
			if projectile.has_meta("is_rain_arrow"):
				return projectile
				
			# Track attack counter for standard arrows
			if not archer.has_meta("arrow_rain_counter"):
				archer.set_meta("arrow_rain_counter", 0)
			
			var counter = archer.get_meta("arrow_rain_counter")
			counter += 1
			archer.set_meta("arrow_rain_counter", counter)
			
			# Check threshold
			if counter >= current_effects.arrow_rain_interval:
				archer.set_meta("arrow_rain_counter", 0)
				call_deferred("spawn_arrow_rain", projectile)
	else:
		print("ERROR: current_effects is null, talents not applied")
	
	return projectile
	
func apply_bloodseeker_hit(target: Node) -> void:
	# Basic checks
	if not archer or not target or not is_instance_valid(target):
		return
	
	# Verify if Bloodseeker effect is active
	if not current_effects or not "bloodseeker_enabled" in current_effects or not current_effects.bloodseeker_enabled:
		return
	
	# Initialize data structure if needed
	if not archer.has_meta("bloodseeker_data"):
		archer.set_meta("bloodseeker_data", {
			"target": null,
			"stacks": 0,
			"last_hit_time": 0,
			"target_instance_id": -1  # Add instance ID tracking
		})
	
	var data = archer.get_meta("bloodseeker_data")
	var current_target = data["target"]
	var current_target_id = data["target_instance_id"]
	var target_id = target.get_instance_id()
	
	# Update timestamp
	data["last_hit_time"] = Time.get_ticks_msec()
	
	# Check if it's a new target by comparing instance IDs
	if target_id != current_target_id:
		# New target, reset stacks to 1
		data["target"] = target
		data["target_instance_id"] = target_id
		data["stacks"] = 1
	else:
		# Same target, increment stacks up to maximum
		var stacks = data["stacks"]
		var max_stacks = current_effects.bloodseeker_max_stacks
		stacks = min(stacks + 1, max_stacks)
		data["stacks"] = stacks
	
	# Update metadata
	archer.set_meta("bloodseeker_data", data)
	
	# Create visual indicator
	create_stack_visual(archer, data["stacks"], current_effects.bloodseeker_max_stacks)
	
# Create a visual indicator for bloodseeker stacks
func create_stack_visual(player: Node, stacks: int, max_stacks: int):
	if not player or not is_instance_valid(player):
		return
		
	# First remove any existing indicator
	remove_stack_visual(player)
	
	# Don't show anything for 0 stacks
	if stacks <= 0:
		return
	
	# Create container
	var container = Control.new()
	container.name = "BloodseekerStackDisplay"
	container.position = Vector2(-40, -40)
	container.z_index = 100
	
	# Width for indicator
	var total_width = 16 * min(stacks, max_stacks)
	container.custom_minimum_size = Vector2(total_width, 16)
	
	# Create indicator with text
	var label = Label.new()
	label.text = str(stacks) + "x"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size_flags_horizontal = Control.SIZE_FILL
	label.size_flags_vertical = Control.SIZE_FILL
	
	# Apply color
	var font_color = Color(1.0, 0.2, 0.2)
	label.add_theme_color_override("font_color", font_color)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	
	# Add label to container
	container.add_child(label)
	
	# Add to player
	player.add_child(container)
	
	# Store reference to container
	player.set_meta("bloodseeker_visual", container)
	
	# Add animation
	var tween = container.create_tween()
	tween.tween_property(container, "scale", Vector2(1.2, 1.2), 0.25)
	tween.tween_property(container, "scale", Vector2(1.0, 1.0), 0.25)
	
	# Special animation for max stacks
	if stacks >= max_stacks:
		var max_tween = container.create_tween()
		max_tween.tween_property(container, "modulate", Color(1.0, 0.5, 0.0, 1.0), 0.3)
		max_tween.tween_property(container, "modulate", Color(1.0, 0.0, 0.0, 1.0), 0.3)
		max_tween.set_loops(2)

# Remove stack visual
func remove_stack_visual(player: Node):
	if not player or not is_instance_valid(player):
		return
		
	if player.has_meta("bloodseeker_visual"):
		var visual = player.get_meta("bloodseeker_visual")
		if visual and is_instance_valid(visual):
			visual.queue_free()
		player.remove_meta("bloodseeker_visual")

# Reset bloodseeker stacks when changing targets
func reset_bloodseeker_stacks():
	if not archer or not archer.has_meta("bloodseeker_data"):
		return
		
	var data = archer.get_meta("bloodseeker_data")
	data["target"] = null
	data["target_instance_id"] = -1  # Clear instance ID
	data["stacks"] = 0
	archer.set_meta("bloodseeker_data", data)
	
	# Remove visual
	remove_stack_visual(archer)

# Connected to the target_change signal of the archer
func _on_target_change(new_target: Node):
	reset_bloodseeker_stacks()

# Método simplificado para Arrow Rain
func spawn_arrow_rain(original_projectile: Node) -> void:
	if not archer or not is_instance_valid(archer) or not current_effects:
		return
	
	# Determine target position
	var target_position = Vector2.ZERO
	if archer.current_target and is_instance_valid(archer.current_target):
		target_position = archer.current_target.global_position
	else:
		var direction = original_projectile.direction if original_projectile else Vector2.RIGHT
		target_position = archer.global_position + direction * 300
	
	# Get archer position and arrow rain count
	var spawn_pos = archer.global_position
	var arrow_count = current_effects.arrow_rain_count if "arrow_rain_count" in current_effects else 5
	
	# Get radius
	var radius = current_effects.arrow_rain_radius if "arrow_rain_radius" in current_effects else 80.0
	
	# Batch spawn arrows
	for i in range(arrow_count):
		# Create random position around target
		var angle = randf() * TAU
		var distance = randf() * radius
		var pos_offset = Vector2(cos(angle), sin(angle)) * distance
		var target_pos = target_position + pos_offset
		
		# Create new arrow
		var arrow_scene = preload("res://Test/Projectiles/Archer/Arrow.tscn")
		var arrow = arrow_scene.instantiate()
		
		# Set initial position above the target
		arrow.global_position = spawn_pos + Vector2(0, -200)
		
		# Set properties
		arrow.shooter = archer
		arrow.set_meta("is_rain_arrow", true)
		
		if "damage" in original_projectile:
			var rain_damage_percent = current_effects.arrow_rain_damage_percent if "arrow_rain_damage_percent" in current_effects else 0.5
			arrow.damage = int(original_projectile.damage * rain_damage_percent)
		
		# Add to scene
		archer.get_parent().add_child(arrow)
		
		# Create processor
		var processor = load("res://Test/Processors/RainArrowProcessor.gd").new()
		arrow.add_child(processor)
		
		# Set trajectory
		processor.start_position = arrow.global_position
		processor.target_position = target_pos
		processor.arc_height = randf_range(200, 300)
		processor.total_time = 1.0 + (i * 0.05)  # Slight variation
		
		# Configure processor for pressure wave if available
		if "pressure_wave_enabled" in current_effects and current_effects.pressure_wave_enabled:
			arrow.set_meta("pressure_wave_enabled", true)
			arrow.set_meta("knockback_force", current_effects.knockback_force if "knockback_force" in current_effects else 150.0)
			arrow.set_meta("slow_percent", current_effects.slow_percent if "slow_percent" in current_effects else 0.3)
			arrow.set_meta("slow_duration", current_effects.slow_duration if "slow_duration" in current_effects else 0.5)
			arrow.set_meta("arrow_rain_radius", radius)
			arrow.set_meta("ground_duration", current_effects.ground_duration if "ground_duration" in current_effects else 3.0)
