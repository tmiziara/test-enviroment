extends Node
class_name ArcherTalentManager

# Reference to the archer
var archer: ArcherBase
# Reference to the talent system
var talent_system: ArcherTalentSystem

# Attack counter (for talents like Arrow Rain)
var attack_counter: int = 0
var attack_handlers: Dictionary = {}

func _ready():
	# Find archer reference (should be parent)
	archer = get_parent() as ArcherBase
	
	if not archer:
		push_error("ArcherTalentManager: Parent is not an ArcherBase")
		return
	
	# Find or create talent system
	talent_system = archer.get_node_or_null("ArcherTalentSystem")
	
	if not talent_system:
		# Create talent system if it doesn't exist
		talent_system = ArcherTalentSystem.new(archer)
		talent_system.name = "ArcherTalentSystem"
		archer.add_child(talent_system)
		
		# Connect signals
		if not archer.is_connected("target_change", talent_system._on_target_change):
			archer.connect("target_change", talent_system._on_target_change)
	
	# Connect to archer's attack signals
	if not archer.is_connected("attack_started", _on_attack_started):
		archer.connect("attack_started", _on_attack_started)
	
	if not archer.is_connected("attack_finished", _on_attack_finished):
		archer.connect("attack_finished", _on_attack_finished)
	
	# Set up attack handlers
	_initialize_attack_handlers()
	
	print("ArcherTalentManager initialized")

# Initialize handlers for talent effects that trigger on attacks
func _initialize_attack_handlers():
	# Arrow Rain handler
	attack_handlers["arrow_rain"] = func():
		var effects = talent_system.compile_archer_effects()
		
		if effects.arrow_rain_enabled and effects.arrow_rain_interval > 0:
			attack_counter += 1
			
			# Check if we've reached the threshold
			if attack_counter >= effects.arrow_rain_interval:
				# Reset counter
				attack_counter = 0
				
				# Trigger arrow rain
				call_deferred("_trigger_arrow_rain", effects)

# Handler for attack started
func _on_attack_started():
	# Nothing specific yet
	pass

# Handler for attack finished
func _on_attack_finished():
	# Process attack handlers
	for handler_name in attack_handlers.keys():
		if attack_handlers[handler_name] is Callable:
			attack_handlers[handler_name].call()

# Trigger arrow rain effect
func _trigger_arrow_rain(effects):
	if not effects.arrow_rain_enabled or not is_instance_valid(archer):
		return
	
	# Get target
	var target = archer.get_current_target()
	if not target or not is_instance_valid(target):
		return
	
	# Calculate target position (centered on target)
	var target_pos = target.global_position
	
	# Calculate start position (above target)
	var start_pos = target_pos + Vector2(0, -200)
	
	# Create multiple rain arrows
	var count = effects.arrow_rain_count
	var radius = effects.arrow_rain_radius
	var damage_percent = effects.arrow_rain_damage_percent
	
	# Get base arrow damage
	var base_damage = archer.get_weapon_damage()
	var rain_damage = int(base_damage * damage_percent)
	
	# Create arrows in a pattern
	for i in range(count):
		# Calculate random position within radius
		var angle = randf() * TAU
		var distance = randf() * radius
		var offset = Vector2(cos(angle), sin(angle)) * distance
		var arrow_target_pos = target_pos + offset
		
		# Create the rain arrow
		_spawn_rain_arrow(start_pos, arrow_target_pos, rain_damage, effects)
	
	print("Arrow Rain triggered: ", count, " arrows")

# Spawn an individual rain arrow
func _spawn_rain_arrow(start_pos: Vector2, target_pos: Vector2, damage: int, effects):
	# Load arrow scene
	var arrow_scene = load("res://Test/Projectiles/Archer/Arrow.tscn")
	if not arrow_scene:
		return
	
	# Create arrow instance
	var arrow = arrow_scene.instantiate()
	
	# Configure as rain arrow
	arrow.global_position = start_pos
	arrow.direction = (target_pos - start_pos).normalized()
	arrow.shooter = archer
	arrow.damage = damage
	
	# Set rain arrow metadata
	arrow.set_meta("is_rain_arrow", true)
	arrow.set_meta("rain_start_pos", start_pos)
	arrow.set_meta("rain_target_pos", target_pos)
	arrow.set_meta("rain_arc_height", 250.0)
	arrow.set_meta("rain_time", 1.0)
	
	# Check if we should add pressure wave
	if effects.pressure_wave_enabled:
		arrow.set_meta("pressure_wave_enabled", true)
		arrow.set_meta("knockback_force", effects.knockback_force)
		arrow.set_meta("slow_percent", effects.slow_percent)
		arrow.set_meta("slow_duration", effects.slow_duration)
		arrow.set_meta("ground_duration", effects.ground_duration)
		arrow.set_meta("wave_visual_enabled", true)
	
	# Apply talent effects (through talent system)
	if talent_system:
		talent_system.apply_effects_to_projectile(arrow, effects)
	
	# Add to scene
	archer.get_parent().add_child(arrow)

# Handler for PressureWave talent
func create_pressure_wave(position: Vector2, settings: Dictionary = {}):
	# Check if PressureWaveProcessor is available
	var pressure_wave_script = load("res://Test/Processors/PersistentPressureWaveProcessor.gd")
	if not pressure_wave_script:
		push_error("ArcherTalentManager: PersistentPressureWaveProcessor not found")
		return null
	
	# Create wave through static method
	var wave = PersistentPressureWaveProcessor.create_at_position(
		position,
		archer.get_parent(),
		archer,
		settings
	)
	
	return wave

# Apply Bloodseeker stacks to an enemy
func apply_bloodseeker_stacks(target: Node, stacks: int):
	if not target or not is_instance_valid(target):
		return
	
	# Get current Bloodseeker data
	if not archer.has_meta("bloodseeker_data"):
		archer.set_meta("bloodseeker_data", {
			"target": target,
			"target_instance_id": target.get_instance_id(),
			"stacks": 0,
			"last_hit_time": Time.get_ticks_msec()
		})
	
	var data = archer.get_meta("bloodseeker_data")
	
	# Update stacks
	data.stacks = stacks
	data.last_hit_time = Time.get_ticks_msec()
	
	# Save updated data
	archer.set_meta("bloodseeker_data", data)
	
	# Update buff display if available
	if archer.buff_display_container:
		# Implementation depends on your buff display system
		pass
