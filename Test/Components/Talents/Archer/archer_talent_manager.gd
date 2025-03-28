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
		
	# Update talent effects
	archer.set_meta("talents_updated", true)
	
	# Try to get compiled effects
	current_effects = talent_system.compile_effects()
	
	# Apply range multiplier immediately if available
	if current_effects and "range_multiplier" in current_effects:
		if current_effects.range_multiplier != 1.0:
			archer.attack_range *= current_effects.range_multiplier

# Apply all talents to a projectile
func apply_talents_to_projectile(projectile: Node) -> Node:
	print("ArcherTalentManager: apply_talents_to_projectile called")
	# Check for valid archer
	if not archer:
		push_error("ArcherTalentManager: Cannot apply talents - archer is null")
		return projectile
	
	# Ensure talent system is initialized
	if not talent_system:
		print("Initializing talent system in apply_talents_to_projectile")
		initialize_talent_system()
	
	if not talent_system:
		push_error("ArcherTalentManager: Cannot apply talents - talent system initialization failed")
		return projectile
	
	# Recompile effects if needed
	if not current_effects:
		print("Compiling effects in apply_talents_to_projectile")
		current_effects = talent_system.compile_effects()
	
	if current_effects:
		print("Applying compiled effects to projectile")
		talent_system.apply_compiled_effects(projectile, current_effects)
				# Print some info about the effects
		print("Arrow talent effects - crit: ", projectile.is_crit, 
			  ", damage: ", projectile.damage, 
			  ", tags: ", projectile.tags)
	
		# Check for arrow rain
		if "arrow_rain_enabled" in current_effects and current_effects.arrow_rain_enabled:
			attack_counter += 1
			if attack_counter >= current_effects.arrow_rain_interval:
				attack_counter = 0
				talent_system.spawn_arrow_rain(projectile, current_effects)
		
		# Check for double shot
		if "double_shot_enabled" in current_effects and current_effects.double_shot_enabled:
			talent_system.spawn_double_shot(projectile, current_effects)
	else:
		print("ERROR: current_effects is null, talents not applied")
	return projectile

# Apply bloodseeker stacks to a target
func apply_bloodseeker_hit(target: Node):
	if not archer or not target or not is_instance_valid(target):
		return
		
	if not current_effects or not "bloodseeker_enabled" in current_effects or not current_effects.bloodseeker_enabled:
		return
		
	# Initialize data structure if needed
	if not archer.has_meta("bloodseeker_data"):
		archer.set_meta("bloodseeker_data", {
			"target": null,
			"stacks": 0,
			"last_hit_time": 0
		})
	
	var data = archer.get_meta("bloodseeker_data")
	var current_target = data["target"]
	
	# Update timestamp
	data["last_hit_time"] = Time.get_ticks_msec()
	
	# Check if this is a new target
	if target != current_target:
		# New target, reset stacks to 1
		data["target"] = target
		data["stacks"] = 1
	else:
		# Same target, increment stacks up to max
		var stacks = data["stacks"]
		stacks = min(stacks + 1, current_effects.bloodseeker_max_stacks)
		data["stacks"] = stacks
	
	# Update the metadata
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
	data["stacks"] = 0
	archer.set_meta("bloodseeker_data", data)
	
	# Remove visual
	remove_stack_visual(archer)

# Connected to the target_change signal of the archer
func _on_target_change(new_target: Node):
	reset_bloodseeker_stacks()
