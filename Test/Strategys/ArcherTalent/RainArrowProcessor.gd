extends Node
class_name RainArrowProcessor

# Configuração da trajetória
var start_position: Vector2          # Posição inicial da flecha
var target_position: Vector2         # Posição alvo onde a flecha cairá
var arc_height: float = 150.0        # Altura máxima do arco (ajustável)
var arrow_speed: float = 500.0       # Velocidade da flecha
var total_time: float                # Tempo total de voo (calculado)
var elapsed_time: float = 0.0        # Tempo decorrido

# Referências
var arrow: NewArrow                  # Referência à flecha pai
var shadow: Node2D                   # Referência à sombra de previsão
var show_shadow: bool = true         # Mostrar uma sombra antes da flecha cair?
var shadow_preview_time: float = 0.5 # Quanto tempo a sombra aparece antes da flecha?
var has_hit: bool = false            # Flag para evitar processamento duplicado

# Efeitos visuais
var impact_particles: bool = true    # Criar partículas ao atingir o solo?
var initialization_completed: bool = false # Flag para confirmar inicialização completa

# Identificador único para este processador
var processor_id: String = ""

func _init():
	# Gera um ID único para cada processador
	processor_id = str(Time.get_ticks_msec()) + "_" + str(randi() % 10000)

func _ready():
	# Obtém referência à flecha pai
	arrow = get_parent()
	if not arrow or not is_instance_valid(arrow):
		queue_free()
		return
		
	# PROTEÇÃO CONTRA DUPLICAÇÃO: Verifica se a flecha já tem um processador
	if arrow.has_meta("active_rain_processor_id"):
		var existing_id = arrow.get_meta("active_rain_processor_id")
		print("WARNING: Arrow already has processor ID: ", existing_id)
		queue_free()
		return
		
	# Marca esta flecha como tendo um processador ativo
	arrow.set_meta("active_rain_processor_id", processor_id)
		
	# Obtém configurações da trajetória
	_initialize_trajectory()
	
	# Cria a sombra de previsão se necessário
	if show_shadow:
		_create_target_shadow()
	
	# Desativa física e colisões no início
	_prepare_arrow_for_arc()
	
	# Adiciona um timer de segurança para auto-destruição se algo der errado
	var safety_timer = Timer.new()
	safety_timer.name = "SafetyTimer"
	safety_timer.wait_time = total_time * 2.0  # O dobro do tempo esperado
	safety_timer.one_shot = true
	safety_timer.autostart = true
	safety_timer.timeout.connect(_safety_timeout)
	add_child(safety_timer)
	
	print("Initialized rain arrow processor for ", arrow, " with ID: ", processor_id)
	initialization_completed = true
	print("Starting initialization of RainArrowProcessor for ", get_parent(), " with ", get_path())

func _safety_timeout():
	print("Safety timeout reached for processor: ", processor_id)
	if arrow and is_instance_valid(arrow):
		if arrow.has_meta("active_rain_processor_id") and arrow.get_meta("active_rain_processor_id") == processor_id:
			arrow.remove_meta("active_rain_processor_id")
		
		if arrow.is_pooled():
			arrow.return_to_pool()
		else:
			arrow.queue_free()
	queue_free()

func _physics_process(delta):
	# Verificação de segurança - se a flecha não for válida, remove o processador
	if not arrow or not is_instance_valid(arrow):
		queue_free()
		return
	
	# Atualiza o tempo decorrido
	elapsed_time += delta
	
	# Calcula o progresso (0 a 1)
	var progress = min(elapsed_time / total_time, 1.0)
	
	# Calcula a nova posição seguindo um arco
	var new_position = _calculate_arc_position(progress)
	
	# Atualiza a posição da flecha
	arrow.global_position = new_position
	
	# Atualiza a rotação para seguir a trajetória
	_update_arrow_rotation(progress)
	
	# Processa o impacto se chegou ao destino
	if progress >= 0.99:
		# Habilita colisões APENAS no momento do impacto
		_enable_arrow_collisions()
		_handle_impact()
		set_physics_process(false)

# Inicializa a configuração da trajetória
func _initialize_trajectory():
	# Tenta obter os parâmetros de trajetória dos metadados da flecha
	if arrow.has_meta("rain_start_pos"):
		start_position = arrow.get_meta("rain_start_pos")
	else:
		start_position = arrow.global_position
	
	if arrow.has_meta("rain_target_pos"):
		target_position = arrow.get_meta("rain_target_pos")
	else:
		# Usa a posição atual + direção se não houver alvo definido
		target_position = arrow.global_position + arrow.direction * 300
	
	# Configurações do arco
	if arrow.has_meta("rain_arc_height"):
		arc_height = arrow.get_meta("rain_arc_height")
		
	# Adiciona um pouco de variação aleatória à altura
	arc_height += randf_range(-20, 20)
	
	# Calcula o tempo total baseado na distância
	var direct_distance = start_position.distance_to(target_position)
	var arc_path_factor = 1.6  # O caminho do arco é mais longo que a linha direta
	total_time = (direct_distance * arc_path_factor) / arrow_speed
	
	# Armazena para uso posterior
	if arrow.has_meta("rain_time"):
		total_time = arrow.get_meta("rain_time")
	print("_initialize_trajectory a flecha é ", arrow, " com ID: ", processor_id)

# Prepara a flecha para a trajetória em arco
func _prepare_arrow_for_arc():
	# Desativa física integrada
	arrow.set_physics_process(false)
	
	# Desativa colisões
	if arrow.has_node("Hurtbox"):
		var hurtbox = arrow.get_node("Hurtbox")
		hurtbox.set_deferred("monitoring", false)
		hurtbox.set_deferred("monitorable", false)
	
	# Desativa layers de colisão
	if arrow is CollisionObject2D:
		arrow.set_deferred("collision_layer", 0)
		arrow.set_deferred("collision_mask", 0)

# Cria uma sombra que mostra onde a flecha cairá
func _create_target_shadow():
	if not arrow or not arrow.get_parent():
		return
		
	var parent_node = arrow.get_parent()
	
	# Cria o nó de sombra
	shadow = Node2D.new()
	shadow.name = "ArrowShadow_" + processor_id
	shadow.global_position = target_position
	shadow.z_index = -1
	shadow.modulate = Color(1, 1, 1, 0)  # Começa invisível
	
	# Adiciona script de desenho para a sombra
	var draw_script = GDScript.new()
	draw_script.source_code = """
	extends Node2D
	
	var pulse_phase = 0.0
	
	func _process(delta):
		pulse_phase += delta * 5.0  # Velocidade de pulsação
		modulate.a = 0.3 + 0.2 * sin(pulse_phase)  # Pulsa entre 0.1 e 0.5 de alfa
		queue_redraw()
		
	func _draw():
		# Círculo externo (sombra)
		draw_circle(Vector2.ZERO, 6, Color(0, 0, 0, 0.3))
		
		# Círculo interno mais escuro
		draw_circle(Vector2.ZERO, 3, Color(0, 0, 0, 0.5))
		
		# Cruz para marcar o ponto
		var cross_size = 5
		draw_line(Vector2(-cross_size, 0), Vector2(cross_size, 0), Color(0.8, 0, 0, 0.7), 1.0)
		draw_line(Vector2(0, -cross_size), Vector2(0, cross_size), Color(0.8, 0, 0, 0.7), 1.0)
	"""
	
	var visual = Node2D.new()
	visual.set_script(draw_script)
	shadow.add_child(visual)
	
	# Adiciona à cena
	parent_node.add_child(shadow)
	
	# Anima a entrada da sombra
	var fade_in = shadow.create_tween()
	fade_in.tween_property(shadow, "modulate:a", 1.0, 0.2)
	
	# Configura tamanho de pulso
	var pulse = shadow.create_tween()
	pulse.tween_property(shadow, "scale", Vector2(1.2, 1.2), 0.4)
	pulse.tween_property(shadow, "scale", Vector2(0.9, 0.9), 0.4)
	pulse.set_loops()

# Calcula posição do arco com base no progresso (0-1)
func _calculate_arc_position(progress: float) -> Vector2:
	# Interpolação linear para X e Z
	var pos = start_position.lerp(target_position, progress)
	
	# Adiciona arco usando função de seno - ajustada para um arco mais alto e visível
	var arc_factor = sin(progress * PI)  # Forma uma curva de sino
	
	# Multiplica por 1.5 para garantir que o arco seja bem visível
	var height_offset = arc_height * arc_factor * 1.5
	
	# Subtrai do Y para subir (em coordenadas 2D, Y aumenta para baixo)
	pos.y -= height_offset
	return pos

# Atualiza a rotação da flecha para apontar na direção do movimento
func _update_arrow_rotation(current_progress: float):
	# Calcula a próxima posição para obter a direção
	var next_progress = min(current_progress + 0.05, 1.0)
	var current_pos = _calculate_arc_position(current_progress)
	var next_pos = _calculate_arc_position(next_progress)
	
	# Direção do movimento
	var direction = (next_pos - current_pos).normalized()
	
	# Só atualiza se a direção for significativa
	if direction.length_squared() > 0.01:
		# Atualiza a direção interna da flecha
		arrow.direction = direction
		
		# Atualiza a rotação visual
		arrow.rotation = direction.angle()

# Habilita as colisões da flecha perto do impacto
func _enable_arrow_collisions():
	if arrow.has_node("Hurtbox"):
		var hurtbox = arrow.get_node("Hurtbox")
		hurtbox.set_deferred("monitoring", true)
		hurtbox.set_deferred("monitorable", true)
	
	# Reativa camadas de colisão
	if arrow is CollisionObject2D:
		arrow.set_deferred("collision_layer", 4)  # Layer de projétil 
		arrow.set_deferred("collision_mask", 2)   # Layer de inimigo
	print("_enable_arrow_collisions a flecha é ", arrow, " com ID: ", processor_id)

# Processa o impacto no destino
func _handle_impact():
	# Previne processamento duplicado
	if has_hit:
		return
	has_hit = true
	
	# Remover a sombra se existir
	if shadow and is_instance_valid(shadow):
		var fade_out = shadow.create_tween()
		fade_out.tween_property(shadow, "modulate:a", 0.0, 0.2)
		fade_out.tween_callback(shadow.queue_free)
		shadow = null
	
	# Cria efeito de impacto
	if impact_particles:
		_create_impact_effect()
		
	# Aplica dano a inimigos próximos 
	var enemies = _find_enemies_at_impact()
	for enemy in enemies:
		# Usa o método on_hit do Arrow para garantir processamento completo
		arrow.process_on_hit(enemy)
		
		# Aplica efeito de pressure wave se habilitado (Talent 14)
		if arrow.has_meta("pressure_wave_enabled"):
			_apply_pressure_wave(enemy)
	print("_handle_impact a flecha é ", arrow, " com ID: ", processor_id)
	
	# Agenda retorno ao pool ou destruição
	var cleanup_delay = 0.1
	get_tree().create_timer(cleanup_delay).timeout.connect(func():
		if arrow and is_instance_valid(arrow):
			# Remove o ID de processador ativo antes de retornar
			if arrow.has_meta("active_rain_processor_id") and arrow.get_meta("active_rain_processor_id") == processor_id:
				arrow.remove_meta("active_rain_processor_id")
				
			# Verifica se é um objeto pooled
			if arrow.is_pooled():
				arrow.return_to_pool()
			else:
				arrow.queue_free()
		
		# Auto-destruição do processador
		queue_free()
	)

# Encontra inimigos no ponto de impacto
func _find_enemies_at_impact() -> Array:
	var enemies = []
	
	if not arrow or not is_instance_valid(arrow):
		return enemies
	
	# Raio de detecção
	var detection_radius = 15.0
	
	# Configura a query de física
	var space_state = arrow.get_world_2d().direct_space_state
	var query = PhysicsShapeQueryParameters2D.new()
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = detection_radius
	query.shape = circle_shape
	query.transform = Transform2D(0, arrow.global_position)
	query.collision_mask = 2  # Layer de inimigos
	
	# Executa a query
	var results = space_state.intersect_shape(query)
	
	# Filtra os resultados
	for result in results:
		var body = result.collider
		if (body.is_in_group("enemies") or body.get_collision_layer_value(2)) and body.has_node("HealthComponent"):
			enemies.append(body)
	print("_find_enemies_at_impact a flecha é ", arrow, " com ID: ", processor_id)
	return enemies

# Cria um efeito visual de impacto
func _create_impact_effect():
	if not arrow or not is_instance_valid(arrow) or not arrow.get_parent():
		return
		
	var parent = arrow.get_parent()
	
	# Cria nó de impacto
	var impact = Node2D.new()
	impact.name = "ArrowImpact_" + processor_id
	impact.global_position = arrow.global_position
	parent.add_child(impact)
	
	# Cria partículas manualmente para maior compatibilidade
	var particles = CPUParticles2D.new()
	impact.add_child(particles)
	
	# Configura partículas
	particles.emitting = true
	particles.one_shot = true
	particles.explosiveness = 0.8
	particles.amount = 12
	particles.lifetime = 0.5
	particles.direction = Vector2.DOWN
	particles.spread = 180
	particles.initial_velocity_min = 30
	particles.initial_velocity_max = 60
	particles.gravity = Vector2(0, 98)
	particles.scale_amount_min = 2.0
	particles.scale_amount_max = 2.0
	particles.color = Color(0.8, 0.8, 0.8)
	print("_create_impact_effect a flecha é ", arrow, " com ID: ", processor_id)
	
	# Auto-destruição após efeito
	impact.create_tween().tween_callback(func(): impact.queue_free()).set_delay(1.0)

# Aplica o efeito Pressure Wave (Talent 14)
func _apply_pressure_wave(target: Node) -> void:
	# Verifica se o projétil tem os metadados necessários
	if not arrow.has_meta("pressure_wave_enabled"):
		return
	
	# Obtém os parâmetros de configuração
	var knockback_force = arrow.get_meta("knockback_force", 150.0)
	var slow_percent = arrow.get_meta("slow_percent", 0.3)
	var slow_duration = arrow.get_meta("slow_duration", 0.5)
	var wave_visual_enabled = arrow.get_meta("wave_visual_enabled", true)
	var ground_duration = arrow.get_meta("ground_duration", 3.0)
	
	# Aplicar knockback imediatamente se houver alvo
	if target != null and is_instance_valid(target):
		# Pegar posição da flecha - correção-chave
		var arrow_position = arrow.global_position
		
		# Calcular direção do knockback (afastando do ponto de impacto)
		var knockback_direction = (target.global_position - arrow_position).normalized()
		# Aplicar knockback diretamente se disponível
		if target.has_node("MovementControlComponent"):
			var movement_control = target.get_node("MovementControlComponent")
			if movement_control.has_method("apply_knockback"):
				movement_control.apply_knockback(knockback_direction, knockback_force)
		elif target is CharacterBody2D:
			# Modificação direta da velocidade como fallback
			target.velocity += knockback_direction * knockback_force
	
	
	# Cria o efeito de área persistente que afeta APENAS com slow (não knockback)
	if wave_visual_enabled:
		var parent = arrow.get_parent()
		if parent:
			# Configurações para o efeito
			var settings = {
				"duration": ground_duration,
				"slow_percent": slow_percent,
				"slow_duration": slow_duration,
				"knockback_force": 0.0,  # Remove knockback for the area effect
				"only_slow": true  # Flag específica para indicar apenas slow (não knockback)
			}
			# Usar diretamente a classe para criar
			var wave = PersistentPressureWaveProcessor.create_at_position(
				arrow.global_position, 
				parent, 
				arrow.shooter, 
				settings
			)

func _exit_tree():
	# Perform any necessary cleanup when this processor is being removed
	print("RainArrowProcessor being removed from ", get_parent(), " with ID: ", processor_id)
	
	var arrow = get_parent()
	if is_instance_valid(arrow):
		# Remove a referência ao processor_id apenas se for deste processador
		if arrow.has_meta("active_rain_processor_id") and arrow.get_meta("active_rain_processor_id") == processor_id:
			arrow.remove_meta("active_rain_processor_id")
		
		print("_exit_tree a flecha é ", arrow, " com ID: ", processor_id)
