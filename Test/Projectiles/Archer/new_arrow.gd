extends NewProjectileBase
class_name NewArrow

# Arrow Rain properties
var arrow_rain_enabled: bool = false
var arrow_rain_counter: int = 0
var arrow_rain_threshold: int = 10
var arrow_rain_count: int = 5
var arrow_rain_radius: float = 80.0

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
	if shooter and "crit_chance" in shooter:
		crit_chance = shooter.crit_chance
	# Initialize hit_targets array if not already done
	if not hit_targets:
		hit_targets = []
	# IMPORTANT: Don't precalculate chain here - let each arrow calculate independently
	# when it hits (by setting chain_calculated to false)
	chain_calculated = false
	will_chain = false
	
	# Mark as initialized for pooled objects
	if is_pooled():
		set_meta("initialized", true)

func _physics_process(delta):
	# If this is an arrow rain arrow with a dedicated processor, skip normal movement
	if has_meta("is_rain_arrow") and has_node("RainArrowProcessor"):
		# Let the processor handle it
		return
		
	# Normal movement code continues below...
	super._physics_process(delta)

# Substituir o método get_damage_package para incluir a lógica do Mark of Death
func get_damage_package() -> Dictionary:
	# Obter o pacote base do pai
	var damage_package = super.get_damage_package()
	
	# Definir o alvo atual para efeitos
	var current_target = null
	if has_meta("current_target"):
		current_target = get_meta("current_target")
	elif shooter and shooter.has_method("get_current_target"):
		current_target = shooter.get_current_target()
	
	# Processar Focused Shot se habilitado
	if has_meta("focused_shot_enabled") and current_target and is_instance_valid(current_target):
		damage_package = apply_focused_shot_bonus(damage_package, current_target)
	
	# Processar Mark for Death para acertos críticos
	if current_target and is_instance_valid(current_target) and damage_package.get("is_critical", false):
		damage_package = apply_mark_bonus(damage_package, current_target)
	
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
		
		# Apply to elemental damage
		if "elemental_damage" in damage_package:
			for element in damage_package["elemental_damage"]:
				var bonus_elem = int(damage_package["elemental_damage"][element] * focused_shot_bonus)
				damage_package["elemental_damage"][element] += bonus_elem
		
		# Add tag
		if "tags" not in damage_package:
			damage_package["tags"] = []
		if "focused_shot" not in damage_package["tags"]:
			damage_package["tags"].append("focused_shot")
	
	return damage_package

# Override the process_on_hit method for advanced arrow functionality
func process_on_hit(target: Node) -> void:
	# Variável para controlar destruição da flecha - garante que será destruída por padrão
	var should_destroy = true
	
	# Get target instance ID for reliable comparison
	var target_id = target.get_instance_id()
	
	# Flag to determine if this hit should increment Bloodseeker stacks
	var should_increment_bloodseeker = false
	
	# Define o alvo atual para cálculos de dano
	set_meta("current_target", target)
	
	# Se já estiver processando um ricochet, ignora este hit
	if is_processing_ricochet:
		return
	
	# BLOODSEEKER LOGIC: Determine if this hit should increment Bloodseeker stacks
	# ----------------------------------------------------------------------------------
	# Check if the projectile is marked for special treatment (chain/double shot/piercing)
	if has_meta("is_second_arrow"):
		# For double shot, secondary arrows don't increment Bloodseeker
		should_increment_bloodseeker = false
	elif chain_shot_enabled and current_chains > 0:
		# For chain shot, only the first hit (current_chains == 0) increments Bloodseeker
		should_increment_bloodseeker = false
	elif piercing:
		# For piercing arrows, we need to check if this is a new target for THIS arrow
		if not has_meta("bloodseeker_hit_targets"):
			set_meta("bloodseeker_hit_targets", {})
		
		var bs_hit_targets = get_meta("bloodseeker_hit_targets")
		var target_key = str(target_id)
		
		if target_key in bs_hit_targets:
			# Already hit this target with this arrow - don't increment
			should_increment_bloodseeker = false
		else:
			# First time hitting this target - add it to our tracking and increment
			bs_hit_targets[target_key] = true
			set_meta("bloodseeker_hit_targets", bs_hit_targets)
			
			# Only the first target hit by each arrow should increment
			if not has_meta("bloodseeker_hit_first"):
				set_meta("bloodseeker_hit_first", true)
				should_increment_bloodseeker = true
			else:
				should_increment_bloodseeker = false
	else:
		# Normal arrow - should increment
		should_increment_bloodseeker = true
	
	# Store our decision for Bloodseeker stacking in metadata
	set_meta("should_increment_bloodseeker", should_increment_bloodseeker)
	# ----------------------------------------------------------------------------------
	
	# Adiciona o alvo à lista de alvos atingidos (para other tracking)
	if not has_meta("hit_targets"):
		set_meta("hit_targets", [])
		
	var hit_targets = get_meta("hit_targets")
	
	if not target in hit_targets:
		hit_targets.append(target)
	set_meta("hit_targets", hit_targets)
	
	# Calcula e aplica dano
	if target.has_node("HealthComponent"):
		var health_component = target.get_node("HealthComponent")
		# Obtém o pacote de dano específico para este alvo
		var damage_package = get_damage_package()
		# Process talent effects from metadata and add to damage package
		if has_node("DmgCalculatorComponent"):
			var dmg_calc = get_node("DmgCalculatorComponent")
			# Process fire DoT if configured - either through damage package or the DoTManager
			if dmg_calc.has_meta("fire_dot_data"):
				var dot_data = dmg_calc.get_meta("fire_dot_data")
				var dot_chance = dot_data.get("chance", 0.0)
				# Roll for DoT chance
				if randf() <= dot_chance:
					if "dot_effects" not in damage_package:
						damage_package["dot_effects"] = []
					# Calculate damage based on the TOTAL damage
					# Get the base damage from the damage package or the arrow's damage
					var total_damage = damage_package.get("physical_damage", damage)
					# Add elemental damage if any
					var elemental_damage = damage_package.get("elemental_damage", {})
					for element_type in elemental_damage:
						total_damage += elemental_damage[element_type]
					# Get DoT percentage or use default
					var dot_percent = dot_data.get("percent_per_tick", 0.05)  # Default to 5% if not specified
					# Calculate DoT damage from total damage
					var dot_damage = int(total_damage * dot_percent)
					# Ensure minimum damage of 1
					dot_damage = max(1, dot_damage)
					# Add DoT effect to package
					damage_package["dot_effects"].append({
						"damage": dot_damage,
						"duration": dot_data.get("duration", 3.0),
						"interval": dot_data.get("interval", 0.5),
						"type": dot_data.get("type", "fire")
					})
					
		health_component.take_complex_damage(damage_package)
		# Process special DoT effects like bleeding using DoTManager
		process_special_dot_effects(damage_package, target)
	
	# Emite sinal para sistemas de talentos
	emit_signal("on_hit", target, self)
	# Processa efeitos de talentos (exceto DoTs que agora são centralizados no DoTManager)
	process_talent_effects(target)
	# Desabilita temporariamente a colisão para evitar múltiplos hits
	if has_node("Hurtbox"):
		var hurtbox = get_node("Hurtbox")
		hurtbox.set_deferred("monitoring", false)
		hurtbox.set_deferred("monitorable", false)

	if has_meta("is_rain_arrow"):
		# Simplified hit logic for rain arrows
		if target.has_node("HealthComponent"):
			var health_component = target.get_node("HealthComponent")
			# Get basic damage package
			var damage_package = get_damage_package()
			health_component.take_complex_damage(damage_package)
		# Basic signal emission
		emit_signal("on_hit", target, self)

	
	# Verifica Chain Shot
	if chain_shot_enabled and current_chains < max_chains:
		# IMPORTANTE: Aborta os ricochetes se já atingimos o máximo
		if current_chains >= max_chains:
			will_chain = false
			chain_calculated = true
			is_processing_ricochet = false
		# Apenas calcula a chance no primeiro hit
		elif current_chains == 0 and not chain_calculated:
			var roll = randf()
			will_chain = (roll <= chain_chance)
			chain_calculated = true
		
		if will_chain and current_chains < max_chains:
			is_processing_ricochet = true
			call_deferred("find_chain_target", target)
			should_destroy = false  # Permite que a flecha continue
		else:
			print("No chaining - max reached or chance failed")
	
	# Verifica Piercing - apenas se não estiver fazendo ricochet
	if piercing and not will_chain:
		# Get hit_targets from meta
		hit_targets = get_meta("hit_targets") if has_meta("hit_targets") else []
		var current_pierce_count = hit_targets.size() - 1  # -1 because first hit isn't counted as pierce
		var max_pierce = 1
		
		if has_meta("piercing_count"):
			max_pierce = get_meta("piercing_count")
		# IMPORTANT: Set an explicit metadata entry to track current pierce count
		set_meta("current_pierce_count", current_pierce_count)
		
		if current_pierce_count < max_pierce:
			# Prepara para próximo hit
			if has_node("Hurtbox"):
				var hurtbox = get_node("Hurtbox")
				# Reabilitamos apenas se for continuar com piercing
				hurtbox.set_deferred("monitoring", true)
				hurtbox.set_deferred("monitorable", true)
			
			# Move a flecha ligeiramente para frente para evitar ficar preso
			global_position += direction * 10
			
			# Mantém a velocidade e direção originais
			velocity = direction * speed
			
			should_destroy = false  # Permite que a flecha continue
		else:
			print("Max pierce count reached")
			
	if will_chain:
		is_processing_ricochet = true
		call_deferred("find_chain_target", target)
		should_destroy = false  # Permite que a flecha continue
	# Destruição final
	if should_destroy:
		
		# Desabilita física e visibilidade imediatamente
		set_physics_process(false)
		visible = false
		
		# Desabilita colisões completamente usando set_deferred
		if has_node("Hurtbox"):
			var hurtbox = get_node("Hurtbox")
			hurtbox.set_deferred("monitoring", false)
			hurtbox.set_deferred("monitorable", false)
		
		# Desabilita completamente colisões de corpo
		set_deferred("collision_layer", 0)
		set_deferred("collision_mask", 0)
		velocity = Vector2.ZERO
		
		# Retorna ao pool com pequeno delay ou destrói
		if is_pooled():
			get_tree().create_timer(0.1).timeout.connect(func():
				return_to_pool()
			)
		else:
			queue_free()
			
# Versão corrigida para o método process_special_dot_effects
func process_special_dot_effects(damage_package: Dictionary, target: Node) -> void:
	# Check if DoTManager singleton is available
	var dot_manager = null
	# Tenta acessar pela propriedade estática
	if DoTManager.instance:
		dot_manager = DoTManager.instance
	else:
		# Fallback: tenta encontrar pelo caminho na árvore
		dot_manager = get_node_or_null("/root/DoTManager")
		if dot_manager:
			print("DoTManager encontrado na árvore de nós")
		else:
			return
	
	# Verify the dot_manager has the apply_dot method
	if not dot_manager.has_method("apply_dot"):
		return
	# Calculate TOTAL damage before armor reduction
	var total_damage = damage_package.get("physical_damage", damage)
	var elemental_damage = damage_package.get("elemental_damage", {})
	# Add all elemental damage components
	for element_type in elemental_damage:
		total_damage += elemental_damage[element_type]
	if damage_package.get("is_critical", false) and has_meta("has_bleeding_effect"):
		# Get bleeding metadata from arrow
		var damage_percent = get_meta("bleeding_damage_percent", 0.3)
		var duration = get_meta("bleeding_duration", 4.0)
		var interval = get_meta("bleeding_interval", 0.5)
		
		# FIXED: Calculate bleeding damage based on TOTAL damage before armor reduction
		var bleed_damage_per_tick = int(total_damage * damage_percent)
		
		# Ensure minimum damage of 1
		bleed_damage_per_tick = max(1, bleed_damage_per_tick)
		# Apply bleeding via DoTManager
		var dot_id = dot_manager.apply_dot(
			target,
			bleed_damage_per_tick,
			duration,
			interval,
			"bleeding",
			self  # Source is this arrow
		)
	# Process fire DoT directly via DoTManager if not already added to damage package
	if has_node("DmgCalculatorComponent"):
		var dmg_calc = get_node("DmgCalculatorComponent")
		
		if dmg_calc.has_meta("fire_dot_data") and not "dot_effects" in damage_package:
			var dot_data = dmg_calc.get_meta("fire_dot_data")
			var dot_chance = dot_data.get("chance", 0.0)
			
			# Roll for chance
			if randf() <= dot_chance:
				# FIXED: Calculate fire DoT damage based on TOTAL damage
				var base_dot_damage = dot_data.get("damage_per_tick", 1)
				var dot_percent = dot_data.get("percent", 0.05)  # Default to 5% if not specified
				
				# Calculate based on percentage of total damage if percent is specified
				var dot_damage = base_dot_damage
				if dot_percent > 0:
					dot_damage = int(total_damage * dot_percent)
				
				# Ensure minimum damage of 1
				dot_damage = max(1, dot_damage)
				
				var dot_duration = dot_data.get("duration", 3.0)
				var dot_interval = dot_data.get("interval", 0.5)
				# Apply fire DoT via DoTManager
				var dot_id = dot_manager.apply_dot(
					target,
					dot_damage,
					dot_duration,
					dot_interval,
					"fire",
					self  # Source is this arrow
				)
	# Any other specialized DoT effects can be added here
func process_talent_effects(target: Node) -> void:
	# Get flag for Bloodseeker increment
	var should_increment_bloodseeker = has_meta("should_increment_bloodseeker") and get_meta("should_increment_bloodseeker")
	
	# Apply Bloodseeker effect only when indicated
	if has_meta("has_bloodseeker_effect") and shooter and is_instance_valid(shooter):
		if should_increment_bloodseeker:
			# Verifica se o atirador tem ArcherTalentManager
			if shooter.has_node("ArcherTalentManager"):
				var talent_manager = shooter.get_node("ArcherTalentManager")
				talent_manager.apply_bloodseeker_hit(target)
			
	# Process mark effect - nova verificação
	if has_meta("has_mark_effect") and is_crit:
		apply_mark_on_critical_hit(target)
	
	# Process splinter effect
	if has_meta("has_splinter_effect"):
		process_splinter_effect(target)
	
	# Process explosion effect
	if has_meta("has_explosion_effect"):
		process_explosion_effect(target)

# Process splinter arrow effect
func process_splinter_effect(target: Node) -> void:
	# Implementation would go here - this would be called by process_talent_effects
	# We're using a placeholder as the full implementation would be lengthy
	if has_meta("splinter_strategy"):
		var strategy_ref = get_meta("splinter_strategy")
		var strategy = strategy_ref.get_ref() if strategy_ref is WeakRef else strategy_ref
		
		if strategy and strategy.has_method("create_splinters"):
			strategy.create_splinters(self, target)

func apply_mark_on_critical_hit(target: Node) -> void:
	# Verifica se o projétil tem o efeito de marca configurado
	if not has_meta("has_mark_effect"):
		return
		
	# Verifica se foi um acerto crítico
	if not is_crit:
		return
		
	# Obtém parâmetros da marca dos metadados
	var mark_duration = get_meta("mark_duration", 4.0)
	var mark_crit_bonus = get_meta("mark_crit_bonus", 1.0)
	
	# Verifica se o alvo tem DebuffComponent
	if target.has_node("DebuffComponent"):
		var debuff_component = target.get_node("DebuffComponent")
		
		# Dados da marca
		var mark_data = {
			"max_stacks": 1,  # Não acumula
			"crit_bonus": mark_crit_bonus,
			"source": shooter
		}
		
		# Aplica o debuff de marca
		debuff_component.add_debuff(
			GlobalDebuffSystem.DebuffType.MARKED_FOR_DEATH,
			mark_duration,
			mark_data,
			true  # Pode renovar duração
		)
		
		# Armazena o bônus como metadado no alvo para acesso rápido
		target.set_meta("mark_crit_bonus", mark_crit_bonus)

# Process explosion arrow effect
func process_explosion_effect(target: Node) -> void:
	# Implementation would go here - this would be called by process_talent_effects
	# We're using a placeholder as the full implementation would be lengthy
	if has_meta("explosion_strategy"):
		var strategy_ref = get_meta("explosion_strategy")
		var strategy = strategy_ref.get_ref() if strategy_ref is WeakRef else strategy_ref
		
		if strategy and strategy.has_method("create_explosion"):
			strategy.create_explosion(self, target)
			
func find_chain_target(original_target) -> void:
	if current_chains >= max_chains:
		will_chain = false
		is_processing_ricochet = false
		if is_pooled():
			return_to_pool()
		else:
			queue_free()
		return
	# Wait a frame to ensure hit processing is complete
	await get_tree().process_frame
	# IMPORTANTE: Verificar e inicializar a lista de hit_targets corretamente
	if hit_targets == null:
		hit_targets = []
	
	# Adicione o alvo original à lista se ainda não estiver lá
	if original_target and not original_target in hit_targets:
		hit_targets.append(original_target)
		
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
	
	# Filter and collect target info with velocity
	var target_info = []
	for result in results:
		var body = result.collider
		
		# Skip original target and already hit targets
		if body in hit_targets:
			continue
			
		# Check if it's an enemy with health
		if (body.is_in_group("enemies") or body.get_collision_layer_value(2)) and body.has_node("HealthComponent"):
			# Calculate target velocity if it's a CharacterBody2D
			var target_velocity = Vector2.ZERO
			if body is CharacterBody2D:
				target_velocity = body.velocity
			
			# Store target with its velocity and position
			target_info.append({
				"body": body,
				"position": body.global_position,
				"velocity": target_velocity
			})
	# If we found at least one valid target
	if target_info.size() > 0:
		# Choose random target
		var target_data = target_info[randi() % target_info.size()]
		var next_target = target_data.body
		var target_position = target_data.position
		var target_velocity = target_data.velocity
		
		# IMPORTANT: Increment chain counter BEFORE continuing
		current_chains += 1
		set_meta("is_part_of_chain", true)
		if current_chains >= max_chains:
			will_chain = false
			chain_calculated = true
		# Adicione o novo alvo à lista de hit_targets
		hit_targets.append(next_target)
		# Apply damage reduction
		if has_node("DmgCalculatorComponent"):
			var dmg_calc = get_node("DmgCalculatorComponent")
			
			# Reduce base damage
			if "base_damage" in dmg_calc:
				var original_base = dmg_calc.base_damage
				dmg_calc.base_damage = int(dmg_calc.base_damage * (1.0 - chain_damage_decay))
			
			# Reduce damage multiplier
			if "damage_multiplier" in dmg_calc:
				var original_mult = dmg_calc.damage_multiplier
				dmg_calc.damage_multiplier *= (1.0 - chain_damage_decay * 0.5)  # Half effect on multiplier
			
			# Reduce elemental damage
			if "elemental_damage" in dmg_calc and not dmg_calc.elemental_damage.is_empty():
				for element_type in dmg_calc.elemental_damage.keys():
					var original_elem = dmg_calc.elemental_damage[element_type]
					dmg_calc.elemental_damage[element_type] = int(dmg_calc.elemental_damage[element_type] * (1.0 - chain_damage_decay))
		# Reduce direct damage
		var original_damage = damage
		damage = int(damage * (1.0 - chain_damage_decay))
		# Importante: Reabilitar a física antes de redefinir a trajetória
		set_physics_process(true)
		
		# Disable collision during redirection
		if has_node("Hurtbox"):
			var hurtbox = get_node("Hurtbox")
			hurtbox.set_deferred("monitoring", false)
			hurtbox.set_deferred("monitorable", false)
		
		# Calculate time for arrow to reach target
		var distance = global_position.distance_to(target_position)
		var flight_time = distance / speed
		
		# Predict target position based on its velocity and flight time
		var predicted_position = target_position + (target_velocity * flight_time)
		
		# Add a slight lead to ensure hitting even with irregular movement
		var lead_factor = 1.2  # Adjust as needed
		var lead_position = target_position + (target_velocity * flight_time * lead_factor)
		
		# Update direction toward predicted position
		direction = (lead_position - global_position).normalized()
		rotation = direction.angle()
		
		# IMPORTANTE: Reativa as camadas de colisão
		collision_layer = 4   # Camada de projétil
		collision_mask = 2    # Camada de inimigo
		
		# Set metadata for homing behavior
		set_meta("homing_target", next_target)
		set_meta("homing_strength", 5.0)  # Adjust as needed
		
		# Move away from current position to avoid collisions
		global_position += direction * 20
		
		# Reset velocity for proper movement
		velocity = direction * speed
		
		# Enable homing behavior
		set_meta("enable_homing", true)
		
		# Create a short timer to re-enable collision
		get_tree().create_timer(0.1).timeout.connect(func():
			if is_instance_valid(self):
				if has_node("Hurtbox"):
					var hurtbox = get_node("Hurtbox")
					hurtbox.set_deferred("monitoring", true)
					hurtbox.set_deferred("monitorable", true)
		)
		
		# IMPORTANTE: Redefine a flag de processamento
		is_processing_ricochet = false
		
		# Adicione um log para confirmar que o ricochete foi configurado corretamente
	else:
		# No valid targets found, clean up arrow
		if is_pooled():
			return_to_pool()
		else:
			queue_free()

func reset_for_reuse() -> void:
	# Salva o estado de crítico atual e metadados importantes antes da limpeza
	var was_critical = is_crit
	var crit_chance_current = crit_chance
		# Save chain shot configuration if needed
	var chain_config = {
		"enabled": chain_shot_enabled,
		"chance": chain_chance,
		"range": chain_range,
		"decay": chain_damage_decay,
		"max": max_chains
	}
	# Salva metadados de sangramento antes da limpeza
	var bleeding_meta = {
		"has_bleeding_effect": get_meta("has_bleeding_effect") if has_meta("has_bleeding_effect") else null,
		"bleeding_damage_percent": get_meta("bleeding_damage_percent") if has_meta("bleeding_damage_percent") else null,
		"bleeding_duration": get_meta("bleeding_duration") if has_meta("bleeding_duration") else null,
		"bleeding_interval": get_meta("bleeding_interval") if has_meta("bleeding_interval") else null
	}
	
	# Salva metadados de Bloodseeker antes da limpeza
	var bloodseeker_meta = {
		"has_bloodseeker_effect": get_meta("has_bloodseeker_effect") if has_meta("has_bloodseeker_effect") else null,
		"damage_increase_per_stack": get_meta("damage_increase_per_stack") if has_meta("damage_increase_per_stack") else null,
		"max_stacks": get_meta("max_stacks") if has_meta("max_stacks") else null
	}
	
	# Salva metadados de Marked for Death antes da limpeza
	var mark_meta = {
		"has_mark_effect": get_meta("has_mark_effect") if has_meta("has_mark_effect") else null,
		"mark_duration": get_meta("mark_duration") if has_meta("mark_duration") else null,
		"mark_crit_bonus": get_meta("mark_crit_bonus") if has_meta("mark_crit_bonus") else null
	}
	
	# Limpa todos os estados de chain e ricochete
	current_chains = 0
	chain_calculated = false
	will_chain = false
	is_processing_ricochet = false
	hit_targets.clear()
	# Reseta velocidade
	velocity = Vector2.ZERO
	
	# Reset damage to base value
	damage = 10  # Use your base arrow damage
	arrow_rain_enabled = false
	arrow_rain_counter = 0
	arrow_rain_threshold = 10
	arrow_rain_count = 5
	arrow_rain_radius = 80.0
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
	# Reset das variáveis de controle do Bloodseeker
	if has_meta("bloodseeker_hit_targets"):
		remove_meta("bloodseeker_hit_targets")
		
	if has_meta("bloodseeker_hit_first"):
		remove_meta("bloodseeker_hit_first")
		
	if has_meta("should_increment_bloodseeker"):
		remove_meta("should_increment_bloodseeker")
	#reset das variavesi do rain arrow
	if has_meta("is_rain_arrow"):
		remove_meta("is_rain_arrow")
	if has_meta("no_double_shot"):
		remove_meta("no_double_shot")
	if has_meta("no_chain_shot"):
		remove_meta("no_chain_shot")
	if has_meta("rain_start_pos"):
		remove_meta("rain_start_pos")
	if has_meta("rain_target_pos"):
		remove_meta("rain_target_pos")
	if has_meta("rain_time"):
		remove_meta("rain_time")
	# Reset collision layers
	set_deferred("collision_layer", 4)  # Projectile layer
	set_deferred("collision_mask", 2)   # Enemy layer
	
	# Reset physics processing
	set_physics_process(true)
	var rain_processor = get_node_or_null("RainArrowProcessor")
	if rain_processor:
		rain_processor.queue_free()
	# Mantém uma cópia das tags antes de limpar
	var old_tags = tags.duplicate() if "tags" in self else []
	
	# Clear all metadata EXCEPT certain keys
	var meta_list = get_meta_list()
	for prop in meta_list:
		# Preserve certain important metadata
		if prop != "pooled" and prop != "initialized":
			remove_meta(prop)
			
	# Restaura metadados importantes
	# 1. Primeiro os metadados de sangramento
	for key in bleeding_meta:
		if bleeding_meta[key] != null:
			set_meta(key, bleeding_meta[key])
	# Restore chain shot configuration if it was enabled
	if chain_config["enabled"]:
		chain_shot_enabled = true
		chain_chance = chain_config["chance"]
		chain_range = chain_config["range"] 
		chain_damage_decay = chain_config["decay"]
		max_chains = chain_config["max"]
	else:
		chain_shot_enabled = false
	# 2. Restaura metadados do Bloodseeker
	for key in bloodseeker_meta:
		if bloodseeker_meta[key] != null:
			set_meta(key, bloodseeker_meta[key])
			
	# 3. Restaura metadados de Marked for Death
	for key in mark_meta:
		if mark_meta[key] != null:
			set_meta(key, mark_meta[key])
		# Reset double shot metadata
	if has_meta("is_second_arrow"):
		remove_meta("is_second_arrow")
	if has_meta("double_shot_enabled"):
		remove_meta("double_shot_enabled")
	if has_meta("double_shot_angle"):
		remove_meta("double_shot_angle")
		# Clear homing-specific metadata
	if has_meta("enable_homing"):
		remove_meta("enable_homing")
	if has_meta("homing_target"):
		remove_meta("homing_target")
	if has_meta("homing_strength"):
		remove_meta("homing_strength")
	# Limpa as tags para depois restaurá-las de forma seletiva
	if "tags" in self:
		tags.clear()
		
		# Restaura tags importantes
		if "bleeding" in old_tags:
			add_tag("bleeding")
		
		if "bloodseeker" in old_tags:
			add_tag("bloodseeker")
			
		if "marked_for_death" in old_tags:
			add_tag("marked_for_death")
			
		if "chain_shot" in old_tags:
			add_tag("chain_shot")
	
	# Recalcula o acerto crítico usando o sistema unificado
	if shooter and "crit_chance" in shooter:
		crit_chance = shooter.crit_chance
		is_crit = is_critical_hit(crit_chance)
	else:
		# Mantém o valor anterior se não for possível recalcular
		crit_chance = crit_chance_current
		is_crit = was_critical

	# Reset physics processing
	set_physics_process(true)
# Helper method to check if arrow is from pool
func is_pooled() -> bool:
	return has_meta("pooled") and get_meta("pooled") == true
