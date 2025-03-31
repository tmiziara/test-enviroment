extends Node2D
class_name PersistentPressureWaveProcessor

# Propriedades visuais
var radius: float = 5.0
var max_radius: float = 80.0
var expansion_speed: float = 200.0
var color: Color = Color(0.5, 0.7, 1.0, 0.7)
var ring_color: Color = Color(0.7, 0.9, 1.0, 1.0)
var ring_width: float = 2.0

# Propriedades do efeito
var ground_effect_duration: float = 3.0
var slow_percent: float = 0.3
var slow_duration: float = 0.5
var knockback_force: float = 150.0
var shooter = null

# Variáveis de controle
var effect_active: bool = true
var expansion_done: bool = false
var elapsed_time: float = 0.0
var area: Area2D = null
var setup_completed: bool = false
var pending_setup: bool = false

# Ao inicializar, apenas configurar o básico, adiar o resto
func _ready():
	# Adiar a criação de qualquer nó envolvendo física
	call_deferred("_deferred_setup")
	
	# Timer para limpeza - este é seguro para criar imediatamente
	var cleanup_timer = Timer.new()
	cleanup_timer.name = "CleanupTimer"
	cleanup_timer.wait_time = (max_radius / expansion_speed) + ground_effect_duration + 1.0
	cleanup_timer.one_shot = true
	cleanup_timer.autostart = true
	add_child(cleanup_timer)
	cleanup_timer.timeout.connect(func(): queue_free())
	
	# Marcar como pendente para setup
	pending_setup = true

# Configuração adiada, executada quando for seguro
func _deferred_setup():
	# Timer para o efeito - criado aqui para garantir que esteja após o processamento de física
	var effect_timer = Timer.new()
	effect_timer.name = "EffectTimer"
	effect_timer.wait_time = (max_radius / expansion_speed) + ground_effect_duration
	effect_timer.one_shot = true
	effect_timer.autostart = true
	add_child(effect_timer)
	effect_timer.timeout.connect(func(): _disable_effect())
	
	# Agora sim, criar a área de colisão
	_create_collision_area()
	
	# Marcar como configurado
	setup_completed = true
	pending_setup = false

# Criação segura da área de colisão
func _create_collision_area():
	# Criar a área
	area = Area2D.new()
	area.name = "EffectArea"
	area.collision_layer = 0
	area.collision_mask = 2  # Layer de inimigos
	
	# Desativar monitoring até que esteja completamente configurada
	area.monitoring = false
	area.monitorable = false
	
	# Adicionar à cena
	add_child(area)
	
	# Criar o shape de colisão
	var collision_shape = CollisionShape2D.new()
	collision_shape.name = "CollisionShape"
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = radius
	
	# Desativar o shape primeiro
	collision_shape.disabled = true
	collision_shape.shape = circle_shape
	
	# Adicionar o shape
	area.add_child(collision_shape)
	
	# Conectar sinal - só depois de tudo configurado
	area.body_entered.connect(_on_body_entered)
	
	# Finalmente, ativar após um pequeno delay
	var activation_timer = Timer.new()
	activation_timer.name = "ActivationTimer"
	activation_timer.wait_time = 0.2  # Espera 0.2 segundos para ativar
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

func _disable_effect():
	effect_active = false
	if area and is_instance_valid(area):
		# Desativar a área de colisão
		area.set_deferred("monitoring", false)
		area.set_deferred("monitorable", false)
		
		# Desativar o shape
		var collision_shape = area.get_node_or_null("CollisionShape")
		if collision_shape:
			collision_shape.set_deferred("disabled", true)

func _process(delta):
	# Se ainda estiver esperando setup, não fazer processamento de física
	if pending_setup:
		return
	
	elapsed_time += delta
	
	# Atualizar o raio da onda
	if radius < max_radius:
		radius += expansion_speed * delta
		
		# Atualizar o raio do shape, se estiver pronto
		if setup_completed and area and is_instance_valid(area):
			var collision_shape = area.get_node_or_null("CollisionShape")
			if collision_shape and collision_shape.shape is CircleShape2D:
				collision_shape.shape.set_deferred("radius", radius)
	elif not expansion_done:
		expansion_done = true
	
	# Calcular opacidade
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
	# Desenhar o círculo principal
	draw_circle(Vector2.ZERO, radius, color)
	
	# Desenhar o anel
	draw_arc(Vector2.ZERO, radius, 0, TAU, 32, ring_color, ring_width)
	
	# Desenhar ondulações quando expandido
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
	
	# Verificar se é um inimigo
	if body.is_in_group("enemies") or body.get_collision_layer_value(2):
		apply_effect_to_enemy(body)

func apply_effect_to_enemy(enemy):
	# Aplicar knockback - Usar MovementControlComponent preferencialmente
	if enemy.has_node("MovementControlComponent"):
		var movement_control = enemy.get_node("MovementControlComponent")
		if movement_control.has_method("apply_knockback"):
			# Calcular direção do knockback
			var knockback_direction = (enemy.global_position - global_position).normalized()
			# Chamar via call_deferred para segurança
			call_deferred("_apply_movement_knockback", movement_control, knockback_direction, knockback_force)
	# Fallback para método direto se não tiver MovementControlComponent
	elif enemy is CharacterBody2D:
		var knockback_direction = (enemy.global_position - global_position).normalized()
		# Aplicar knockback através da velocidade
		enemy.set_deferred("velocity", enemy.velocity + knockback_direction * knockback_force)
	
	# Aplicar slow
	if slow_percent > 0 and slow_duration > 0:
		# Via DebuffComponent
		if enemy.has_node("DebuffComponent"):
			var debuff_component = enemy.get_node("DebuffComponent")
			call_deferred("_apply_debuff", debuff_component, GlobalDebuffSystem.DebuffType.SLOWED, slow_duration, {
				"slow_percent": slow_percent,
				"source": shooter,
				"display_icon": true,
				"effect_name": "Pressure Wave"
			})
		# Via MovementControl
		elif enemy.has_node("MovementControlComponent"):
			var movement_control = enemy.get_node("MovementControlComponent")
			if movement_control.has_method("apply_slow"):
				call_deferred("_apply_movement_slow", movement_control, slow_percent, slow_duration)
		# Método direto
		elif "base_speed" in enemy and "move_speed" in enemy:
			var original_speed = enemy.move_speed
			enemy.set_deferred("move_speed", original_speed * (1.0 - slow_percent))
			
			# Timer para restaurar
			var timer = Timer.new()
			timer.wait_time = slow_duration
			timer.one_shot = true
			timer.autostart = true
			call_deferred("_add_restore_timer", enemy, timer, original_speed)

# Método auxiliar para aplicar knockback
func _apply_movement_knockback(component, direction, force):
	if component and is_instance_valid(component) and component.has_method("apply_knockback"):
		component.apply_knockback(direction, force)

# Métodos auxiliares para aplicar efeitos de forma segura
func _apply_debuff(component, debuff_type, duration, data):
	if component and is_instance_valid(component) and component.has_method("add_debuff"):
		component.add_debuff(debuff_type, duration, data)

func _apply_movement_slow(component, percent, duration):
	if component and is_instance_valid(component) and component.has_method("apply_slow"):
		component.apply_slow(percent, duration)

func _add_restore_timer(enemy, timer, original_speed):
	if enemy and is_instance_valid(enemy):
		enemy.add_child(timer)
		
		var enemy_ref = weakref(enemy)
		timer.timeout.connect(func():
			var enemy_instance = enemy_ref.get_ref()
			if enemy_instance and is_instance_valid(enemy_instance) and "move_speed" in enemy_instance:
				enemy_instance.set_deferred("move_speed", original_speed)
			if timer and is_instance_valid(timer):
				timer.queue_free()
		)

# Método estático para criar o efeito
static func create_at_position(position: Vector2, parent: Node, shooter = null, settings: Dictionary = {}) -> PersistentPressureWaveProcessor:
	if not parent or not is_instance_valid(parent):
		return null
	
	# Criar em dois passos para evitar problemas de física
	# 1. Criar primeiro sem configuração completa
	var wave = PersistentPressureWaveProcessor.new()
	wave.name = "PressistentPressureWave"
	wave.position = position
	wave.shooter = shooter
	
	# 2. Aplicar configurações básicas (não envolvem física)
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
	
	# 3. Usar call_deferred do nó pai para adicionar com segurança
	if parent.has_method("call_deferred"):
		parent.call_deferred("add_child", wave)
	else:
		# Fallback se não puder usar call_deferred
		parent.add_child(wave)
	
	return wave
