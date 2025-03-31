extends Node
class_name RainArrowProcessor

# Configuraçao da trajetória
var start_position: Vector2          # Posição inicial da flecha
var target_position: Vector2         # Posição alvo onde a flecha cairá
var arc_height: float = 150.0        # Altura máxima do arco (ajustável)
var arrow_speed: float = 500.0       # Velocidade da flecha
var total_time: float                # Tempo total de voo (calculado)
var elapsed_time: float = 0.0        # Tempo decorrido

# Referências
var arrow: Node                      # Referência à flecha pai
var shadow: Node2D                   # Referência à sombra de previsão
var show_shadow: bool = true         # Mostrar uma sombra antes da flecha cair?
var shadow_preview_time: float = 0.5 # Quanto tempo a sombra aparece antes da flecha?

# Efeitos visuais
var impact_particles: bool = true    # Criar partículas ao atingir o solo?

func _ready():
	# Obtém referência à flecha pai
	arrow = get_parent()
	if not arrow:
		push_error("RainArrowProcessor: Arrow parent not found!")
		queue_free()
		return
		
	# Imprimir uma mensagem para confirmar que o NOVO processador está sendo usado
	print("Novo RainArrowProcessor ativado")

	# Obtém configurações da trajetória
	_initialize_trajectory()
	
	# Cria a sombra de previsão se necessário
	if show_shadow:
		_create_target_shadow()
	
	# Desativa física e colisões no início
	_prepare_arrow_for_arc()

func _physics_process(delta):
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
	
	# Ativa colisões APENAS no impacto, não antes
	# Removemos a ativação em 0.8 para evitar dano prematuro
	
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
	shadow.name = "ArrowShadow"
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
		if "direction" in arrow:
			arrow.direction = direction
			
		# Atualiza a rotação visual
		arrow.rotation = direction.angle()

# Verifica se as colisões da flecha estão habilitadas
func _has_collisions_enabled() -> bool:
	if arrow.has_node("Hurtbox"):
		var hurtbox = arrow.get_node("Hurtbox")
		return hurtbox.monitoring
	return false

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
		
# Processa o impacto no destino
func _handle_impact():
	# Remover a sombra se existir
	if shadow and is_instance_valid(shadow):
		var fade_out = shadow.create_tween()
		fade_out.tween_property(shadow, "modulate:a", 0.0, 0.2)
		fade_out.tween_callback(shadow.queue_free)
		shadow = null
	
	# Cria efeito de impacto
	if impact_particles:
		_create_impact_effect()
	
	# Aplica dano a inimigos próximos (usando lógica padrão da flecha)
	if arrow.has_method("process_on_hit"):
		# Busca inimigos por perto
		var enemies = _find_enemies_at_impact()
		for enemy in enemies:
			arrow.process_on_hit(enemy)
	
	# Agenda retorno ao pool ou destruição
	var cleanup_delay = 0.1
	get_tree().create_timer(cleanup_delay).timeout.connect(func():
		if arrow and is_instance_valid(arrow):
			# Tenta retornar ao pool se for um objeto pooled
			if arrow.has_method("return_to_pool") and arrow.has_meta("pooled") and arrow.get_meta("pooled"):
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
	
	return enemies

# Cria um efeito visual de impacto
func _create_impact_effect():
	if not arrow or not is_instance_valid(arrow) or not arrow.get_parent():
		return
		
	var parent = arrow.get_parent()
	
	# Cria nó de impacto
	var impact = Node2D.new()
	impact.name = "ArrowImpact"
	impact.global_position = arrow.global_position
	parent.add_child(impact)
	
	# Adiciona partículas
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
	
	# Auto-destruição após efeito
	impact.create_tween().tween_callback(func(): impact.queue_free()).set_delay(1.0)
