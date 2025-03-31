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
	
	# IMPORTANT: Always recompile effects to ensure they're current
	print("FORÇANDO recompilação de efeitos para garantir valores corretos")
	current_effects = talent_system.compile_effects()
	
	if current_effects:
		print("Compilando efeitos a partir de " + str(archer.attack_upgrades.size()) + " estratégias:")
		# Log which strategies are being processed
		for strategy in archer.attack_upgrades:
			if strategy:
				print("- Processando estratégia: " + strategy.get_strategy_name())
		talent_system.apply_compiled_effects(projectile, current_effects)
		
		# Check for special abilities
		if "arrow_rain_enabled" in current_effects and current_effects.arrow_rain_enabled:
			# Only increment counter for normal arrows, not for Arrow Rain arrows themselves
			if not projectile.has_meta("is_rain_arrow"):
				# Track attack counter
				if not archer.has_meta("arrow_rain_counter"):
					archer.set_meta("arrow_rain_counter", 0)
				
				var counter = archer.get_meta("arrow_rain_counter")
				counter += 1
				archer.set_meta("arrow_rain_counter", counter)
				
				print("Arrow Rain counter: " + str(counter) + "/" + str(current_effects.arrow_rain_interval))
				
				# If we've reached the threshold, trigger Arrow Rain and reset counter
				if counter >= current_effects.arrow_rain_interval:
					print("Arrow Rain triggered!")
					archer.set_meta("arrow_rain_counter", 0)
					talent_system.spawn_arrow_rain(projectile, current_effects)
		
		if projectile.has_meta("double_shot_enabled") and not projectile.has_meta("is_second_arrow"):
			print("Double Shot enabled - will spawn second arrow")
			# Let the ConsolidatedTalentSystem handle the spawning to ensure proper effect application
			if talent_system and current_effects:
				talent_system.spawn_double_shot(projectile, current_effects)
			else:
				print("ERROR: Cannot spawn second arrow - talent_system or current_effects is null")
				
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
