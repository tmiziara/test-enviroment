extends Node
class_name RainArrowProcessor

# ======== PROPRIEDADES DE TRAJETÓRIA ========
var start_position: Vector2
var target_position: Vector2
var arc_height: float = 250.0
var total_time: float = 1.0

# ======== PROPRIEDADES DE ONDA DE PRESSÃO ========
var create_pressure_wave: bool = false
var knockback_force: float = 150.0
var slow_percent: float = 0.3
var slow_duration: float = 0.5
var wave_visual_enabled: bool = true
var ground_effect_duration: float = 3.0

# ======== VARIÁVEIS DE CONTROLE ========
var elapsed_time: float = 0.0
var arrow_landed: bool = false
var arrow: Arrow

func _ready():
	# Obtém referência à flecha pai
	arrow = get_parent() as Arrow
	
	if arrow:
		# Desabilita física e colisão inicialmente
		arrow.set_physics_process(false)
		
		if arrow.hitbox:
			arrow.hitbox.set_deferred("monitoring", false)
			arrow.hitbox.set_deferred("monitorable", false)
		
		# Verifica se os dados necessários estão presentes
		if start_position != Vector2.ZERO and target_position != Vector2.ZERO:
			# Tudo bem, inicia a animação de queda
			arrow.global_position = start_position
		else:
			# Tenta obter dados dos metadados
			if arrow.has_meta("rain_start_pos") and arrow.has_meta("rain_target_pos"):
				start_position = arrow.get_meta("rain_start_pos")
				target_position = arrow.get_meta("rain_target_pos")
				
				if arrow.has_meta("rain_arc_height"):
					arc_height = arrow.get_meta("rain_arc_height")
				
				if arrow.has_meta("rain_time"):
					total_time = arrow.get_meta("rain_time")
				
				arrow.global_position = start_position
			else:
				# Sem dados suficientes, remover o processador
				queue_free()
				return
		
		# Configura a direção da flecha para apontar para baixo
		arrow.direction = Vector2(0, 1).normalized()
		arrow.rotation = arrow.direction.angle()
		
		# Adiciona timer de segurança
		var safety_timer = Timer.new()
		safety_timer.wait_time = total_time + 2.0  # Tempo extra de segurança
		safety_timer.one_shot = true
		safety_timer.timeout.connect(func(): _ensure_cleanup())
		add_child(safety_timer)
		safety_timer.start()

func _process(delta):
	if arrow_landed or not arrow or not is_instance_valid(arrow):
		return
	
	# Atualiza tempo decorrido
	elapsed_time += delta
	
	# Calcula progresso normalizado (0 a 1)
	var progress = min(elapsed_time / total_time, 1.0)
	
	if progress >= 1.0:
		# Atingiu o alvo, processa impacto
		_process_landing()
		return
	
	# Interpola posição em arco
	var new_position = _calculate_arc_position(progress)
	
	# Atualiza a posição da flecha
	arrow.global_position = new_position
	
	# Atualiza direção da flecha para acompanhar a trajetória
	if progress < 0.9:  # Mantém apontado para baixo nos últimos 10%
		var next_pos = _calculate_arc_position(min(progress + 0.05, 1.0))
		var direction = (next_pos - arrow.global_position).normalized()
		arrow.direction = direction
		arrow.rotation = direction.angle()
	else:
		# Nos últimos 10%, aponta diretamente para baixo para um impacto mais dramático
		arrow.direction = Vector2(0, 1).normalized()
		arrow.rotation = arrow.direction.angle() + PI/2  # Ajuste para orientação visual da flecha

# Calcula a posição em um arco baseado no progresso (0 a 1)
func _calculate_arc_position(progress: float) -> Vector2:
	# Interpolação linear para movimento horizontal
	var horizontal_pos = start_position.lerp(target_position, progress)
	
	# Cálculo de arco para movimento vertical
	# Parábola invertida: 0 no início, -altura_arco no meio, 0 no fim
	var arc_offset = -4.0 * arc_height * progress * (1.0 - progress)
	
	# Altura inicial e final podem ser diferentes
	var start_y = start_position.y
	var end_y = target_position.y
	
	# Cálculo da altura atual com base no progresso
	var vertical_pos = lerp(start_y, end_y, progress) + arc_offset
	
	return Vector2(horizontal_pos.x, vertical_pos)

# Processa o impacto da flecha no solo
func _process_landing():
	if arrow_landed:
		return
		
	arrow_landed = true
	
	# Posiciona a flecha exatamente no alvo
	arrow.global_position = target_position
	
	# Ativa a física e colisão para permitir hits
	if arrow.hitbox:
		arrow.hitbox.set_deferred("monitoring", true)
		arrow.hitbox.set_deferred("monitorable", true)
	
	# Cria uma pequena explosão visual
	_create_impact_effect()
	
	# Cria onda de pressão se configurado
	if create_pressure_wave:
		_create_pressure_wave()
	
	# Agenda limpeza
	get_tree().create_timer(0.5).timeout.connect(func(): 
		if arrow and is_instance_valid(arrow):
			arrow._prepare_for_destruction()
	)

# Cria efeito visual no impacto
func _create_impact_effect():
	if not arrow or not is_instance_valid(arrow):
		return
		
	# Cria partículas de impacto
	var impact = CPUParticles2D.new()
	impact.emitting = true
	impact.one_shot = true
	impact.explosiveness = 1.0
	impact.amount = 15
	impact.lifetime = 0.5
	impact.direction = Vector2.UP
	impact.spread = 90.0
	impact.gravity = Vector2(0, 98)
	impact.initial_velocity_min = 20.0
	impact.initial_velocity_max = 40.0
	impact.scale_amount_min = 1.0
	impact.scale_amount_max = 2.0
	impact.color = Color(0.8, 0.8, 0.8, 0.8)
	
	impact.position = Vector2.ZERO  # Relativo à seta
	arrow.add_child(impact)

# Cria onda de pressão para knockback/slow
func _create_pressure_wave():
	if not arrow or not is_instance_valid(arrow):
		return
		
	# Carrega script da onda de pressão persistente
	var wave_script = load("res://Test/Processors/PersistentPressureWaveProcessor.gd")
	
	if wave_script:
		# Configura parâmetros da onda
		var settings = {
			"duration": ground_effect_duration,
			"slow_percent": slow_percent,
			"slow_duration": slow_duration,
			"knockback_force": knockback_force,
			"max_radius": 80.0,  # Raio padrão, pode ser ajustado
			"only_slow": false   # Aplica knockback + slow
		}
		
		# Pega a referência do atirador da flecha
		var shooter = arrow.shooter
		
		# Cria a onda de pressão no pai da flecha (para que persista após a flecha)
		if arrow.get_parent():
			# Usa o método estático para criar no local certo
			var wave = wave_script.call("create_at_position", 
				arrow.global_position, 
				arrow.get_parent(), 
				shooter, 
				settings
			)
			
			# Confirma criação bem-sucedida
			if wave:
				# Se necessário, configura propriedades adicionais
				pass
	else:
		print("ERRO: Script de onda de pressão não encontrado")

# Garante limpeza mesmo em caso de problemas
func _ensure_cleanup():
	if arrow and is_instance_valid(arrow):
		arrow._prepare_for_destruction()
	queue_free()
