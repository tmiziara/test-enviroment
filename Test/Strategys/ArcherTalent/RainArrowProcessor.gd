extends Node
class_name RainArrowProcessor

var start_position: Vector2
var target_position: Vector2
var total_time: float
var elapsed_time: float = 0.0
var arrow_speed: float = 500.0
var shadow: Node2D
var max_arc_height: float = 150.0  # Maximum height of the arc

func _ready():
	var arrow = get_parent()
	if not arrow:
		return
		
	# Get configuration values from metadata
	start_position = arrow.global_position
	if arrow.has_meta('rain_start_pos'):
		start_position = arrow.get_meta('rain_start_pos')
	
	if arrow.has_meta('rain_target_pos'):
		target_position = arrow.get_meta('rain_target_pos')
	else:
		# Fallback target position in front of the arrow
		target_position = start_position + Vector2(0, 300)
		
	if arrow.has_meta('rain_time'):
		total_time = arrow.get_meta('rain_time')
	else:
		# Calculate based on distance and speed
		var distance = start_position.distance_to(target_position)
		total_time = max(0.5, distance / arrow_speed)  # Ensure minimum time of 0.5 seconds
	
	# Create shadow at the impact point
	create_shadow(target_position)
	
	# Initial arrow setup
	arrow.direction = (target_position - start_position).normalized()
	arrow.rotation = arrow.direction.angle()
	
	# Make sure the arrow is visible and its physics is disabled
	arrow.visible = true
	arrow.set_physics_process(false)
	
	# Disable collision until impact
	if arrow.has_node("Hurtbox"):
		var hurtbox = arrow.get_node("Hurtbox")
		hurtbox.set_deferred("monitoring", false)
		hurtbox.set_deferred("monitorable", false)


func _physics_process(delta):
	var arrow = get_parent()
	if not arrow or not is_instance_valid(arrow):
		return
		
	# Update elapsed time
	elapsed_time += delta
	
	# Calculate progress (0 to 1)
	var progress = min(elapsed_time / total_time, 1.0)
	
	# Linear interpolation for position
	var new_position = start_position.lerp(target_position, progress)
	
	# Add arc using sine function
	var arc_height = max_arc_height * sin(progress * PI)
	new_position.y -= arc_height
	
	# Update arrow position
	arrow.global_position = new_position
	
	# Calculate direction for proper rotation
	var next_progress = min(progress + 0.05, 1.0)
	var next_position = start_position.lerp(target_position, next_progress)
	next_position.y -= max_arc_height * sin(next_progress * PI)
	
	var direction = (next_position - arrow.global_position).normalized()
	if direction.length() > 0.1:
		arrow.direction = direction
		arrow.rotation = direction.angle()
	# Handle impact when close to target
	if progress >= 0.95:
		handle_impact()
		set_physics_process(false)
		
	# Update shadow (pulsate to draw attention)
	if shadow and is_instance_valid(shadow):
		var pulse = (sin(elapsed_time * 5) + 1) / 2  # Oscillate between 0 and 1
		shadow.modulate.a = 0.3 + (0.2 * pulse)

func handle_impact():
	var arrow = get_parent()
	if not arrow or not is_instance_valid(arrow):
		return
		
	# Put arrow exactly at impact point
	arrow.global_position = target_position
	
	# Create impact effect
	create_impact_effect()
	
	# Re-enable collision
	if arrow.has_node("Hurtbox"):
		var hurtbox = arrow.get_node("Hurtbox")
		hurtbox.set_deferred("monitoring", true)
		hurtbox.set_deferred("monitorable", true)
	
	# Apply damage to nearby enemies
	var hit_enemies = find_and_damage_enemies()
	
	# Remove shadow
	if shadow and is_instance_valid(shadow):
		shadow.queue_free()
		shadow = null
	
	# Schedule cleanup/return to pool
	get_tree().create_timer(0.1).timeout.connect(func():
		if arrow and is_instance_valid(arrow):
			if arrow.has_method("return_to_pool") and arrow.has_meta("pooled") and arrow.get_meta("pooled"):
				arrow.return_to_pool()
			else:
				arrow.queue_free()
	)
	
	# Remove self
	queue_free()

func create_shadow(position: Vector2):
	var arrow = get_parent()
	if not arrow or not is_instance_valid(arrow):
		return
		
	var parent_node = arrow.get_parent()
	if not parent_node or not is_instance_valid(parent_node):
		return
		
	shadow = Node2D.new()
	shadow.name = "ArrowRainShadow"
	shadow.global_position = position
	shadow.z_index = -1  # Below other elements
	shadow.modulate = Color(1, 1, 1, 0.5)  # Semi-transparent
	
	# Add shadow sprite or custom draw
	var shadow_visual = Node2D.new()
	shadow_visual.name = "ShadowVisual"
	shadow.add_child(shadow_visual)
	
	# Custom drawing script
	var script = GDScript.new()
	script.source_code = """
	extends Node2D

	func _draw():
		# Outer shadow
		draw_circle(Vector2.ZERO, 8, Color(0, 0, 0, 0.3))
		# Inner shadow
		draw_circle(Vector2.ZERO, 4, Color(0, 0, 0, 0.5))
		# Draw small cross target for better visibility
		var cross_size = 6
		draw_line(Vector2(-cross_size, 0), Vector2(cross_size, 0), Color(0.8, 0, 0, 0.7), 1.0)
		draw_line(Vector2(0, -cross_size), Vector2(0, cross_size), Color(0.8, 0, 0, 0.7), 1.0)
	"""
	shadow_visual.set_script(script)
	
	# Add to scene
	parent_node.add_child(shadow)

func create_impact_effect():
	var arrow = get_parent()
	if not arrow or not is_instance_valid(arrow):
		return
		
	var parent_node = arrow.get_parent()
	if not parent_node or not is_instance_valid(parent_node):
		return
		
	# Create impact effect
	var impact = Node2D.new()
	impact.name = "ArrowImpact"
	impact.global_position = target_position
	parent_node.add_child(impact)
	
	# Add particles
	var particles = CPUParticles2D.new()
	impact.add_child(particles)
	
	# Configure particles
	particles.emitting = true
	particles.one_shot = true
	particles.explosiveness = 0.8
	particles.amount = 12
	particles.lifetime = 0.5
	particles.initial_velocity_min = 30
	particles.initial_velocity_max = 60
	particles.direction = Vector2.DOWN
	particles.spread = 180
	particles.gravity = Vector2(0, 98)
	particles.scale_amount_min = 2.0
	particles.scale_amount_max = 2.0
	particles.color = Color(0.8, 0.8, 0.8)
	
	# Auto-destroy after effect
	impact.create_tween().tween_callback(func(): impact.queue_free()).set_delay(1.0)

func find_and_damage_enemies() -> Array:
	var arrow = get_parent()
	if not arrow or not is_instance_valid(arrow):
		return []
		
	# Get damage from arrow
	var damage = 10  # Default fallback
	if "damage" in arrow:
		damage = arrow.damage
	# Find enemies in area
	var radius = 15.0  # Small area for single arrow hit
	var space_state = arrow.get_world_2d().direct_space_state
	
	var query = PhysicsShapeQueryParameters2D.new()
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = radius
	query.shape = circle_shape
	query.transform = Transform2D(0, target_position)
	query.collision_mask = 2  # Enemy layer
	
	var results = space_state.intersect_shape(query)
	var hit_enemies = []
	# Apply damage to each enemy
	for result in results:
		var body = result.collider
		if body.is_in_group("enemies") or body.get_collision_layer_value(2):
			if body.has_node("HealthComponent"):
				var health_component = body.get_node("HealthComponent")
				var damage_package = {}
				
				# Use damage package if available
				if arrow.has_method("get_damage_package"):
					damage_package = arrow.get_damage_package()
					health_component.take_complex_damage(damage_package)
				else:
					# Simple damage fallback
					var is_crit = arrow.is_crit if "is_crit" in arrow else false
					health_component.take_damage(damage, is_crit, "rain_arrow")
					
					# Create a simple damage package for DoT processing
					damage_package = {
						"physical_damage": damage,
						"is_critical": is_crit
					}
				# Process special DoT effects for critical hits with bleeding, etc.
				process_special_dot_effects(damage_package, body)
				
				# Add to hit enemies list
				hit_enemies.append(body)
	
	return hit_enemies

# Now let's add explicit debugging to process_special_dot_effects
func process_special_dot_effects(damage_package: Dictionary, target: Node) -> void:
	var arrow = get_parent()
	if not arrow or not is_instance_valid(arrow):
		return
	
	# Access DOT manager directly as a singleton
	var dot_manager = DoTManagerSingleton
	
	# Base damage for calculations
	var base_damage = damage_package.get("physical_damage", 10)
	
	# --- Handle all DOT types generically ---
	
	# 1. Check for bleeding DOT (requires critical hit)
	var is_critical = damage_package.get("is_critical", false)
	
	if is_critical and arrow.has_meta("has_bleeding_effect"):
		var damage_percent = arrow.get_meta("bleeding_damage_percent", 0.3)
		var duration = arrow.get_meta("bleeding_duration", 4.0)
		var interval = arrow.get_meta("bleeding_interval", 0.5)
		
		var bleeding_damage = max(1, int(base_damage * damage_percent))
		
		apply_dot(
			dot_manager,
			target, 
			bleeding_damage, 
			duration, 
			interval, 
			"bleeding", 
			arrow
		)
	
	# 2. Check for fire DOT from DmgCalculatorComponent
	if arrow.has_node("DmgCalculatorComponent"):
		var dmg_calc = arrow.get_node("DmgCalculatorComponent")
		
		if dmg_calc.has_meta("fire_dot_data"):
			var dot_data = dmg_calc.get_meta("fire_dot_data")
			
			# Extract parameters
			var dot_chance = dot_data.get("chance", 0.0)
			var dot_damage = max(1, dot_data.get("damage_per_tick", 0))
			var dot_duration = dot_data.get("duration", 3.0)
			var dot_interval = dot_data.get("interval", 0.5)
			var dot_type = dot_data.get("type", "fire")
			
			# Roll the chance
			if randf() <= dot_chance:
				apply_dot(
					dot_manager,
					target, 
					dot_damage, 
					dot_duration, 
					dot_interval, 
					dot_type, 
					arrow
				)
	
	# 3. Process any other DOT effects from damage_package
	if "dot_effects" in damage_package and damage_package.dot_effects is Array:
		for dot_effect in damage_package.dot_effects:
			var dot_damage = max(1, dot_effect.get("damage", 0))
			var dot_duration = dot_effect.get("duration", 3.0)
			var dot_interval = dot_effect.get("interval", 0.5)
			var dot_type = dot_effect.get("type", "generic")
			
			apply_dot(
				dot_manager,
				target, 
				dot_damage, 
				dot_duration, 
				dot_interval, 
				dot_type, 
				arrow
			)

# Helper function to apply a DOT consistently
func apply_dot(dot_manager, target, damage, duration, interval, dot_type, source):
	if not dot_manager or not dot_manager.has_method("apply_dot"):
		print("Invalid DOT manager for", dot_type, "DOT")
		return ""
		
	var dot_id = dot_manager.apply_dot(
		target,
		damage,
		duration,
		interval,
		dot_type,
		source
	)
	
	print(dot_type.capitalize(), "DOT applied with ID:", dot_id)
	return dot_id
