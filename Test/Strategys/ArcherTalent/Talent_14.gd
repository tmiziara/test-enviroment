extends BaseProjectileStrategy
class_name Talent_14

# Splinter Arrows parameters
@export var splinter_count: int = 2            # Number of mini-arrows created
@export var splinter_damage_percent: float = 0.25  # Damage as percentage of original arrow
@export var splinter_range: float = 100.0     # Range to search for secondary targets
@export var talent_id: int = 14               # ID for this talent in the talent tree

# Name for debug panel
func get_strategy_name() -> String:
	return "Splinter Arrows"

# This function enhances Arrow Rain functionality
func apply_upgrade(projectile: Node) -> void:
	print("Applying Splinter Arrows upgrade - Arrows will splinter on impact!")
	
	# Skip if projectile is from splinter to avoid recursion
	if projectile.has_meta("is_splinter"):
		print("Skipping Splinter Arrows for splinter arrow")
		return
	
	# SPECIAL HANDLING: Check if this is a regular arrow being shot. If so, we need to
	# grab a reference to the archer and register our strategy with the Arrow Rain strategy
	# to make it apply splinter effect to all rain arrows it creates
	if projectile is ProjectileBase and projectile.shooter and not projectile.has_meta("is_rain_arrow"):
		var shooter = projectile.shooter
		
		# Check if the shooter has attack_upgrades
		if "attack_upgrades" in shooter:
			# Look for the Arrow Rain strategy
			for strategy in shooter.attack_upgrades:
				var script_path = strategy.get_script().get_path()
				if script_path.find("Talent_13") >= 0:
					print("Found Arrow Rain strategy in archer's upgrades")
					# Register our splinter strategy with Arrow Rain
					strategy.set_meta("splinter_strategy", self)
					strategy.set_meta("enable_splinters", true)
					print("Registered splinter strategy with Arrow Rain - all rain arrows will now splinter on impact")
	
	# Skip if projectile is from Double Shot's second arrow
	if projectile.has_meta("is_second_arrow"):
		print("Skipping Splinter Arrows for second shot arrow")
		return
		
	# Skip if this is not an arrow or doesn't have required properties
	if not "damage" in projectile:
		print("Cannot apply Splinter Arrows to incompatible projectile")
		return
		
	# Check if arrow already has splinter property to avoid duplicating
	if "has_splinter_effect" in projectile or projectile.has_meta("has_splinter_effect"):
		print("Splinter effect already applied to this arrow")
		return
		
	# Add tag to arrow for identification
	if "tags" in projectile and projectile.has_method("add_tag"):
		projectile.add_tag("splinter")
	elif "tags" in projectile:
		if not "splinter" in projectile.tags:
			projectile.tags.append("splinter")

	# Mark arrow as having splinter effect
	projectile.set_meta("has_splinter_effect", true)
	
	# Store splinter parameters in arrow for later use
	projectile.set_meta("splinter_count", splinter_count)
	projectile.set_meta("splinter_damage_percent", splinter_damage_percent)
	projectile.set_meta("splinter_range", splinter_range)
	projectile.set_meta("splinter_strategy", self)
	
	# If this is a rain arrow, we need to enhance its impact behavior
	enhance_arrow_impact(projectile)

# Enhances an arrow with splinter functionality
func enhance_arrow_impact(arrow: Node) -> void:
	# For Arrow Rain arrows, we need to intercept their impact
	if arrow is Arrow:
		# Check if it's from Arrow Rain specifically
		var is_rain_arrow = false
		if "tags" in arrow:
			for tag in arrow.tags:
				if tag == "rain_arrow":
					is_rain_arrow = true
					break
		
		if is_rain_arrow:
			print("Enhancing Arrow Rain arrow with splinter effect")
			
			# Store reference to self - needed for when hit happens
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
						# Only process our own splinter effect if it's the right arrow
						if projectile == arrow and is_instance_valid(target):
							# Get self reference to access methods
							var strategy = self_ref.get_ref()
							if strategy:
								# Create splinters after hit
								strategy.create_splinters(arrow, target)
					)
					print("Connected to arrow's on_hit signal")
				else:
					print("Already connected to on_hit signal")
			else:
				# Alternative approach: use a meta property and hook into the Arrow's process_on_hit method
				arrow.set_meta("splinter_strategy", self_ref)
				print("Added splinter_strategy reference to arrow for lookup during hit")
	else:
		# For Arrow Rain arrows without Arrow class, we need to enhance their impact
		# Check if it's tagged as a rain arrow
		var is_rain_arrow = false
		if "tags" in arrow:
			for tag in arrow.tags:
				if tag == "rain_arrow":
					is_rain_arrow = true
					break
					
		if is_rain_arrow:
			print("Non-Arrow rain arrow with splinter effect (impact events not accessible)")
			# In this case we might need to set up metadata for the arrow to use
			arrow.set_meta("create_splinters_on_impact", true)
			arrow.set_meta("splinter_strategy", weakref(self))
		else:
			print("Not a rain arrow, splinter effect may not apply")

# Creates splinter arrows from impact position
func create_splinters(arrow: Node, hit_target: Node) -> void:
	print("Creating splinters from arrow impact!")
	
	# Essential safety checks
	if not is_instance_valid(arrow) or not is_instance_valid(hit_target):
		print("Invalid arrow or target for splinter creation")
		return
		
	# Get parent scene to add splinters to
	var parent_scene = arrow.get_parent()
	if not parent_scene:
		print("No parent scene to add splinters to")
		return
		
	# Get arrow data from metadata
	var splinter_count = arrow.get_meta("splinter_count", 2)
	var splinter_damage_percent = arrow.get_meta("splinter_damage_percent", 0.25)
	var splinter_range = arrow.get_meta("splinter_range", 100.0)
	
	# Calculate damage for mini-arrows (25% of original)
	var splinter_damage = int(arrow.damage * splinter_damage_percent)
	if splinter_damage < 1:
		splinter_damage = 1  # Ensure minimum damage of 1
		
	# Get shooter for proper attribution
	var shooter = arrow.shooter
	
	# Get all potential targets within range
	var potential_targets = find_nearby_targets(hit_target.global_position, hit_target, splinter_range)
	
	# If no targets found, no need to create splinters
	if potential_targets.size() == 0:
		print("No nearby targets for splinters")
		return
		
	print("Found", potential_targets.size(), "potential targets for splinters")
	
	# Track how many splinters we've created
	var splinters_created = 0
	
	# Create mini-arrows (splinters) to target nearby enemies
	for target in potential_targets:
		# Stop if we've reached the maximum splinter count
		if splinters_created >= splinter_count:
			break
			
		# Create visual splinter effect and apply damage
		create_splinter_effect(
			arrow.global_position,
			target.global_position,
			splinter_damage,
			parent_scene,
			shooter,
			arrow
		)
		
		splinters_created += 1

# Additional method to be called directly from Arrow Rain's on_arrow_impact
func process_splinters_at_impact(impact_position: Vector2, arrow: Node, target: Node, parent_scene: Node) -> void:
	print("Processing splinters at impact point")
	
	# If arrow doesn't have damage property, we can't create splinters
	if not "damage" in arrow:
		print("Arrow doesn't have damage property, can't create splinters")
		return
		
	# Calculate damage for mini-arrows (25% of original)
	var splinter_damage = int(arrow.damage * splinter_damage_percent)
	if splinter_damage < 1:
		splinter_damage = 1
		
	# Get shooter for proper attribution
	var shooter = arrow.shooter if "shooter" in arrow else null
	
	# Get all potential targets within range
	var potential_targets = find_nearby_targets(impact_position, target, splinter_range)
	
	# If no targets found, no need to create splinters
	if potential_targets.size() == 0:
		print("No nearby targets for splinters at impact point")
		return
		
	print("Found", potential_targets.size(), "potential targets for splinters at impact")
	
	# Track how many splinters we've created
	var splinters_created = 0
	
	# Create mini-arrows (splinters) to target nearby enemies
	for potential_target in potential_targets:
		# Stop if we've reached the maximum splinter count
		if splinters_created >= splinter_count:
			break
			
		# Create visual splinter effect and apply damage
		create_splinter_effect(
			impact_position,
			potential_target.global_position,
			splinter_damage,
			parent_scene,
			shooter,
			arrow
		)
		
		splinters_created += 1

# Creates the visual effect and applies damage
func create_splinter_effect(from_pos: Vector2, to_pos: Vector2, damage: int, parent_scene: Node, shooter: Node, source_arrow: Node) -> void:
	# Create a visual splinter projectile
	var splinter = Line2D.new()
	splinter.name = "SplinterEffect"
	splinter.points = [Vector2.ZERO, to_pos - from_pos]
	splinter.width = 2.0
	splinter.default_color = Color(1.0, 0.8, 0.2, 0.8)  # Yellow-orange
	splinter.position = from_pos
	
	# Add to scene
	parent_scene.add_child(splinter)
	
	# Create fade animation
	var tween = splinter.create_tween()
	tween.tween_property(splinter, "modulate", Color(1, 1, 1, 0), 0.3)
	tween.tween_callback(splinter.queue_free)
	
	# Apply damage to target
	var target = get_node_at_position(to_pos, parent_scene)
	if target and target.has_node("HealthComponent"):
		var health_component = target.get_node("HealthComponent")
		
		# Try to construct similar damage package as original arrow
		var is_crit = source_arrow.is_crit if "is_crit" in source_arrow else false
		
		if source_arrow.has_node("DmgCalculatorComponent"):
			# Copy damage structure with reduced value
			var dmg_calc = source_arrow.get_node("DmgCalculatorComponent")
			var damage_package = {
				"physical_damage": damage,
				"is_critical": is_crit,
				"elemental_damage": {},
				"armor_penetration": 0.0
			}
			
			# Get armor penetration if available
			if "armor_penetration" in dmg_calc:
				damage_package["armor_penetration"] = dmg_calc.armor_penetration
			
			# Copy elemental damage if any (also at reduced percentage)
			if "elemental_damage" in dmg_calc:
				for element in dmg_calc.elemental_damage:
					# Get splinter damage percent with proper default
					var splinter_percent = 0.25
					if source_arrow.has_meta("splinter_damage_percent"):
						splinter_percent = source_arrow.get_meta("splinter_damage_percent")
					
					damage_package["elemental_damage"][element] = int(dmg_calc.elemental_damage[element] * splinter_percent)
			
			# Apply damage
			health_component.take_complex_damage(damage_package)
		else:
			# Fallback to basic damage
			health_component.take_damage(damage, is_crit, "splinter")
		
		# Create hit effect
		create_hit_effect(to_pos, parent_scene)
		
	# NOVA PARTE: Criar uma flecha real com os mesmos buffs para aplicações avançadas
	if shooter and is_instance_valid(shooter) and "attack_upgrades" in shooter:
		create_physical_splinter_arrow(from_pos, to_pos, damage, parent_scene, shooter, source_arrow)

# Cria uma flecha física com os mesmos buffs do arqueiro
func create_physical_splinter_arrow(from_pos: Vector2, to_pos: Vector2, damage: int, parent_scene: Node, shooter: Node, source_arrow: Node) -> void:
	# Não criamos flechas reais para alvos mortos ou inválidos
	var target = get_node_at_position(to_pos, parent_scene)
	if not target or not is_instance_valid(target):
		return
		
	# Carrega a cena da flecha
	var arrow_scene = load("res://Test/Projectiles/Archer/Arrow.tscn")
	if not arrow_scene:
		print("Splinter Arrows: Não foi possível carregar a cena da flecha")
		return
		
	# Instancia a flecha
	var splinter_arrow = arrow_scene.instantiate()
	
	# Configura posição
	splinter_arrow.global_position = from_pos
	
	# Define direção para o alvo
	var direction = (to_pos - from_pos).normalized()
	splinter_arrow.direction = direction
	splinter_arrow.rotation = direction.angle()
	
	# Transfere propriedades básicas
	splinter_arrow.damage = damage
	splinter_arrow.crit_chance = source_arrow.crit_chance if "crit_chance" in source_arrow else 0.1
	splinter_arrow.is_crit = source_arrow.is_crit if "is_crit" in source_arrow else false
	splinter_arrow.shooter = shooter
	splinter_arrow.speed = 600.0  # Ligeiramente mais rápida que flechas normais
	
	# Adiciona tag para identificação
	if splinter_arrow.has_method("add_tag"):
		splinter_arrow.add_tag("splinter")
		
	# Marca como fragmento para evitar aplicação recursiva
	splinter_arrow.set_meta("is_splinter", true)
	
	# Se tiver DmgCalculator, copia as configurações relevantes
	if splinter_arrow.has_node("DmgCalculatorComponent") and source_arrow.has_node("DmgCalculatorComponent"):
		var src_dmg_calc = source_arrow.get_node("DmgCalculatorComponent")
		var dst_dmg_calc = splinter_arrow.get_node("DmgCalculatorComponent")
		
		# Copia dano base ajustado
		if "base_damage" in src_dmg_calc:
			dst_dmg_calc.base_damage = damage  # Já calculado com a redução
			
		# Copia penetração de armadura
		if "armor_penetration" in src_dmg_calc:
			dst_dmg_calc.armor_penetration = src_dmg_calc.armor_penetration
			
		# Copia multiplicador de dano
		if "damage_multiplier" in src_dmg_calc:
			dst_dmg_calc.damage_multiplier = src_dmg_calc.damage_multiplier
			
		# Copia danos elementais
		if "elemental_damage" in src_dmg_calc:
			for element in src_dmg_calc.elemental_damage:
				var elem_dmg = int(src_dmg_calc.elemental_damage[element] * 0.25)  # 25% do dano
				if elem_dmg > 0:
					if not "elemental_damage" in dst_dmg_calc:
						dst_dmg_calc.elemental_damage = {}
					dst_dmg_calc.elemental_damage[element] = elem_dmg
					
		# Copia efeitos DoT
		if "dot_effects" in src_dmg_calc:
			for effect in src_dmg_calc.dot_effects:
				# Reduz o dano do DoT pela mesma proporção
				var dot_dmg = int(effect.get("damage", 0) * 0.25)
				if dot_dmg > 0:
					dst_dmg_calc.add_dot_effect(
						dot_dmg,
						effect.get("duration", 3.0),
						effect.get("interval", 1.0),
						effect.get("type", "generic")
					)
	
	# Aplica upgrades do arqueiro (exceto os talentos especificados)
	if "attack_upgrades" in shooter:
		for strategy in shooter.attack_upgrades:
			# Verifica se não é um dos talentos excluídos
			var strategy_path = strategy.get_script().get_path()
			var is_excluded = false
			
			if strategy_path.find("Talent_11") >= 0 or strategy_path.find("Talent_12") >= 0 or strategy_path.find("Talent_13") >= 0 or strategy_path.find("Talent_14") >= 0:
				is_excluded = true
				
			if not is_excluded:
				strategy.apply_upgrade(splinter_arrow)
	
	# Adiciona à cena
	parent_scene.add_child(splinter_arrow)
	
	# Configura um timer para autodestruição caso não atinja nada
	var timeout = Timer.new()
	timeout.wait_time = 0.6  # Reduzido para 0.6 segundos conforme solicitado
	timeout.one_shot = true
	splinter_arrow.add_child(timeout)
	timeout.timeout.connect(func(): splinter_arrow.queue_free())
	timeout.start()

# Finds nearby enemy targets
func find_nearby_targets(origin: Vector2, original_target: Node, max_range: float) -> Array:
	var targets = []
	
	# Get physics space
	var space_state = original_target.get_world_2d().direct_space_state
	
	# Configure circle shape for query
	var query = PhysicsShapeQueryParameters2D.new()
	var shape = CircleShape2D.new()
	shape.radius = max_range
	query.shape = shape
	query.transform = Transform2D(0, origin)
	query.collision_mask = 2  # Enemy layer (adjust if needed)
	
	# Execute query
	var results = space_state.intersect_shape(query)
	
	# Filter results
	for result in results:
		var body = result.collider
		
		# Skip invalid bodies and the original target
		if not is_instance_valid(body) or body == original_target:
			continue
			
		# Only include enemies with health component
		if body.is_in_group("enemies") and body.has_node("HealthComponent"):
			targets.append(body)
	
	return targets

# Utility to find node at position
func get_node_at_position(position: Vector2, parent_scene: Node) -> Node:
	# Simple approach - this assumes we already found this target in find_nearby_targets
	# and we're just using the position to identify which target it is
	var closest_node = null
	var closest_dist = 100.0  # Maximum distance to consider
	
	# Find enemies in scene
	var enemies = []
	for child in parent_scene.get_children():
		if child.is_in_group("enemies"):
			enemies.append(child)
	
	# Find closest enemy to position
	for enemy in enemies:
		var dist = enemy.global_position.distance_to(position)
		if dist < closest_dist:
			closest_dist = dist
			closest_node = enemy
	
	return closest_node

# Creates a hit effect at impact point
func create_hit_effect(position: Vector2, parent: Node) -> void:
	# Create a particle-like effect using a CPUParticles2D
	var effect = Node2D.new()
	effect.name = "SplinterHitEffect"
	effect.position = position
	parent.add_child(effect)
	
	# Create sprite for effect
	var sprite = Sprite2D.new()
	
	# Create a simple circular texture
	var img = Image.create(16, 16, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))  # Initially transparent
	
	# Draw a colored circle
	for x in range(16):
		for y in range(16):
			var dx = (x - 8) / 8.0
			var dy = (y - 8) / 8.0
			var dist = sqrt(dx*dx + dy*dy)
			
			if dist <= 1.0:
				var alpha = 0.8 * (1.0 - dist)
				img.set_pixel(x, y, Color(1.0, 0.7, 0.0, alpha))
	
	# Create texture
	var texture = ImageTexture.create_from_image(img)
	sprite.texture = texture
	effect.add_child(sprite)
	
	# Animate and remove
	var tween = effect.create_tween()
	tween.tween_property(sprite, "scale", Vector2(0.5, 0.5), 0.2).from(Vector2(1.2, 1.2))
	tween.parallel().tween_property(sprite, "modulate:a", 0.0, 0.2)
	tween.tween_callback(effect.queue_free)
