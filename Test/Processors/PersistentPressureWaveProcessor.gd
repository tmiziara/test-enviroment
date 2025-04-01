extends Node2D
class_name PersistentPressureWaveProcessor

# Visual properties
var radius: float = 5.0
var max_radius: float = 80.0
var expansion_speed: float = 200.0
var color: Color = Color(0.5, 0.7, 1.0, 0.7)
var ring_color: Color = Color(0.7, 0.9, 1.0, 1.0)
var ring_width: float = 2.0
var only_slow: bool = false  # Se verdadeiro, apenas aplica slow sem knockback

# Effect properties
var ground_effect_duration: float = 3.0
var slow_percent: float = 0.3
var slow_duration: float = 0.5
var knockback_force: float = 150.0
var shooter = null

# Control variables
var effect_active: bool = true
var expansion_done: bool = false
var elapsed_time: float = 0.0
var area: Area2D = null
var setup_completed: bool = false
var pending_setup: bool = false
var affected_enemies = {}  # Track enemies already affected

# On initialization, only set up basics and defer the rest
func _ready():
	# Defer creation of any nodes involving physics
	call_deferred("_deferred_setup")
	
	# Timer for cleanup - safe to create immediately
	var cleanup_timer = Timer.new()
	cleanup_timer.name = "CleanupTimer"
	cleanup_timer.wait_time = (max_radius / expansion_speed) + ground_effect_duration + 1.0
	cleanup_timer.one_shot = true
	cleanup_timer.autostart = true
	add_child(cleanup_timer)
	cleanup_timer.timeout.connect(func(): queue_free())
	
	# Mark as pending setup
	pending_setup = true

# Deferred setup, executed when safe
func _deferred_setup():
	# Timer for the effect - created here to ensure it's after physics processing
	var effect_timer = Timer.new()
	effect_timer.name = "EffectTimer"
	effect_timer.wait_time = (max_radius / expansion_speed) + ground_effect_duration
	effect_timer.one_shot = true
	effect_timer.autostart = true
	add_child(effect_timer)
	effect_timer.timeout.connect(func(): _disable_effect())
	
	# Create the collision area
	_create_collision_area()
	
	# Mark as configured
	setup_completed = true
	pending_setup = false

# Safe creation of collision area
func _create_collision_area():
	# Create the area
	area = Area2D.new()
	area.name = "EffectArea"
	area.collision_layer = 0
	area.collision_mask = 2  # Enemy layer
	
	# Disable monitoring until fully configured
	area.monitoring = false
	area.monitorable = false
	
	# Add to scene
	add_child(area)
	
	# Create collision shape
	var collision_shape = CollisionShape2D.new()
	collision_shape.name = "CollisionShape"
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = radius
	
	# Disable shape first
	collision_shape.disabled = true
	collision_shape.shape = circle_shape
	
	# Add the shape
	area.add_child(collision_shape)
	
	# Connect signals - only after everything is configured
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)  # Track when bodies exit the area
	
	# Activate after a small delay
	var activation_timer = Timer.new()
	activation_timer.name = "ActivationTimer"
	activation_timer.wait_time = 0.2  # Wait 0.2 seconds to activate
	activation_timer.one_shot = true
	activation_timer.autostart = true
	add_child(activation_timer)
	activation_timer.timeout.connect(func(): _activate_area())

func _activate_area():
	if area and is_instance_valid(area):
		# Ativar os recursos de monitoramento
		area.set_deferred("monitoring", true)
		area.set_deferred("monitorable", true)
		
		# Ativar o shape
		var collision_shape = area.get_node_or_null("CollisionShape")
		if collision_shape:
			collision_shape.set_deferred("disabled", false)
		# Adicionar timer para verificação periódica de inimigos na área
		var check_timer = Timer.new()
		check_timer.name = "AreaCheckTimer"
		check_timer.wait_time = 0.5  # A cada 0.5 segundos
		check_timer.one_shot = false
		check_timer.autostart = true
		add_child(check_timer)
		check_timer.timeout.connect(_check_enemies_in_area)

func _check_enemies_in_area():
	if not effect_active or not area or not is_instance_valid(area):
		return
		
	var bodies = area.get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("enemies") or body.get_collision_layer_value(2):
			# Aplicar apenas o slow (sem knockback) para inimigos que já estão na área
			apply_slow_effect(body)

func _disable_effect():
	effect_active = false
	if area and is_instance_valid(area):
		# Disable collision area
		area.set_deferred("monitoring", false)
		area.set_deferred("monitorable", false)
		
		# Disable shape
		var collision_shape = area.get_node_or_null("CollisionShape")
		if collision_shape:
			collision_shape.set_deferred("disabled", true)
		
		# Remove slow effects from all affected enemies
		for enemy_id in affected_enemies.keys():
			var enemy_ref = affected_enemies[enemy_id]["ref"]
			var enemy = enemy_ref.get_ref()
			if enemy and is_instance_valid(enemy):
				_remove_slow_effect(enemy)

func _process(delta):
	# If still waiting for setup, don't do physics processing
	if pending_setup:
		return
	
	elapsed_time += delta
	
	# Update wave radius
	if radius < max_radius:
		radius += expansion_speed * delta
		
		# Update shape radius if ready
		if setup_completed and area and is_instance_valid(area):
			var collision_shape = area.get_node_or_null("CollisionShape")
			if collision_shape and collision_shape.shape is CircleShape2D:
				collision_shape.shape.set_deferred("radius", radius)
	elif not expansion_done:
		expansion_done = true
	
	# Calculate opacity
	if expansion_done:
		var remaining_time = ground_effect_duration - (elapsed_time - (max_radius / expansion_speed))
		var fade_factor = max(0, remaining_time / ground_effect_duration)
		color.a = max(0, 0.5 * fade_factor)
		ring_color.a = color.a * 1.5
	else:
		color.a = max(0, 0.7 * (1.0 - radius / max_radius))
		ring_color.a = color.a * 1.5
	
	queue_redraw()

func _draw():
	# Draw main circle
	draw_circle(Vector2.ZERO, radius, color)
	
	# Draw ring
	draw_arc(Vector2.ZERO, radius, 0, TAU, 32, ring_color, ring_width)
	
	# Draw ripples when expanded
	if expansion_done and effect_active:
		var inner_radius = radius * 0.8
		var wave_count = 3
		for i in range(wave_count):
			var wave_radius = inner_radius + (radius - inner_radius) * (i / float(wave_count))
			var wave_alpha = color.a * (1.0 - (i / float(wave_count)))
			var wave_color = Color(color.r, color.g, color.b, wave_alpha)
			draw_arc(Vector2.ZERO, wave_radius, 0, TAU, 24, wave_color, 1.0)

func _on_body_entered(body):
	if not effect_active or not setup_completed:
		return
	
	# Check if it's an enemy
	if body.is_in_group("enemies") or body.get_collision_layer_value(2):
		# Track this enemy as being inside the area
		var body_id = body.get_instance_id()
		affected_enemies[body_id] = {
			"ref": weakref(body),
			"inside_area": true
		}
		
		# Apply the appropriate effects
		if only_slow:
			apply_slow_effect(body)
		else:
			# Apply both knockback and slow effects
			apply_effect_to_enemy(body)

func _on_body_exited(body):
	if not effect_active:
		return
		
	# When an enemy leaves the area, mark it as no longer inside
	# but don't remove the slow effect immediately - it has its own duration
	var body_id = body.get_instance_id()
	if body_id in affected_enemies:
		affected_enemies[body_id]["inside_area"] = false

# Method that applies both effects to enemy
func apply_effect_to_enemy(enemy):
	# Se a flag only_slow estiver ativa, apenas aplica o slow
	if only_slow:
		apply_slow_effect(enemy)
		return
	
	# Comportamento padrão: aplica knockback e slow
	apply_knockback_effect(enemy)
	apply_slow_effect(enemy)

# Apply only slow effect for enemies in the area
func apply_slow_effect(enemy):
	if slow_percent <= 0 or slow_duration <= 0:
		return
			# Via DebuffComponent
	if enemy.has_node("DebuffComponent"):
		var debuff_component = enemy.get_node("DebuffComponent")
		# Dados para o debuff
		var debuff_data = {
			"slow_percent": slow_percent,
			"source": shooter,
			"display_icon": true,
			"effect_name": "Pressure Wave",
			"stack_count": 1,
			"max_stacks": 1
		}
		
		# Aplica o debuff
		if debuff_component.has_method("add_debuff"):
			var result = debuff_component.add_debuff(GlobalDebuffSystem.DebuffType.SLOWED, slow_duration, debuff_data)
		return
	
	# Via MovementControl - Como alternativa
	if enemy.has_node("MovementControlComponent"):
		var movement_control = enemy.get_node("MovementControlComponent")
		if movement_control.has_method("apply_slow"):
			movement_control.apply_slow(slow_percent, slow_duration)
		return
	
	# Direct method - Último recurso
	if "base_speed" in enemy and "move_speed" in enemy:
		var original_speed = enemy.move_speed
		enemy.move_speed = original_speed * (1.0 - slow_percent)
		# Timer for restore
		var timer = Timer.new()
		timer.wait_time = slow_duration
		timer.one_shot = true
		timer.autostart = true
		enemy.add_child(timer)
		
		# Usar WeakRef para evitar referências inválidas
		var enemy_ref = weakref(enemy)
		timer.timeout.connect(func():
			var enemy_instance = enemy_ref.get_ref()
			if enemy_instance and is_instance_valid(enemy_instance) and "move_speed" in enemy_instance:
				enemy_instance.move_speed = original_speed
			if timer and is_instance_valid(timer):
				timer.queue_free()
		)

# Apply knockback effect
func apply_knockback_effect(enemy):
	if knockback_force <= 0:
		return
	# Apply knockback - Use MovementControlComponent preferentially
	if enemy.has_node("MovementControlComponent"):
		var movement_control = enemy.get_node("MovementControlComponent")
		if movement_control.has_method("apply_knockback"):
			# Calculate knockback direction
			var knockback_direction = (enemy.global_position - global_position).normalized()
			# Chamar diretamente sem call_deferred
			movement_control.apply_knockback(knockback_direction, knockback_force)
	# Fallback for direct method if no MovementControlComponent
	elif enemy is CharacterBody2D:
		var knockback_direction = (enemy.global_position - global_position).normalized()
		# Apply knockback through velocity - chamar diretamente
		enemy.velocity += knockback_direction * knockback_force

# Remove slow effect manually (for cleanup)
func _remove_slow_effect(enemy):
	# Via DebuffComponent
	if enemy.has_node("DebuffComponent"):
		var debuff_component = enemy.get_node("DebuffComponent")
		if debuff_component.has_method("remove_debuff"):
			debuff_component.remove_debuff(GlobalDebuffSystem.DebuffType.SLOWED)
	# Via MovementControl
	elif enemy.has_node("MovementControlComponent"):
		var movement_control = enemy.get_node("MovementControlComponent")
		if movement_control.has_method("remove_slow"):
			movement_control.remove_slow()

# Static method to create the effect
static func create_at_position(position: Vector2, parent: Node, shooter = null, settings: Dictionary = {}) -> PersistentPressureWaveProcessor:
	if not parent or not is_instance_valid(parent):
		return null
	
	# Create in two steps to avoid physics problems
	# 1. Create first without full configuration
	var wave = PersistentPressureWaveProcessor.new()
	wave.name = "PersistentPressureWave"
	wave.position = position
	wave.shooter = shooter
	
	# 2. Apply basic settings (not involving physics)
	if "duration" in settings:
		wave.ground_effect_duration = settings.duration
	if "slow_percent" in settings:
		wave.slow_percent = settings.slow_percent
	if "slow_duration" in settings:
		wave.slow_duration = settings.slow_duration
	if "knockback_force" in settings:
		wave.knockback_force = settings.knockback_force
	if "max_radius" in settings:
		wave.max_radius = settings.max_radius
	if "only_slow" in settings:
		wave.only_slow = settings.only_slow
	
	# 3. Use call_deferred of parent node to add safely
	if parent.has_method("call_deferred"):
		parent.call_deferred("add_child", wave)
	else:
		# Fallback if call_deferred cannot be used
		parent.add_child(wave)
	return wave
