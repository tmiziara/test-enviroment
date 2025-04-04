extends Node
class_name RainArrowProcessor

# Arrow that this processor controls
var arrow: Node = null

# Flight parameters
var start_position: Vector2 = Vector2.ZERO
var target_position: Vector2 = Vector2.ZERO
var time_elapsed: float = 0.0
var total_time: float = 1.0
var arc_height: float = 200.0
var has_landed: bool = false

func _ready():
	# Get parent arrow
	arrow = get_parent()
	if not arrow:
		queue_free()
		return
	
	# If metadata exists, get values from it
	if arrow.has_meta("rain_start_pos"):
		start_position = arrow.get_meta("rain_start_pos")
	
	if arrow.has_meta("rain_target_pos"):
		target_position = arrow.get_meta("rain_target_pos")
		
	if arrow.has_meta("rain_time"):
		total_time = arrow.get_meta("rain_time")
	
	if arrow.has_meta("rain_arc_height"):
		arc_height = arrow.get_meta("rain_arc_height")
	
	# If start_position isn't set, use current position
	if start_position == Vector2.ZERO:
		start_position = arrow.global_position
	
	# If target_position isn't set, use position ahead
	if target_position == Vector2.ZERO:
		if "direction" in arrow:
			target_position = start_position + arrow.direction * 300
		else:
			target_position = start_position + Vector2.DOWN * 300
	
	# Disable regular physics for the arrow
	if arrow.has_method("set_physics_process"):
		arrow.set_physics_process(false)
	
	# Disable collision until landing
	if arrow.has_node("Hurtbox"):
		var hurtbox = arrow.get_node("Hurtbox")
		hurtbox.set_deferred("monitoring", false)
		hurtbox.set_deferred("monitorable", false)
	
	# Set orientation to point downward
	arrow.rotation = Vector2.DOWN.angle()

func _physics_process(delta):
	if not arrow or not is_instance_valid(arrow):
		queue_free()
		return
	
	if has_landed:
		return
	
	# Update time
	time_elapsed += delta
	
	# Calculate progress (0 to 1)
	var progress = min(time_elapsed / total_time, 1.0)
	
	# Calculate arc position
	var pos = calculate_arc_position(progress)
	
	# Update arrow position
	arrow.global_position = pos
	
	# Update arrow rotation to point along trajectory
	if progress < 0.9:  # Don't update rotation at the very end
		var next_pos = calculate_arc_position(min(progress + 0.05, 1.0))
		var direction = (next_pos - arrow.global_position).normalized()
		arrow.rotation = direction.angle()
	else:
		# At the end, point straight down
		arrow.rotation = Vector2.DOWN.angle()
	
	# Check if arrow has landed
	if progress >= 1.0:
		handle_landing()

# Calculate position along a parabolic arc
func calculate_arc_position(progress: float) -> Vector2:
	# Linear interpolation for horizontal movement
	var pos_x = lerp(start_position.x, target_position.x, progress)
	var pos_y = lerp(start_position.y, target_position.y, progress)
	
	# Add arc height - parabolic curve peaking at the middle
	var arc_offset = -arc_height * 4.0 * progress * (1.0 - progress)
	
	return Vector2(pos_x, pos_y + arc_offset)

# Handle arrow landing
func handle_landing():
	has_landed = true
	
	# Enable collision
	if arrow.has_node("Hurtbox"):
		var hurtbox = arrow.get_node("Hurtbox")
		hurtbox.set_deferred("monitoring", true)
		hurtbox.set_deferred("monitorable", true)
	
	# Set arrow pointing down
	arrow.rotation = Vector2.DOWN.angle()
	
	# Create pressure wave effect if enabled
	if arrow.has_meta("pressure_wave_enabled") and arrow.get_meta("pressure_wave_enabled"):
		create_pressure_wave()
	
	# Setup auto-destruction after a short time
	var timer = Timer.new()
	timer.wait_time = 0.5  # Half second to allow for collision detection
	timer.one_shot = true
	timer.autostart = true
	arrow.add_child(timer)
	timer.timeout.connect(func():
		if arrow and is_instance_valid(arrow):
			arrow.queue_free()
	)
	
	# Re-enable physics briefly to allow for collision detection
	if arrow.has_method("set_physics_process"):
		arrow.set_physics_process(true)
	
	# Set velocity downward for proper collision
	if "velocity" in arrow:
		arrow.velocity = Vector2.DOWN * (arrow.speed if "speed" in arrow else 400.0) * 0.5

# Create pressure wave effect
func create_pressure_wave():
	# Load the PressureWave scene or script
	var PressureWaveClass = load("res://Test/Processors/PersistentPressureWaveProcessor.gd")
	if not PressureWaveClass:
		print("Error: Could not load PressistentPressureWaveProcessor")
		return
	
	# Get pressure wave parameters from arrow metadata
	var knockback_force = arrow.get_meta("knockback_force", 150.0)
	var slow_percent = arrow.get_meta("slow_percent", 0.3)
	var slow_duration = arrow.get_meta("slow_duration", 0.5)
	var radius = arrow.get_meta("arrow_rain_radius", 80.0)
	var ground_duration = arrow.get_meta("ground_duration", 3.0)
	
	# Prepare settings
	var settings = {
		"duration": ground_duration,
		"slow_percent": slow_percent,
		"slow_duration": slow_duration,
		"knockback_force": knockback_force,
		"max_radius": radius,
		"only_slow": false
	}
	
	# Get parent scene
	var parent = arrow.get_parent()
	if not parent:
		return
	
	# Use the static method if available
	if PressureWaveClass.has_method("create_at_position"):
		PressureWaveClass.create_at_position(
			arrow.global_position,
			parent,
			arrow.shooter,
			settings
		)
	else:
		# Create manually if static method isn't available
		var wave = PressureWaveClass.new()
		wave.position = arrow.global_position
		wave.shooter = arrow.shooter
		wave.radius = 5.0
		wave.max_radius = radius
		wave.ground_effect_duration = ground_duration
		wave.slow_percent = slow_percent
		wave.slow_duration = slow_duration
		wave.knockback_force = knockback_force
		parent.add_child(wave)
