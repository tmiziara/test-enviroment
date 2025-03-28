extends NewProjectileBase
class_name NewArrow

# Arrow Storm properties
var arrow_storm_enabled: bool = false
var arrow_storm_trigger_chance: float = 0.1
var arrow_storm_additional_arrows: int = 2
var arrow_storm_spread_angle: float = 30.0

# Method to configure Arrow Storm
func configure_arrow_storm(is_enabled: bool, trigger_chance: float, additional_arrows: int, spread_angle: float) -> void:
	arrow_storm_enabled = is_enabled
	arrow_storm_trigger_chance = trigger_chance
	arrow_storm_additional_arrows = additional_arrows
	arrow_storm_spread_angle = spread_angle
	
# Focused Shot properties
var focused_shot_enabled: bool = false
var focused_shot_bonus: float = 0.0
var focused_shot_threshold: float = 0.75  # Default 75%

# Method to configure Focused Shot
func configure_focused_shot(is_enabled: bool, bonus: float, threshold: float = 0.75) -> void:
	focused_shot_enabled = is_enabled
	focused_shot_bonus = bonus
	focused_shot_threshold = threshold

# Chain Shot properties
var chain_shot_enabled: bool = false
var chain_chance: float = 0.3        # 30% chance to ricochet
var chain_range: float = 150.0       # Maximum range for finding targets
var chain_damage_decay: float = 0.2  # 20% damage reduction for chained hit
var max_chains: int = 1              # Maximum number of ricochets
var current_chains: int = 0          # Current number of ricochet jumps performed
var hit_targets = []                 # Array to track which targets we've hit
var is_processing_ricochet: bool = false  # Flag to prevent multiple hits during ricochet
var will_chain: bool = false         # Flag to store if this arrow will chain
var chain_calculated: bool = false   # Flag to track if chain chance has been calculated

func _ready():
	# If this is a pooled arrow being reused, skip standard initialization
	if is_pooled() and has_meta("initialized"):
		return
		
	super._ready()
	
	# Initialize hit_targets array if not already done
	if not hit_targets:
		hit_targets = []
		
	# Mark as initialized for pooled objects
	if is_pooled():
		set_meta("initialized", true)

# Override get_damage_package to handle special arrow effects
func get_damage_package() -> Dictionary:
	# Log the current damage values for debugging
	print("NewArrow.get_damage_package - Current damage: " + str(damage))
	# Call parent's method to create base damage package
	var damage_package = super.get_damage_package()
	# Log the package for debugging
	print("Base damage package: " + str(damage_package))
	# Find current target for effects
	var current_target = null
	if has_meta("current_target"):
		current_target = get_meta("current_target")
	elif shooter and shooter.has_method("get_current_target"):
		current_target = shooter.get_current_target()
	
	# Process Focused Shot if enabled via metadata
	if has_meta("focused_shot_enabled") and current_target and is_instance_valid(current_target):
		damage_package = apply_focused_shot_bonus(damage_package, current_target)
	
	# Process Marked for Death effect for critical hits
	if current_target and is_instance_valid(current_target) and damage_package.get("is_critical", false):
		damage_package = apply_mark_bonus(damage_package, current_target)
		
	print("Final damage package: " + str(damage_package))
	return damage_package
	
# Apply Focused Shot bonus to damage package
func apply_focused_shot_bonus(damage_package: Dictionary, target: Node) -> Dictionary:
	# Use metadata to get Focused Shot parameters
	if not has_meta("focused_shot_enabled") or not target.has_node("HealthComponent"):
		return damage_package
	
	var health_component = target.get_node("HealthComponent")
	
	# Get Focused Shot parameters from metadata
	var focused_shot_threshold = get_meta("focused_shot_threshold", 0.75)
	var focused_shot_bonus = get_meta("focused_shot_bonus", 0.3)
	
	# Check if target meets health threshold
	var health_percent = float(health_component.current_health) / health_component.max_health
	if health_percent >= focused_shot_threshold:
		# Apply bonus to physical damage
		if "physical_damage" in damage_package:
			var bonus_physical = int(damage_package["physical_damage"] * focused_shot_bonus)
			damage_package["physical_damage"] += bonus_physical
			print("Focused Shot: Physical damage increased by ", bonus_physical)
		
		# Apply to elemental damage
		if "elemental_damage" in damage_package:
			for element in damage_package["elemental_damage"]:
				var bonus_elem = int(damage_package["elemental_damage"][element] * focused_shot_bonus)
				damage_package["elemental_damage"][element] += bonus_elem
				print("Focused Shot: Elemental damage for ", element, " increased by ", bonus_elem)
		
		# Add tag
		if "tags" not in damage_package:
			damage_package["tags"] = []
		if "focused_shot" not in damage_package["tags"]:
			damage_package["tags"].append("focused_shot")
	
	return damage_package

# Apply Mark for Death bonus to critical hits
func apply_mark_bonus(damage_package: Dictionary, target: Node) -> Dictionary:
	# Check if target has mark debuff
	var has_mark = false
	var mark_bonus = 1.0
	
	if target.has_node("DebuffComponent"):
		var debuff_component = target.get_node("DebuffComponent")
		has_mark = debuff_component.has_debuff(GlobalDebuffSystem.DebuffType.MARKED_FOR_DEATH)
		
		if has_mark:
			# Get mark bonus from target
			mark_bonus = target.get_meta("mark_crit_bonus", 1.0)
			
			# Apply bonus to physical damage
			var base_crit_damage = damage_package["physical_damage"]
			var bonus_damage = int(base_crit_damage * mark_bonus)
			damage_package["physical_damage"] += bonus_damage
			
			# Apply to elemental damage
			if "elemental_damage" in damage_package:
				for element in damage_package["elemental_damage"]:
					var base_elem_crit = damage_package["elemental_damage"][element]
					var bonus_elem = int(base_elem_crit * mark_bonus)
					damage_package["elemental_damage"][element] += bonus_elem
			
			# Set damage type
			damage_package["damage_type"] = "marked_for_death"
	
	return damage_package

# Override the process_on_hit method for advanced arrow functionality
func process_on_hit(target: Node) -> void:
	print("Arrow process_on_hit called")
	print("Pooled status: ", is_pooled())
	print("Shooter: ", shooter)
	print("Piercing: ", piercing)
	
	# Variável para controlar destruição da flecha
	var should_destroy = true
	
	# Define o alvo atual para cálculos de dano
	set_meta("current_target", target)
	
	# Se já estiver processando um ricochet, ignora este hit
	if is_processing_ricochet:
		print("Already processing ricochet - ignoring hit")
		return
	
	# Adiciona o alvo à lista de alvos atingidos
	if not target in hit_targets:
		hit_targets.append(target)
	
	# Calcula e aplica dano
	if target.has_node("HealthComponent"):
		var health_component = target.get_node("HealthComponent")
		
		# Obtém o pacote de dano específico para este alvo
		var damage_package = get_damage_package()
		
		# Processa efeitos DoT de flechas de fogo
		if has_node("DmgCalculatorComponent"):
			var dmg_calc = get_node("DmgCalculatorComponent")
			
			# Aplica DoT de fogo se configurado
			if dmg_calc.has_meta("fire_dot_data"):
				var dot_data = dmg_calc.get_meta("fire_dot_data")
				var dot_chance = dot_data.get("chance", 0.0)
				
				# Rola para chance de DoT
				if randf() <= dot_chance:
					if "dot_effects" not in damage_package:
						damage_package["dot_effects"] = []
					
					# Adiciona efeito DoT
					damage_package["dot_effects"].append({
						"damage": dot_data.get("damage_per_tick", 1),
						"duration": dot_data.get("duration", 3.0),
						"interval": dot_data.get("interval", 0.5),
						"type": dot_data.get("type", "fire")
					})
		
		# Aplica dano com o pacote completo
		health_component.take_complex_damage(damage_package)
	
	# Emite sinal para sistemas de talentos
	emit_signal("on_hit", target, self)
	
	# Processa efeitos de talentos
	process_talent_effects(target)
	
	# Verifica Chain Shot
	if chain_shot_enabled and current_chains < max_chains:
		print("Chain shot enabled and can ricochet")
		if not chain_calculated:
			var roll = randf()
			will_chain = (roll <= chain_chance)
			chain_calculated = true
		
		if will_chain:
			print("Arrow will chain")
			is_processing_ricochet = true
			call_deferred("find_chain_target", target)
			should_destroy = false  # Permite que a flecha continue
	
	# Verifica Piercing
	if piercing:
		print("Piercing enabled")
		var current_pierce_count = hit_targets.size() - 1
		var max_pierce = 1
		
		if has_meta("piercing_count"):
			max_pierce = get_meta("piercing_count")
			
		print("Pierce count: ", current_pierce_count, "/", max_pierce)    
		if current_pierce_count < max_pierce:
			# Prepara para próximo hit
			if has_node("Hurtbox"):
				var hurtbox = get_node("Hurtbox")
				# Usa set_deferred para evitar erros de bloqueio
				hurtbox.set_deferred("monitoring", true)
				hurtbox.set_deferred("monitorable", true)
			
			# Move a flecha ligeiramente para frente para evitar ficar preso
			global_position += direction * 10
			
			# Mantém a velocidade e direção originais
			velocity = direction * speed
			
			should_destroy = false  # Permite que a flecha continue
		else:
			print("Max pierce count reached")
	
	# Destruição final
	if should_destroy:
		print("Arrow should be destroyed")
		
		# Desabilita física e visibilidade
		set_physics_process(false)
		visible = false
		
		# Desabilita colisões usando set_deferred
		if has_node("Hurtbox"):
			var hurtbox = get_node("Hurtbox")
			hurtbox.set_deferred("monitoring", false)
			hurtbox.set_deferred("monitorable", false)
		
		set_deferred("collision_layer", 0)
		set_deferred("collision_mask", 0)
		velocity = Vector2.ZERO
		
		# Retorna ao pool com pequeno delay
		if is_pooled():
			print("Returning to pool")
			get_tree().create_timer(0.1).timeout.connect(func():
				return_to_pool()
			)
		else:
			print("Queuing free")
			queue_free()

# Process effects from talents that trigger on hit
func process_talent_effects(target: Node) -> void:
	print("Processing Talent Effects")
	
	# Process bleeding effect on critical hit
	if is_crit and has_meta("has_bleeding_effect") and target.has_node("HealthComponent"):
		print("Critical hit + bleeding effect detected - applying bleeding")
		apply_bleeding_effect(target, self)
	else:
		print("Conditions for bleeding not met")
		
	# Process splinter effect
	if has_meta("has_splinter_effect"):
		print("Splinter effect detected - processing splinters")
		process_splinter_effect(target)
	
	# Process explosion effect
	if has_meta("has_explosion_effect"):
		print("Explosion effect detected - processing explosion")
		process_explosion_effect(target)
	else:
		print("Bleeding not applied. Conditions:")
		print("- Is Critical: ", is_crit)
		print("- Has Bleeding Effect Meta: ", has_meta("has_bleeding_effect"))
		print("- Target has HealthComponent: ", target.has_node("HealthComponent"))
		
# Método para aplicar efeito de sangramento
func apply_bleeding_effect(target: Node, projectile: Node) -> void:
	# Log de diagnóstico
	print("Aplicando efeito de sangramento")
	print("Projétil é crítico: ", projectile.is_crit)
	
	# Verifica se o alvo tem HealthComponent
	if not target.has_node("HealthComponent"):
		print("Alvo não tem HealthComponent")
		return
	
	var health_component = target.get_node("HealthComponent")
	
	# Obtém os metadados diretamente do projétil
	var damage_percent = projectile.get_meta("bleeding_damage_percent", 0.3)
	var duration = projectile.get_meta("bleeding_duration", 4.0)
	var interval = projectile.get_meta("bleeding_interval", 0.5)
	
	# Calcula dano de sangramento
	var base_damage = projectile.damage
	if projectile.has_node("DmgCalculatorComponent"):
		var dmg_calc = projectile.get_node("DmgCalculatorComponent")
		if "base_damage" in dmg_calc:
			base_damage = dmg_calc.base_damage
	
	var bleed_damage_per_tick = int(base_damage * damage_percent)
	
	print("Dano de sangramento por tick: ", bleed_damage_per_tick)
	print("Duração do sangramento: ", duration)
	print("Intervalo do sangramento: ", interval)
	
	# Aplica DoT
	health_component.apply_dot(
		bleed_damage_per_tick,
		duration,
		interval,
		"bleeding"
	)
# Process splinter arrow effect
func process_splinter_effect(target: Node) -> void:
	# Implementation would go here - this would be called by process_talent_effects
	# We're using a placeholder as the full implementation would be lengthy
	if has_meta("splinter_strategy"):
		var strategy_ref = get_meta("splinter_strategy")
		var strategy = strategy_ref.get_ref() if strategy_ref is WeakRef else strategy_ref
		
		if strategy and strategy.has_method("create_splinters"):
			strategy.create_splinters(self, target)

# Process explosion arrow effect
func process_explosion_effect(target: Node) -> void:
	# Implementation would go here - this would be called by process_talent_effects
	# We're using a placeholder as the full implementation would be lengthy
	if has_meta("explosion_strategy"):
		var strategy_ref = get_meta("explosion_strategy")
		var strategy = strategy_ref.get_ref() if strategy_ref is WeakRef else strategy_ref
		
		if strategy and strategy.has_method("create_explosion"):
			strategy.create_explosion(self, target)

# Find a new target to chain to
func find_chain_target(original_target) -> void:
	# Wait a frame to ensure hit processing is complete
	await get_tree().process_frame
	
	# Find nearby enemies we haven't hit yet
	var potential_targets = []
	var space_state = get_world_2d().direct_space_state
	
	# Create circle query
	var query = PhysicsShapeQueryParameters2D.new()
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = chain_range
	query.shape = circle_shape
	query.transform = Transform2D(0, global_position)
	query.collision_mask = 2  # Enemy layer
	
	# Execute query
	var results = space_state.intersect_shape(query)
	
	# Filter valid targets
	for result in results:
		var body = result.collider
		
		# Skip original target and already hit targets
		if body == original_target or body in hit_targets:
			continue
			
		# Check if it's an enemy with health
		if (body.is_in_group("enemies") or body.get_collision_layer_value(2)) and body.has_node("HealthComponent"):
			potential_targets.append(body)
	
	# If we found at least one valid target
	if potential_targets.size() > 0:
		# Choose random target
		var next_target = potential_targets[randi() % potential_targets.size()]
		
		# Apply damage reduction
		if has_node("DmgCalculatorComponent"):
			var dmg_calc = get_node("DmgCalculatorComponent")
			
			if "base_damage" in dmg_calc:
				dmg_calc.base_damage = int(dmg_calc.base_damage * (1.0 - chain_damage_decay))
				
			if "elemental_damage" in dmg_calc:
				for element_type in dmg_calc.elemental_damage.keys():
					dmg_calc.elemental_damage[element_type] = int(dmg_calc.elemental_damage[element_type] * (1.0 - chain_damage_decay))
		
		# Reduce direct damage
		damage = int(damage * (1.0 - chain_damage_decay))
		
		# Get new trajectory
		var new_direction = (next_target.global_position - global_position).normalized()
		
		# Update direction
		direction = new_direction
		rotation = direction.angle()
		
		# Reset collision
		if has_node("Hurtbox"):
			var hurtbox = get_node("Hurtbox")
			hurtbox.set_deferred("monitoring", true)
			hurtbox.set_deferred("monitorable", true)
		
		# Re-enable collision
		collision_layer = 4
		collision_mask = 2
		
		# Reposition to avoid immediate collision
		global_position += direction * 10
		
		# Increment chain counter
		current_chains += 1
		
		# Reset velocity for proper movement
		velocity = direction * speed
		
		# Allow hits to be processed again
		is_processing_ricochet = false
	else:
		# If arrow also has piercing, let it continue
		if piercing:
			var current_pierce_count = 0
			if has_meta("current_pierce_count"):
				current_pierce_count = get_meta("current_pierce_count")
			
			var max_pierce = 1
			if has_meta("piercing_count"):
				max_pierce = get_meta("piercing_count")
			
			if current_pierce_count <= max_pierce:
				is_processing_ricochet = false
				return
		
		# Clean up arrow
		if is_pooled():
			return_to_pool()
		else:
			queue_free()

func reset_for_reuse() -> void:
	# IMPORTANT: Don't reset critical hit yet
	var bleeding_meta = {
		"has_bleeding_effect": get_meta("has_bleeding_effect") if has_meta("has_bleeding_effect") else null,
		"bleeding_damage_percent": get_meta("bleeding_damage_percent") if has_meta("bleeding_damage_percent") else null,
		"bleeding_duration": get_meta("bleeding_duration") if has_meta("bleeding_duration") else null,
		"bleeding_interval": get_meta("bleeding_interval") if has_meta("bleeding_interval") else null
	}
	# Clear all states
	current_chains = 0
	chain_calculated = false
	will_chain = false
	is_processing_ricochet = false
	hit_targets.clear()
	
	# Don't clear tags yet - will be repopulated by talents
	velocity = Vector2.ZERO
	
	# Reset damage to base value
	damage = 10  # Use your base arrow damage
	
	# Reset DmgCalculator
	if has_node("DmgCalculatorComponent"):
		var dmg_calc = get_node("DmgCalculatorComponent")
		# Reset apenas os valores que NÃO vêm do atirador
		dmg_calc.base_damage = 10  # Base damage padrão
		dmg_calc.damage_multiplier = 1.0
		dmg_calc.armor_penetration = 0.0
		dmg_calc.elemental_damage = {}
		dmg_calc.additional_effects = []
		dmg_calc.dot_effects = []
	
	# Reset collision properties safely
	if has_node("Hurtbox"):
		var hurtbox = get_node("Hurtbox")
		hurtbox.set_deferred("monitoring", true)
		hurtbox.set_deferred("monitorable", true)
	
	# Reset collision layers
	set_deferred("collision_layer", 4)  # Projectile layer
	set_deferred("collision_mask", 2)   # Enemy layer
	
	# Reset physics processing
	set_physics_process(true)
	
	# Clear all metadata EXCEPT certain keys
	var meta_list = get_meta_list()
	for prop in meta_list:
		# Preserva certas metadados importantes
		if prop != "pooled" and prop != "initialized":
			remove_meta(prop)
	# Restaura metadados de sangramento se existirem
	for key in bleeding_meta:
		if bleeding_meta[key] != null:
			set_meta(key, bleeding_meta[key])
	# We'll recalculate critical hit AFTER shooter is set
	tags.clear()  # Now clear tags after preserving important metadata
# Helper method to check if arrow is from pool
func is_pooled() -> bool:
	return has_meta("pooled") and get_meta("pooled") == true

# Helper method to return arrow to pool
func return_to_pool() -> void:
	print("Attempting to return arrow to pool")
	print("Is pooled: ", is_pooled())
	print("Shooter: ", shooter)
	print("Shooter type: ", typeof(shooter))
	print("Shooter has instance method: ", shooter.has_method("get_instance_id"))
	
	if not is_pooled() or not shooter:
		print("Cannot return to pool - queuing free")
		queue_free()
		return
	
	# Log de verificação do pool
	print("ProjectilePool exists: ", ProjectilePool != null)
	print("ProjectilePool instance exists: ", ProjectilePool.instance != null)
	
	# Return to appropriate pool
	if ProjectilePool and ProjectilePool.instance:
		print("Attempting to return arrow via pool method")
		ProjectilePool.instance.return_arrow_to_pool(self)
	else:
		print("No pool instance - queuing free")
		queue_free()
