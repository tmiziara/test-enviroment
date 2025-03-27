extends BaseProjectileStrategy
class_name Talent_15

# Arrow Explosion parameters
@export var explosion_damage_percent: float = 0.5   # 50% of original arrow damage
@export var explosion_radius: float = 35.0         # Radius of explosion effect in pixels
@export var talent_id: int = 15                    # ID for this talent in the talent tree

# Name for debug panel
func get_strategy_name() -> String:
	return "Arrow Explosion"

# Main upgrade application
func apply_upgrade(projectile: Node) -> void:
	print("Applying Arrow Explosion upgrade - Arrows will explode on impact!")
	
	# Skip if projectile is from an explosion to avoid recursion
	if projectile.has_meta("from_explosion"):
		print("Skipping Arrow Explosion for secondary explosion arrow")
		return

	# Skip if this is not an arrow or doesn't have required properties
	if not "damage" in projectile:
		print("Cannot apply Arrow Explosion to incompatible projectile")
		return
		
	# Check if arrow already has explosion property to avoid duplicating
	if "has_explosion_effect" in projectile or projectile.has_meta("has_explosion_effect"):
		print("Explosion effect already applied to this arrow")
		return
		
	# Add tag for identification
	if "tags" in projectile and projectile.has_method("add_tag"):
		projectile.add_tag("explosive")
	elif "tags" in projectile:
		if not "explosive" in projectile.tags:
			projectile.tags.append("explosive")

	# Mark arrow as having explosion effect
	projectile.set_meta("has_explosion_effect", true)
	
	# Store explosion parameters in arrow for later use
	projectile.set_meta("explosion_damage_percent", explosion_damage_percent)
	projectile.set_meta("explosion_radius", explosion_radius)
	
	# Register callback for when the arrow hits a target
	enhance_arrow_impact(projectile)

# Enhance arrow to explode on impact
func enhance_arrow_impact(arrow: Node) -> void:
	# For standard arrows, enhance their process_on_hit
	if arrow is Arrow:
		print("Enhancing Arrow with explosion effect")
		
		# Store reference to self to use in callbacks
		var self_ref = weakref(self)
		
		# Connect to the arrow's 'on_hit' signal if it exists
		if arrow.has_signal("on_hit"):
			# Check if signal is already connected
			var connections = arrow.get_signal_connection_list("on_hit")
			var already_connected = false
			
			for connection in connections:
				if connection.callable.get_object() == self:
					already_connected = true
					break
			
			if not already_connected:
				arrow.connect("on_hit", func(target, projectile):
					# Only process explosion if this is our arrow
					if projectile == arrow and is_instance_valid(target):
						# Get self reference to access methods
						var strategy = self_ref.get_ref()
						if strategy:
							# Create explosion at impact point
							strategy.create_explosion(arrow, target)
				)
				print("Connected to arrow's on_hit signal")
			else:
				print("Already connected to on_hit signal")
		elif arrow.has_method("process_on_hit"):
			# Store original process_on_hit method if it exists
			print("Arrow has process_on_hit method - setting up explosion metadata")
			
			# Add metadata to be checked in the Arrow's process_on_hit method
			arrow.set_meta("explosion_strategy", self_ref)
			print("Added explosion_strategy reference to arrow")
		else:
			print("Arrow doesn't have process_on_hit method or on_hit signal, cannot enhance")
	else:
		# For non-Arrow types, just set metadata
		arrow.set_meta("explosion_strategy", weakref(self))
		arrow.set_meta("create_explosion_on_impact", true)
		print("Added explosion metadata to non-Arrow projectile")

# Create an explosion at the impact point
func create_explosion(arrow: Node, hit_target: Node) -> void:
	print("Creating explosion at impact point!")
	
	# Safety checks
	if not is_instance_valid(arrow) or not is_instance_valid(hit_target):
		print("Invalid arrow or target for explosion")
		return
		
	# Get parent scene to add explosion to
	var parent_scene = arrow.get_parent()
	if not parent_scene:
		print("No parent scene for explosion")
		return
		
	# Get explosion data from metadata
	var explosion_damage_percent = arrow.get_meta("explosion_damage_percent", 0.5)
	var explosion_radius = arrow.get_meta("explosion_radius", 35.0)
	
	# Calculate damage for explosion (50% of original)
	var explosion_damage = int(arrow.damage * explosion_damage_percent)
	if explosion_damage < 1:
		explosion_damage = 1  # Ensure minimum damage of 1
		
	# Get shooter for proper attribution
	var shooter = arrow.shooter if "shooter" in arrow else null
	
	# Get all potential targets within explosion radius
	var impact_position = hit_target.global_position
	var targets_hit = apply_explosion_damage(impact_position, explosion_damage, explosion_radius, arrow)
	
	# Create visual explosion effect
	create_explosion_effect(impact_position, explosion_radius, parent_scene)
	
	print("Explosion hit", targets_hit, "targets")

# Apply damage to all targets within explosion radius
func apply_explosion_damage(impact_position: Vector2, damage: int, radius: float, source_arrow: Node) -> int:
	# Get current scene
	var current_scene = Engine.get_main_loop().current_scene
	if not current_scene:
		print("No current scene found")
		return 0
		
	var space_state = current_scene.get_world_2d().direct_space_state
	
	# Create circle shape for area detection
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = radius
	
	var query = PhysicsShapeQueryParameters2D.new()
	query.shape = circle_shape
	query.transform = Transform2D(0, impact_position)
	query.collision_mask = 2  # Enemy collision layer
	query.collide_with_bodies = true
	
	var results = space_state.intersect_shape(query)
	print("Explosion found", results.size(), "potential targets in area")
	
	# Apply damage to each valid enemy
	var hits = 0
	for result in results:
		var body = result.collider
		
		if body and is_instance_valid(body) and body.has_node("HealthComponent"):
			var health_component = body.get_node("HealthComponent")
			print("Explosion hit:", body.name, "with damage:", damage)
			
			# Check if the enemy is the original hit target
			var is_original_target = false
			if source_arrow.has_meta("last_hit_target"):
				is_original_target = (body == source_arrow.get_meta("last_hit_target"))
			
			# Skip damaging the original target (already received direct hit damage)
			if is_original_target:
				print("Skipping original target that was directly hit")
				continue
			
			# Try to apply full damage package if possible for elemental effects
			if source_arrow.has_node("DmgCalculatorComponent"):
				# Copy damage structure with reduced value
				var dmg_calc = source_arrow.get_node("DmgCalculatorComponent")
				var is_crit = source_arrow.is_crit if "is_crit" in source_arrow else false
				
				var damage_package = {
					"physical_damage": damage,
					"is_critical": is_crit,
					"elemental_damage": {},
					"armor_penetration": 0.0
				}
				
				# Get armor penetration if available
				if "armor_penetration" in dmg_calc:
					damage_package["armor_penetration"] = dmg_calc.armor_penetration
				
				# Copy elemental damage with explosion reduction
				if "elemental_damage" in dmg_calc:
					for element in dmg_calc.elemental_damage:
						var elem_dmg = int(dmg_calc.elemental_damage[element] * explosion_damage_percent)
						if elem_dmg > 0:
							damage_package["elemental_damage"][element] = elem_dmg
				
				print("Applying explosion damage package:", damage_package)
				health_component.take_complex_damage(damage_package)
			else:
				# Fallback to basic damage
				var is_crit = source_arrow.is_crit if "is_crit" in source_arrow else false
				health_component.take_damage(damage, is_crit, "explosion")
			
			hits += 1
	
	return hits

# Create a visual explosion effect
func create_explosion_effect(position: Vector2, radius: float, parent: Node) -> void:
	# Create explosion container
	var explosion = Node2D.new()
	explosion.name = "ArrowExplosion"
	explosion.position = position
	parent.add_child(explosion)
	
	# Create circle for explosion
	var explosion_circle = Node2D.new()
	explosion.add_child(explosion_circle)
	
	# Create a visual for the explosion
	explosion_circle.set_script(GDScript.new())
	explosion_circle.script.source_code = """
	extends Node2D

	var radius = 35.0
	var current_radius = 0.0
	var max_radius = 0.0
	var alpha = 1.0
	var color = Color(1.0, 0.5, 0.0, 1.0)  # Orange-yellow explosion
	
	func _ready():
		max_radius = radius
	
	func _process(delta):
		if current_radius < max_radius:
			current_radius += max_radius * 5 * delta  # Expand quickly
		else:
			alpha -= delta * 2  # Fade out
			
		if alpha <= 0:
			queue_free()
			
		queue_redraw()
	
	func _draw():
		if alpha > 0:
			# Draw outer glow
			draw_circle(Vector2.ZERO, current_radius, Color(color.r, color.g, color.b, alpha * 0.3))
			
			# Draw inner core
			var inner_radius = max(0, current_radius * 0.7)
			draw_circle(Vector2.ZERO, inner_radius, Color(1.0, 0.8, 0.0, alpha * 0.7))
	"""
	
	# Set explosion radius
	explosion_circle.set("radius", radius)
	
	# Add particles for additional effect
	var particles = CPUParticles2D.new()
	explosion.add_child(particles)
	
	# Configure particles
	particles.emitting = true
	particles.one_shot = true
	particles.explosiveness = 0.8
	particles.amount = 20
	particles.lifetime = 0.5
	particles.direction = Vector2(0, -1)
	particles.spread = 180.0
	particles.gravity = Vector2.ZERO
	particles.initial_velocity_min = radius * 0.8
	particles.initial_velocity_max = radius * 1.2
	particles.scale_amount_min = 2.0
	particles.scale_amount_max = 3.0
	particles.color = Color(1.0, 0.5, 0.0, 1.0)
	particles.color_ramp = Gradient.new()
	particles.color_ramp.add_point(0.0, Color(1.0, 0.8, 0.0, 1.0))
	particles.color_ramp.add_point(1.0, Color(1.0, 0.3, 0.0, 0.0))
	
	# Create auto-destruct timer for explosion container
	var timer = Timer.new()
	explosion.add_child(timer)
	timer.wait_time = 1.0  # Total lifetime of the explosion effect
	timer.one_shot = true
	timer.timeout.connect(func(): explosion.queue_free())
	timer.start()
	
	# Sound effect could be added here if available
	# var audio_player = AudioStreamPlayer2D.new()
	# explosion.add_child(audio_player)
	# audio_player.stream = preload("res://path/to/explosion_sound.wav")
	# audio_player.play()
