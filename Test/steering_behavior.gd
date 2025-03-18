extends Resource
class_name SteeringBehavior

# Parâmetros configuráveis
const AVOIDANCE_STRENGTH = 4.0     # Intensidade da evitação de obstáculos
const AVOIDANCE_DISTANCE = 100.0   # Distância do Raycast para detectar obstáculos
const ARRIVAL_RADIUS = 20.0        # Raio para diminuir a velocidade ao chegar no alvo
const SLOW_RADIUS = 100.0          # Raio para começar a desacelerar

# Persegue um alvo e adiciona influência ao Interest Map
static func seek(context_map: ContextMap, agent_position: Vector2, target_position: Vector2):
	var direction = (target_position - agent_position)
	var distance = direction.length()
	direction = direction.normalized()
	
	# Calcula intensidade baseada na distância (maior se estiver longe)
	var strength = 1.0
	
	# Adiciona ao mapa de interesse
	context_map.add_interest(direction, strength)
	
	return direction

# Evita obstáculos e adiciona perigo ao Danger Map
static func avoid(context_map: ContextMap, agent: CharacterBody2D, space_state, ray_count: int = 12, max_distance: float = 100.0):
	var forward = agent.velocity.normalized() if agent.velocity.length() > 0 else Vector2.RIGHT
	
	# Lança raios em vários ângulos para detectar obstáculos
	for i in range(ray_count):
		# Ângulo distribuído uniformemente ao redor do agente
		var angle = (i / float(ray_count)) * TAU
		var ray_direction = Vector2.RIGHT.rotated(angle)
		
		# Configura parâmetros do raio
		var query = PhysicsRayQueryParameters2D.new()
		query.from = agent.global_position
		query.to = agent.global_position + ray_direction * max_distance
		query.exclude = [agent.get_rid()]  # Exclui o próprio agente
		
		# Executa o raycast
		var result = space_state.intersect_ray(query)
		
		if result:
			# Calcula a distância do obstáculo
			var distance = result.position.distance_to(agent.global_position)
			
			# Função exponencial para dar mais peso a obstáculos muito próximos
			var danger_strength = pow(1.0 - (distance / max_distance), 2) * AVOIDANCE_STRENGTH
			danger_strength = clamp(danger_strength, 0.0, 1.0)
			
			# Adiciona ao mapa de perigo
			context_map.add_danger(ray_direction, danger_strength)
			
			# Adicione este trecho para evitar ficar preso em paredes retas
			# Adiciona perigo extra nas direções adjacentes para paredes muito próximas
			if distance < 30.0:  # Se o obstáculo estiver muito próximo
				# Adiciona perigo nas direções perpendiculares
				var perp1 = ray_direction.rotated(PI/2)
				var perp2 = ray_direction.rotated(-PI/2)
				context_map.add_danger(perp1, danger_strength * 0.7)
				context_map.add_danger(perp2, danger_strength * 0.7)
# Comportamento de chegada para desacelerar ao se aproximar do alvo
static func arrive(context_map: ContextMap, agent_position: Vector2, target_position: Vector2, speed_scale: float = 1.0):
	var direction = target_position - agent_position
	var distance = direction.length()
	direction = direction.normalized()
	
	# Adiciona ao mapa de interesse
	context_map.add_interest(direction, 1.0)
	
	# Calcula o fator de velocidade
	var speed_factor = 1.0
	if distance < ARRIVAL_RADIUS:
		speed_factor = 0.0  # Parar ao chegar no alvo
	elif distance < SLOW_RADIUS:
		speed_factor = distance / SLOW_RADIUS  # Desacelerar gradualmente
	
	return direction * speed_factor * speed_scale

# Fuga - comportamento oposto ao seek
static func flee(context_map: ContextMap, agent_position: Vector2, target_position: Vector2, panic_distance: float = 150.0):
	var direction = agent_position - target_position  # Direção invertida
	var distance = direction.length()
	direction = direction.normalized()
	
	# Só foge se estiver dentro da distância de pânico
	if distance < panic_distance:
		var strength = 1.0 - (distance / panic_distance)
		context_map.add_interest(direction, strength)
	
	return direction

# Manobra para evitar uma colisão iminente
static func emergency_avoid(context_map: ContextMap, agent_position: Vector2, obstacle_position: Vector2, obstacle_radius: float):
	var direction = agent_position - obstacle_position
	var distance = direction.length()
	var combined_radius = obstacle_radius + 20.0  # Adiciona margem de segurança
	
	if distance < combined_radius:
		# Colisão iminente, evasão de emergência
		var strength = 1.0
		context_map.add_interest(direction.normalized(), strength)
		
		# Bloqueia direções para o obstáculo
		var danger_direction = -direction.normalized()
		context_map.add_danger(danger_direction, 1.0)

# Nova função para seguir paredes
static func wall_following(context_map: ContextMap, agent: CharacterBody2D, space_state, wall_distance: float = 40.0):
	var velocity_dir = agent.velocity.normalized()
	if velocity_dir == Vector2.ZERO:
		velocity_dir = Vector2.RIGHT
	
	# Lança raios laterais para detectar paredes
	var left_ray = velocity_dir.rotated(PI/2)
	var right_ray = velocity_dir.rotated(-PI/2)
	
	var query_left = PhysicsRayQueryParameters2D.new()
	query_left.from = agent.global_position
	query_left.to = agent.global_position + left_ray * wall_distance
	query_left.exclude = [agent.get_rid()]
	
	var query_right = PhysicsRayQueryParameters2D.new()
	query_right.from = agent.global_position
	query_right.to = agent.global_position + right_ray * wall_distance
	query_right.exclude = [agent.get_rid()]
	
	var result_left = space_state.intersect_ray(query_left)
	var result_right = space_state.intersect_ray(query_right)
	
	# Se estiver próximo a uma parede à esquerda, tente seguir ao longo dela
	if result_left and not result_right:
		var parallel_dir = velocity_dir.rotated(-PI/4)  # Gira para a direita
		context_map.add_interest(parallel_dir, 0.8)
	
	# Se estiver próximo a uma parede à direita, tente seguir ao longo dela
	elif result_right and not result_left:
		var parallel_dir = velocity_dir.rotated(PI/4)  # Gira para a esquerda
		context_map.add_interest(parallel_dir, 0.8)
	
	# Se estiver em um corredor ou canto
	elif result_right and result_left:
		var front_dir = velocity_dir
		var query_front = PhysicsRayQueryParameters2D.new()
		query_front.from = agent.global_position
		query_front.to = agent.global_position + front_dir * wall_distance
		query_front.exclude = [agent.get_rid()]
		
		var result_front = space_state.intersect_ray(query_front)
		
		# Se tiver parede na frente também, é um canto ou corredor sem saída
		if result_front:
			# Tenta encontrar a direção com mais espaço
			var left_dist = result_left.position.distance_to(agent.global_position)
			var right_dist = result_right.position.distance_to(agent.global_position)
			
			if left_dist > right_dist:
				context_map.add_interest(left_ray, 1.0)
			else:
				context_map.add_interest(right_ray, 1.0)
