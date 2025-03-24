extends BaseProjectileStrategy
class_name Talent_13

# Arrow Rain parameters
@export var arrow_count: int = 5          # Number of arrows in the rain
@export var damage_per_arrow: int = 10     # Damage caused by each arrow
@export var radius: float = 50.0          # Radius of the affected area
@export var min_height: float = 400.0     # Minimum spawn height for arrows
@export var max_height: float = 450.0     # Maximum spawn height for arrows
@export var impact_radius: float = 25.0   # Impact radius of each arrow
@export var attacks_threshold: int = 10   # Threshold of attacks before triggering Arrow Rain
@export var talent_id: int = 13           # ID for this talent in the talent tree

# Counter to track number of attacks
var attack_counter = {}  # Dictionary to track attack counts per archer

# Capture original projectile information and ensure it's affected by archer attributes
func capture_original_arrow_data(projectile):
	var data = {}
	
	# Basic properties
	data.damage = projectile.damage if "damage" in projectile else damage_per_arrow
	data.crit_chance = projectile.crit_chance if "crit_chance" in projectile else 0.1
	
	# Tags
	data.tags = projectile.tags.duplicate() if "tags" in projectile else []
	
	# Capture DmgCalculator data which would contain bonuses from archer stats
	if projectile.has_node("DmgCalculatorComponent"):
		var dmg_calc = projectile.get_node("DmgCalculatorComponent")
		data.dmg_calc_data = {
			"base_damage": dmg_calc.base_damage if "base_damage" in dmg_calc else data.damage,
			"elemental_damage": dmg_calc.elemental_damage.duplicate() if "elemental_damage" in dmg_calc else {},
			"dot_effects": dmg_calc.dot_effects.duplicate() if "dot_effects" in dmg_calc else []
		}
		
		# Copy other important attributes that may affect damage calculation
		if "damage_multiplier" in dmg_calc:
			data.dmg_calc_data.damage_multiplier = dmg_calc.damage_multiplier
		
		if "armor_penetration" in dmg_calc:
			data.dmg_calc_data.armor_penetration = dmg_calc.armor_penetration
			
		# Main stat and stat multiplier (used for archer dexterity bonuses)
		if "main_stat" in dmg_calc:
			data.dmg_calc_data.main_stat = dmg_calc.main_stat
			
		if "main_stat_multiplier" in dmg_calc:
			data.dmg_calc_data.main_stat_multiplier = dmg_calc.main_stat_multiplier
	
	# Get shooter stats that might affect damage
	if projectile.shooter:
		var shooter = projectile.shooter
		data.shooter_stats = {}
		
		# Check for relevant stats from archer
		if "main_stat" in shooter:
			data.shooter_stats.main_stat = shooter.main_stat
			
		if "main_stat_type" in shooter:
			data.shooter_stats.main_stat_type = shooter.main_stat_type
			
		# Check for weapon damage
		if shooter.has_method("get_weapon_damage"):
			data.shooter_stats.weapon_damage = shooter.get_weapon_damage()
	
	return data

# Called when a destroy timer times out for an arrow
func _on_destroy_timer_timeout(arrow):
	if arrow and is_instance_valid(arrow):
		arrow.queue_free()

# Executed when an arrow reaches its impact point
func on_arrow_impact(impact_position, arrow, shadow, shooter):
	# Debug print to track execution
	print("Arrow Rain: Impact at position ", impact_position)
	
	# Verificar se a flecha tem efeito de explosão
	var has_explosion = arrow.has_meta("has_explosion_effect")
	var explosion_strategy = null
	
	if has_explosion and arrow.has_meta("explosion_strategy"):
		var explosion_strategy_ref = arrow.get_meta("explosion_strategy")
		explosion_strategy = explosion_strategy_ref.get_ref() if explosion_strategy_ref is WeakRef else explosion_strategy_ref
	
	# Calculate correct damage based on critical hit status
	var impact_damage = arrow.damage
	if arrow.is_crit:
		# Use the crit multiplier (default 2.0 if not available)
		var crit_mult = 2.0
		if arrow.has_node("DmgCalculatorComponent"):
			var dmg_calc = arrow.get_node("DmgCalculatorComponent")
			if "crit_multiplier" in dmg_calc:
				crit_mult = dmg_calc.crit_multiplier
		
		impact_damage = int(impact_damage * crit_mult)
		print("Arrow Rain: Critical hit! Damage increased to ", impact_damage)
	
	# Try our direct damage application first (more reliable)
	var direct_hits = apply_damage_to_area(impact_position, impact_damage, arrow.is_crit, "arrow_rain", arrow)
	
	if direct_hits > 0:
		print("Arrow Rain: Direct damage application successful, hit ", direct_hits, " targets")
		
		# Se tiver efeito de explosão e pelo menos um alvo, aplicar explosão
		if has_explosion and explosion_strategy:
			print("Arrow Rain: Arrow has explosion effect! Creating explosion...")
			
			# Buscar primeiro inimigo atingido para servir como alvo da explosão
			var enemy_hit = find_enemy_at_position(impact_position, impact_radius)
			if enemy_hit:
				# Marcar o último alvo atingido para evitar dano duplo
				arrow.set_meta("last_hit_target", enemy_hit)
				
				# Aplicar efeito de explosão
				explosion_strategy.create_explosion(arrow, enemy_hit)
				print("Arrow Rain: Explosion created on enemy at position ", enemy_hit.global_position)
			else:
				print("Arrow Rain: No valid targets found for explosion effect")
	else:
		print("Arrow Rain: Direct damage failed, trying fallback method")
		
		# Fallback to the original method as backup
		var space_state = arrow.get_world_2d().direct_space_state
		
		# Set up shape query to find enemies in impact area
		var query = PhysicsShapeQueryParameters2D.new()
		var circle_shape = CircleShape2D.new()
		circle_shape.radius = impact_radius
		query.shape = circle_shape
		query.transform = Transform2D(0, impact_position)
		query.collision_mask = 2  # Enemy collision layer
		query.collide_with_bodies = true
		
		# Execute overlap search using direct PhysicsDirectSpaceState2D query
		var results = []
		results = space_state.intersect_shape(query)
		print("Arrow Rain: Found ", results.size(), " potential targets in area")
		
		# For each enemy in impact zone
		var targets_hit = 0
		var first_target = null
		
		for result in results:
			var body = result.collider
			if body and is_instance_valid(body):
				print("Arrow Rain: Checking potential target: ", body.name)
				
				# Direct damage application without requiring "enemies" group
				if body.has_node("HealthComponent"):
					var health = body.get_node("HealthComponent")
					
					# Guardamos o primeiro alvo para o efeito de explosão
					if targets_hit == 0:
						first_target = body
					
					# If complex damage calculation is available
					if arrow.has_method("get_damage_package"):
						var damage_package = arrow.get_damage_package()
						print("Arrow Rain: Applying complex damage: ", damage_package)
						health.take_complex_damage(damage_package)
						targets_hit += 1
					else:
						# Fallback to basic damage
						var damage_amount = arrow.damage if "damage" in arrow else damage_per_arrow * 3
						var is_crit = arrow.is_crit if "is_crit" in arrow else false
						print("Arrow Rain: Applying basic damage: ", damage_amount)
						health.take_damage(damage_amount, is_crit)
						targets_hit += 1
		
		print("Arrow Rain: Successfully applied damage to ", targets_hit, " targets")
		
		# Aplicar efeito de explosão no primeiro alvo encontrado
		if has_explosion and explosion_strategy and first_target:
			print("Arrow Rain: Creating explosion effect on first found target!")
			arrow.set_meta("last_hit_target", first_target)
			explosion_strategy.create_explosion(arrow, first_target)
	
	
	if has_meta("enable_splinters") and has_meta("splinter_strategy"):
		var splinter_strategy = get_meta("splinter_strategy")
		if splinter_strategy and is_instance_valid(splinter_strategy):
			# Procura por inimigos atingidos pela flecha
			var current_scene = Engine.get_main_loop().current_scene
			var space_state = current_scene.get_world_2d().direct_space_state
			
			# Create a circle shape for target detection
			var circle_shape = CircleShape2D.new()
			circle_shape.radius = impact_radius
			
			var query = PhysicsShapeQueryParameters2D.new()
			query.shape = circle_shape
			query.transform = Transform2D(0, impact_position)
			query.collision_mask = 2  # Enemy layer
			query.collide_with_bodies = true
			
			var results = space_state.intersect_shape(query)
			
			# Encontra o primeiro inimigo atingido
			for result in results:
				var body = result.collider
				if body and is_instance_valid(body) and body.is_in_group("enemies"):
					# Encontrou um alvo - cria fragmentos a partir dele
					splinter_strategy.process_splinters_at_impact(
						impact_position, 
						arrow, 
						body, 
						shooter.get_parent()  # A cena pai
					)
					break  # Apenas um alvo é suficiente	
	# Remove shadow - ensuring tween is interrupted first
	if shadow and is_instance_valid(shadow):
		# Interrupt tween (if it exists)
		if shadow.has_meta("tween"):
			var shadow_tween = shadow.get_meta("tween")
			if shadow_tween and is_instance_valid(shadow_tween):
				shadow_tween.kill()  # Stop tween
		shadow.queue_free()
	
	# Destroy arrow
	if arrow and is_instance_valid(arrow):
		arrow.queue_free()

# Método auxiliar para encontrar um inimigo na posição especificada
func find_enemy_at_position(position: Vector2, search_radius: float) -> Node:
	var current_scene = Engine.get_main_loop().current_scene
	if not current_scene:
		return null
		
	var space_state = current_scene.get_world_2d().direct_space_state
	
	# Configurar query de círculo
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = search_radius
	
	var query = PhysicsShapeQueryParameters2D.new()
	query.shape = circle_shape
	query.transform = Transform2D(0, position)
	query.collision_mask = 2  # Enemy layer
	query.collide_with_bodies = true
	
	var results = space_state.intersect_shape(query)
	
	# Retorna o primeiro inimigo válido encontrado
	for result in results:
		var body = result.collider
		if body and is_instance_valid(body) and body.is_in_group("enemies"):
			return body
	
	return null

# Apply direct damage to enemies in the impact area
func apply_damage_to_area(impact_position, damage_amount, is_crit, damage_type, arrow=null, collision_mask=2):
	print("Arrow Rain: Direct damage application at ", impact_position, " with damage ", damage_amount)
	
	# Find all bodies within the impact area
	# Use the current scene's world 2D instead of get_tree()
	var current_scene = Engine.get_main_loop().current_scene
	var space_state = current_scene.get_world_2d().direct_space_state
	
	# Create a circle shape for area detection
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = impact_radius
	
	var query = PhysicsShapeQueryParameters2D.new()
	query.shape = circle_shape
	query.transform = Transform2D(0, impact_position)
	query.collision_mask = collision_mask
	query.collide_with_bodies = true
	
	var results = space_state.intersect_shape(query)
	print("Arrow Rain: Direct area damage found ", results.size(), " potential targets")
	
	# Apply damage to each valid enemy
	var hits = 0
	for result in results:
		var body = result.collider
		
		if body and is_instance_valid(body) and body.has_node("HealthComponent"):
			var health = body.get_node("HealthComponent")
			print("Arrow Rain: Direct hit on: ", body.name, " with damage: ", damage_amount)
			
			# Try to apply full damage package if possible for elemental effects
			if arrow and arrow.has_method("get_damage_package"):
				var damage_package = arrow.get_damage_package()
				
				# If it's a critical hit, ensure the package reflects this
				if is_crit and not damage_package.get("is_critical", false):
					damage_package["is_critical"] = true
					damage_package["physical_damage"] = damage_amount  # Use pre-calculated critical damage
				
				print("Arrow Rain: Applying complex damage package with fire effects: ", damage_package)
				health.take_complex_damage(damage_package)
			else:
				# Fallback to basic damage if package isn't available
				health.take_damage(damage_amount, is_crit, damage_type)
			
			hits += 1
	
	print("Arrow Rain: Successfully applied direct damage to ", hits, " targets")
	return hits


# Creates a shadow at impact point
func create_shadow_at_impact(impact_position, parent_node):
	# Create shadow node
	var shadow = Node2D.new()
	shadow.name = "ImpactShadow"
	
	# Create shadow sprite as simple black circle
	var shadow_sprite = Sprite2D.new()
	
	# Create round black image
	var img = Image.create(16, 16, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))  # Initially transparent
	
	# Draw black circle
	for x in range(16):
		for y in range(16):
			# Normalized distance from center
			var dx = (x - 8) / 8.0
			var dy = (y - 8) / 8.0
			var dist = sqrt(dx*dx + dy*dy)
			
			# If inside circle
			if dist <= 1.0:
				# Intensity based on distance from center
				var alpha = 0.4 * (1.0 - dist)
				img.set_pixel(x, y, Color(0, 0, 0, alpha))
	
	# Create texture from image
	var texture = ImageTexture.create_from_image(img)
	shadow_sprite.texture = texture
	
	# Set shadow size
	shadow_sprite.scale = Vector2(0.8, 0.5)  # Larger oval shape
	
	# Add sprite to shadow
	shadow.add_child(shadow_sprite)
	
	# Position shadow
	shadow.global_position = impact_position
	
	# Adjust z_index to be below everything
	shadow.z_index = -10
	
	# Add shadow to scene
	parent_node.add_child(shadow)
	
	# Add "blink" effect with limited loops
	var tween = parent_node.create_tween()
	tween.tween_property(shadow_sprite, "modulate:a", 0.8, 0.2)
	tween.tween_property(shadow_sprite, "modulate:a", 0.3, 0.2)
	
	# Set specific number of loops (10 is more than enough)
	tween.set_loops(10)
	
	# Store tween reference in shadow node to be able to stop it later
	shadow.set_meta("tween", tween)
	
	return shadow

# Function to extend arrow's _physics_process
func add_custom_physics_process(arrow, impact_position, fall_time):
	# Create custom script to replace default behavior
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
		
		# Store original position for calculations
		if arrow.has_meta("impact_position"):
			impact_position = arrow.get_meta("impact_position")
		
		if arrow.has_meta("fall_time"):
			total_time = arrow.get_meta("fall_time")
			
		# Immediately set correct arrow direction
		var direction = (impact_position - start_position).normalized()
		arrow.direction = direction
		
		# Apply correct rotation at start
		# IMPORTANT: Arrow must point in direction of movement
		arrow.rotation = direction.angle()
		
		# Adjust any sprite offset if needed
		# This depends on how the arrow sprite is oriented
		# For an arrow that points right by default
		if direction.x < 0:
			# If arrow is going left
			arrow.get_node("Sprite2D").flip_h = true
	
	func _physics_process(delta):
		var arrow = get_parent()
		
		# Increment elapsed time
		elapsed_time += delta
		
		# Calculate progress percentage (0 to 1)
		var progress = min(elapsed_time / total_time, 1.0)
		
		# Linear interpolation of position
		var new_position = start_position.lerp(impact_position, progress)
		
		# Add arc effect for more natural movement
		var arc_height = start_position.distance_to(impact_position) * 0.05
		var arc_offset = sin(progress * PI) * arc_height
		
		# Apply arc offset to Y position
		new_position.y -= arc_offset
		
		# Update arrow position
		arrow.global_position = new_position
		
		# Calculate current direction based on next point in trajectory
		# Using a small offset to calculate direction tangent to curve
		var next_progress = min(progress + 0.01, 1.0)
		var next_position = start_position.lerp(impact_position, next_progress)
		
		# Add same arc effect to next point
		var next_arc_offset = sin(next_progress * PI) * arc_height
		next_position.y -= next_arc_offset
		
		# Calculate tangent direction
		var direction = (next_position - arrow.global_position).normalized()
		
		# Update direction and rotation only if direction is significant
		if direction.length() > 0.1:
			arrow.direction = direction
			arrow.rotation = direction.angle()
		
		# If destination reached, end movement
		if progress >= 1.0:
			# Arrow should be exactly at impact position
			arrow.global_position = impact_position
			set_physics_process(false)
	"""
	
	# Add script as child node
	var custom_processor = Node.new()
	custom_processor.name = "CustomPhysicsProcessor"
	custom_processor.set_script(custom_script)
	
	# Store important data as metadata
	arrow.set_meta("impact_position", impact_position)
	arrow.set_meta("fall_time", fall_time)
	
	arrow.add_child(custom_processor)
	
	# Disable original arrow physics processing
	arrow.set_physics_process(false)

# Check if this arrow was created from Arrow Rain to avoid recursion
func is_from_arrow_rain(projectile: Node) -> bool:
	if "tags" in projectile:
		if projectile.has_method("has_tag"):
			return projectile.has_tag("rain_arrow")
		else:
			for tag in projectile.tags:
				if tag == "rain_arrow":
					return true
	return false

# Spawn rain arrows above the target area
func spawn_rain_arrows(projectile: Node):
	var shooter = projectile.shooter
	if not shooter:
		print("Arrow Rain: No shooter found")
		return
	
	print("Arrow Rain: Starting to spawn arrows")
	
	# Verificar se o projétil original tem efeito de explosão (Talent 15)
	var has_explosion = projectile.has_meta("has_explosion_effect")
	var explosion_damage_percent = 0.5  # Valor padrão
	var explosion_radius = 35.0  # Valor padrão
	var explosion_strategy = null
	
	if has_explosion:
		print("Arrow Rain: Original projectile has explosion effect, propagating to rain arrows")
		
		# Copiar parâmetros da explosão
		if projectile.has_meta("explosion_damage_percent"):
			explosion_damage_percent = projectile.get_meta("explosion_damage_percent")
			
		if projectile.has_meta("explosion_radius"):
			explosion_radius = projectile.get_meta("explosion_radius")
			
		# Tenta obter a estratégia de explosão
		if projectile.has_meta("explosion_strategy"):
			var strategy_ref = projectile.get_meta("explosion_strategy")
			explosion_strategy = strategy_ref.get_ref() if strategy_ref is WeakRef else strategy_ref
	
	# Procurar o Talent 15 nas estratégias do arqueiro se não encontrou no projétil
	if not explosion_strategy and shooter and "attack_upgrades" in shooter:
		for upgrade in shooter.attack_upgrades:
			var script_path = upgrade.get_script().get_path()
			if script_path.find("Talent_15") >= 0 or (upgrade.has_method("get_strategy_name") and upgrade.get_strategy_name() == "Arrow Explosion"):
				print("Arrow Rain: Found Arrow Explosion strategy in archer's upgrades")
				explosion_strategy = upgrade
				has_explosion = true
				break
	
	if has_explosion and explosion_strategy:
		print("Arrow Rain: Will apply explosion effect to all rain arrows")
	
	# Get other strategies to apply (excluding Double Shot and Chain Shot)
	var other_strategies = []
	if "attack_upgrades" in shooter:
		for strategy in shooter.attack_upgrades:
			if not strategy is ArrowRainStrategy and not strategy is Talent_11 and not strategy is Talent_12:
				other_strategies.append(strategy)
	
	# Capture original projectile information
	var original_damage = projectile.damage if "damage" in projectile else damage_per_arrow
	var original_crit_chance = projectile.crit_chance if "crit_chance" in projectile else 0.1
	var original_tags = projectile.tags.duplicate() if "tags" in projectile else []
	
	# Capture damage calculator data
	var original_dmg_calc_data = {}
	if projectile.has_node("DmgCalculatorComponent"):
		var dmg_calc = projectile.get_node("DmgCalculatorComponent")
		original_dmg_calc_data = {
			"base_damage": dmg_calc.base_damage if "base_damage" in dmg_calc else original_damage,
			"elemental_damage": dmg_calc.elemental_damage if "elemental_damage" in dmg_calc else {},
			"dot_effects": dmg_calc.dot_effects if "dot_effects" in dmg_calc else []
		}
	
	# Define target position
	var target_position = Vector2.ZERO
	var target = null
	
	# Find the target
	if shooter.has_method("get_current_target"):
		target = shooter.get_current_target()
	elif "current_target" in shooter:
		target = shooter.current_target
	
	# Set target position
	if target and is_instance_valid(target):
		target_position = target.global_position
		print("Arrow Rain: Using target position: ", target_position)
	else:
		# Fallback: use projectile direction
		target_position = projectile.global_position + projectile.direction * 300
		print("Arrow Rain: Using fallback position: ", target_position)
	
	# Load arrow scene
	var arrow_scene = preload("res://Test/Projectiles/Archer/Arrow.tscn")
	if not arrow_scene:
		print("Arrow Rain: Error - Could not load arrow scene")
		return
	
	print("Arrow Rain: Spawning ", arrow_count, " arrows")
	
	for i in range(arrow_count):
		var arrow = arrow_scene.instantiate()
		
		# Fall position with dispersion
		var fall_position = target_position
		
		if arrow_count > 1:
			# Generate offset vector within a true circle
			var angle = randf() * TAU  # Full random angle
			var rand_radius = sqrt(randf()) * radius  # Uniform distribution within circle
			
			var random_offset = Vector2(
				cos(angle) * rand_radius,
				sin(angle) * rand_radius
			)
			
			fall_position += random_offset
		
		# IMPORTANT: Set impact position immediately
		var impact_position = fall_position
		
		# Create shadow at impact point
		var shadow = create_shadow_at_impact(impact_position, shooter.get_parent())
		
		# Initial spawn height
		var random_height = randf_range(min_height, max_height)
		
		# Initial position with random horizontal offset to vary fall angle
		var horizontal_offset = randf_range(-50, 50)
		arrow.global_position = Vector2(fall_position.x + horizontal_offset, fall_position.y - random_height)
		
		# Basic arrow settings
		arrow.damage = original_damage  # Use same damage as original arrow
		arrow.crit_chance = original_crit_chance
		# Calculate critical hit status at creation time
		arrow.is_crit = randf() < arrow.crit_chance
		if arrow.is_crit:
			print("Arrow Rain: Arrow ", i, " will be a critical hit!")
			# Note: Don't multiply damage here - let the damage system handle it
		
		arrow.shooter = shooter
		arrow.speed = 500.0  # Default speed, will be ignored by our custom system
		
		# Make sure damage is properly set in the DmgCalculator if it exists
		if arrow.has_node("DmgCalculatorComponent"):
			var dmg_calc = arrow.get_node("DmgCalculatorComponent")
			if original_dmg_calc_data and "base_damage" in original_dmg_calc_data:
				dmg_calc.base_damage = original_dmg_calc_data.base_damage
				
			# Make sure we're properly setting critical multiplier
			if "crit_multiplier" in dmg_calc:
				# If the original arrow has it, copy it
				if projectile.has_node("DmgCalculatorComponent"):
					var original_dmg_calc = projectile.get_node("DmgCalculatorComponent")
					if "crit_multiplier" in original_dmg_calc:
						dmg_calc.crit_multiplier = original_dmg_calc.crit_multiplier
				else:
					# Default to common standard
					dmg_calc.crit_multiplier = 2.0
		
		# Initial direction (will be replaced by custom movement system)
		var initial_direction = (impact_position - arrow.global_position).normalized()
		arrow.direction = initial_direction
		
		# Set initial rotation based on direction to impact point
		arrow.rotation = initial_direction.angle()
		
		# Add tag for identification
		if arrow.has_method("add_tag"):
			arrow.add_tag("rain_arrow")
		elif "tags" in arrow:
			if not "rain_arrow" in arrow.tags:
				arrow.tags.append("rain_arrow")
		else:
			arrow.set_meta("is_rain_arrow", true)
		
		print("Arrow Rain: Arrow ", i, " configured with damage: ", arrow.damage)
		
		# Transfer original tags
		if "tags" in arrow and typeof(arrow.tags) == TYPE_ARRAY:
			for tag in original_tags:
				if not tag in arrow.tags and arrow.has_method("add_tag"):
					arrow.add_tag(tag)
		
		# Set up damage calculator
		if arrow.has_node("DmgCalculatorComponent"):
			var dmg_calc = arrow.get_node("DmgCalculatorComponent")
			
			if original_dmg_calc_data:
				# Configure base damage using original values
				if "base_damage" in original_dmg_calc_data:
					dmg_calc.base_damage = original_dmg_calc_data.base_damage
				
				# Copy elemental damages
				var original_elemental_damage = original_dmg_calc_data.get("elemental_damage", {})
				if original_elemental_damage:
					for element in original_elemental_damage:
						dmg_calc.add_damage_modifier("elemental_damage", 
							{element: original_elemental_damage[element]})
				
				# Copy DoT effects
				var original_dot_effects = original_dmg_calc_data.get("dot_effects", [])
				for effect in original_dot_effects:
					# Configure DoT effects
					dmg_calc.add_dot_effect(
						effect.get("damage", 0),
						effect.get("duration", 3.0),
						effect.get("interval", 1.0),
						effect.get("type", "generic")
					)
		
		# IMPORTANT: Disable ALL arrow collisions
		
		# 1. Disable hurtbox
		if arrow.has_node("Hurtbox"):
			var hurtbox = arrow.get_node("Hurtbox")
			hurtbox.monitoring = false
			hurtbox.monitorable = false
		
		# 2. Disable CharacterBody2D collision
		if arrow is CharacterBody2D:
			# Temporarily disable all collisions
			arrow.collision_layer = 0
			arrow.collision_mask = 0
			
			# Disable all collisionshapes
			for child in arrow.get_children():
				if child is CollisionShape2D or child is CollisionPolygon2D:
					child.disabled = true
		
		# Calculate estimated time to impact based on distance
		var fall_distance = arrow.global_position.distance_to(impact_position)
		var fall_time = fall_distance / arrow.speed
		
		# Print debug info about the arrow's initial setup
		print("Arrow Rain: Arrow ", i, " setup: Position=", arrow.global_position, 
			  ", Target=", impact_position, 
			  ", Damage=", arrow.damage, 
			  ", Fall Time=", fall_time)
		
		# Aplicar efeito de explosão se necessário
		if has_explosion:
			print("Arrow Rain: Applying explosion effect to this arrow")
			arrow.set_meta("has_explosion_effect", true)
			arrow.set_meta("explosion_damage_percent", explosion_damage_percent)
			arrow.set_meta("explosion_radius", explosion_radius)
			
			# Associar estratégia de explosão
			if explosion_strategy:
				arrow.set_meta("explosion_strategy", weakref(explosion_strategy))
		
		# 3. Replace default physics with controlled movement that hits exactly the target
		add_custom_physics_process(arrow, impact_position, fall_time)
		
		# Apply other strategies (except ArrowRainStrategy, Double Shot and Chain Shot to avoid recursion)
		for strategy in other_strategies:
			if strategy and is_instance_valid(strategy):
				strategy.apply_upgrade(arrow)
		
		# Add to scene
		shooter.get_parent().add_child(arrow)
		print("Arrow Rain: Arrow ", i, " added to scene")
		
		# Create timer to apply damage in impact area when arrow "hits" ground
		var impact_timer = Timer.new()
		impact_timer.one_shot = true
		impact_timer.wait_time = fall_time
		impact_timer.name = "ImpactTimer"
		arrow.add_child(impact_timer)
		
		# Store key data directly in the arrow for safety
		arrow.set_meta("impact_position", impact_position)
		arrow.set_meta("damage_amount", arrow.damage)
		arrow.set_meta("is_crit", arrow.is_crit)
		
		# Weak references to avoid lambda captures that cause errors
		var arrow_ref = weakref(arrow)
		var shadow_ref = weakref(shadow)
		var shooter_ref = weakref(shooter)
		var this_ref = weakref(self)  # Reference to this strategy
		
		impact_timer.timeout.connect(func():
			var arrow_inst = arrow_ref.get_ref()
			var shadow_inst = shadow_ref.get_ref()
			var shooter_inst = shooter_ref.get_ref()
			var strategy = this_ref.get_ref()
			
			print("Arrow Rain: Impact timer triggered")
			
			# Even if arrow is lost, try to apply damage directly
			if strategy and arrow_inst:
				# Get the correct damage amount
				var damage = arrow_inst.get_meta("damage_amount")
				var is_crit_hit = arrow_inst.get_meta("is_crit")
				
				# Calculate damage including critical if needed
				if is_crit_hit:
					var crit_mult = 2.0
					if arrow_inst.has_node("DmgCalculatorComponent"):
						var dmg_calc = arrow_inst.get_node("DmgCalculatorComponent")
						if "crit_multiplier" in dmg_calc:
							crit_mult = dmg_calc.crit_multiplier
					damage = int(damage * crit_mult)
					print("Arrow Rain: Critical hit in timer! Damage: ", damage)
				
				var direct_hit = strategy.apply_damage_to_area(
					impact_position, 
					damage,
					is_crit_hit, 
					"arrow_rain",
					arrow_inst
				)
				print("Arrow Rain: Applied direct area damage with result: ",direct_hit)
			
			# Handle arrow and shadow if they still exist
			if arrow_inst and shadow_inst and shooter_inst:
				on_arrow_impact(impact_position, arrow_inst, shadow_inst, shooter_inst)
			else:
				print("Arrow Rain: Some references were lost - arrow:", arrow_inst != null, 
					  ", shadow:", shadow_inst != null, 
					  ", shooter:", shooter_inst != null)
				
				# Remove shadow if it still exists
				if shadow_inst:
					if shadow_inst.has_meta("tween"):
						var tween = shadow_inst.get_meta("tween")
						if tween and is_instance_valid(tween):
							tween.kill()
					shadow_inst.queue_free()
				
				# Remove arrow if it still exists
				if arrow_inst:
					arrow_inst.queue_free()
			
			# Timer self-cleanup
			impact_timer.queue_free()
		)
		impact_timer.start()
		
		# Add additional timer to destroy arrow for safety
		var destroy_timer = Timer.new()
		destroy_timer.one_shot = true
		destroy_timer.wait_time = fall_time + 0.5
		arrow.add_child(destroy_timer)
		
		destroy_timer.timeout.connect(func():
			var arrow_inst = arrow_ref.get_ref()
			if arrow_inst:
				_on_destroy_timer_timeout(arrow_inst)
				
			# Timer self-cleanup
			destroy_timer.queue_free()
		)
		destroy_timer.start()
	
	print("Arrow Rain: All arrows spawned successfully")

# Main upgrade application method
func apply_upgrade(projectile: Node) -> void:
	print("Talent_13 Arrow Rain strategy called for projectile")
	
	# Skip if projectile is from Double Shot's second arrow or rain arrow
	if projectile.has_meta("is_second_arrow") or is_from_arrow_rain(projectile):
		print("Skipping Arrow Rain application - projectile is either a second arrow or already a rain arrow")
		return
		
	# Get shooter to track attack counter
	var shooter = projectile.shooter
	if not shooter:
		print("Arrow Rain: No shooter found for projectile")
		return
		
	# Initialize counter for this shooter if not exists
	if not shooter in attack_counter:
		attack_counter[shooter] = 0
		print("Arrow Rain: Initializing attack counter for shooter")
		
	# Increment attack counter
	attack_counter[shooter] += 1
	print("Arrow Rain: Attack counter for shooter is now ", attack_counter[shooter], "/", attacks_threshold)
	
	# Debug: Force trigger rain immediately for testing purposes
	var should_trigger = (attack_counter[shooter] >= attacks_threshold)
	if Engine.is_editor_hint():
		# Uncomment this line to force trigger arrow rain on every shot during debugging
		# should_trigger = true
		pass
	
	# Check if it's time to spawn rain arrows
	if should_trigger:
		# Reset counter
		attack_counter[shooter] = 0
		print("Arrow Rain: TRIGGERING ARROW RAIN!")
		
		# Spawn rain arrows
		spawn_rain_arrows(projectile)
		
		# Add a visual indicator or effect to show Arrow Rain activation
		var effect = create_rain_activation_effect(shooter)
		if effect:
			shooter.get_parent().add_child(effect)

# Creates a visual effect to indicate Arrow Rain activation
func create_rain_activation_effect(shooter):
	# Create visual flourish for ability activation
	print("Creating Arrow Rain activation effect")
	
	if not shooter:
		return null
	
	# Create a Node2D for the effect
	var effect = Node2D.new()
	effect.name = "ArrowRainActivation"
	effect.global_position = shooter.global_position + Vector2(0, -50)  # Above the shooter
	
	# Create text label
	var label = Label.new()
	label.text = "ARROW RAIN!"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	# Style the label
	var font = label.get_theme_default_font()
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))
	label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0))
	label.add_theme_constant_override("outline_size", 2)
	
	# Add to effect node
	effect.add_child(label)
	
	# Create animation
	var tween = effect.create_tween()
	tween.tween_property(label, "position:y", -30, 0.5).from(0)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.5).from(1.0)
	tween.tween_callback(effect.queue_free)
	
	return effect

# Name for debug panel
func get_strategy_name() -> String:
	return "Arrow Rain"
