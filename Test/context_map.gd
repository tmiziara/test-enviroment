extends Resource
class_name ContextMap

const NUM_SLOTS = 32  # Resolução do mapa (quanto maior, mais preciso)
var directions: Array = []
var interest: Array = []
var danger: Array = []

# Parâmetros adicionais para comportamentos mais refinados
var interest_falloff_angle: float = 45.0  # Ângulo de suavização do interesse
var danger_falloff_angle: float = 30.0    # Ângulo de suavização do perigo
var danger_threshold: float = 0.6         # Limite para bloqueio total de direções

func _init():
	for i in range(NUM_SLOTS):
		var angle = (i / float(NUM_SLOTS)) * TAU
		directions.append(Vector2.RIGHT.rotated(angle))  # Direções unitárias
		interest.append(0.0)  # Inicializa mapa de interesse
		danger.append(0.0)  # Inicializa mapa de perigo

# Adiciona influência a um slot do mapa de interesse
func add_interest(direction: Vector2, strength: float):
	var best_index = get_best_direction_index(direction)
	apply_falloff(interest, best_index, strength, interest_falloff_angle)

# Adiciona influência a um slot do mapa de perigo
func add_danger(direction: Vector2, strength: float):
	var best_index = get_best_direction_index(direction)
	apply_falloff(danger, best_index, strength, danger_falloff_angle)

# Normaliza os mapas para evitar valores exagerados
func normalize():
	var max_interest = max_value(interest)
	var max_danger = max_value(danger)
	
	if max_interest > 0:
		for i in range(NUM_SLOTS):
			interest[i] /= max_interest
	
	if max_danger > 0:
		for i in range(NUM_SLOTS):
			danger[i] /= max_danger

# Filtra o mapa de interesse usando o mapa de perigo como máscara
func apply_danger_mask():
	for i in range(NUM_SLOTS):
		# Aplica limiar de perigo - bloqueio total se acima do threshold
		var danger_factor = 1.0 - danger[i]
		if danger[i] > danger_threshold:
			danger_factor = 0.0
			
		interest[i] *= danger_factor

# Encontra o índice da melhor direção no mapa com interpolação
func get_best_direction() -> Vector2:
	var best_index = 0
	var max_value = -INF
	
	# Encontra o slot com o maior interesse
	for i in range(NUM_SLOTS):
		if interest[i] > max_value:
			max_value = interest[i]
			best_index = i
	
	if max_value <= 0:
		return Vector2.ZERO
	
	# Implementa interpolação entre slots para movimentos mais suaves
	var next_slot = (best_index + 1) % NUM_SLOTS
	var prev_slot = (best_index - 1 + NUM_SLOTS) % NUM_SLOTS
	
	var next_interest = interest[next_slot]
	var prev_interest = interest[prev_slot]
	
	var desired_direction = directions[best_index]
	
	# Interpolação baseada em interesse dos slots vizinhos
	if next_interest > prev_interest and next_interest > 0:
		var blend = next_interest / (max_value + next_interest)
		desired_direction = desired_direction.lerp(directions[next_slot], blend * 0.5)
	elif prev_interest > 0:
		var blend = prev_interest / (max_value + prev_interest)
		desired_direction = desired_direction.lerp(directions[prev_slot], blend * 0.5)
	
	return desired_direction

# Aplica um efeito de suavização nos slots adjacentes
func apply_falloff(map: Array, index: int, strength: float, falloff_angle: float):
	var falloff_slots = int(falloff_angle / (360.0 / NUM_SLOTS))
	falloff_slots = clamp(falloff_slots, 1, NUM_SLOTS - 1)  # Evita valores inválidos
	
	# Aplica ao slot central
	map[index] = max(map[index], strength)
	
	# Aplica aos slots adjacentes com degradação
	for i in range(1, falloff_slots + 1):
		var falloff_factor = 1.0 - (float(i) / (falloff_slots + 1))
		var falloff_strength = strength * falloff_factor
		
		var right_slot = (index + i) % NUM_SLOTS
		var left_slot = (index - i + NUM_SLOTS) % NUM_SLOTS
		
		map[right_slot] = max(map[right_slot], falloff_strength)
		map[left_slot] = max(map[left_slot], falloff_strength)

# Encontra o índice da direção mais próxima no array
func get_best_direction_index(direction: Vector2) -> int:
	var best_index = 0
	var best_dot = -INF
	
	direction = direction.normalized()
	for i in range(NUM_SLOTS):
		var dot = direction.dot(directions[i])
		if dot > best_dot:
			best_dot = dot
			best_index = i
	
	return best_index

# Retorna o maior valor em um array
func max_value(array: Array) -> float:
	var max_val = -INF
	for val in array:
		if val > max_val:
			max_val = val
	return max_val

# Gera uma visualização do mapa para debug
func debug_draw(canvas: CanvasItem, position: Vector2, radius: float = 50.0):
	# Desenha círculo de referência
	canvas.draw_arc(position, radius, 0, TAU, 32, Color(0.5, 0.5, 0.5, 0.3), 1.0)
	
	# Desenha mapa de interesse (verde)
	for i in range(NUM_SLOTS):
		var end_point = position + directions[i] * radius * interest[i]
		canvas.draw_line(position, end_point, Color(0, 1, 0, 0.5), 2.0)
	
	# Desenha mapa de perigo (vermelho)
	for i in range(NUM_SLOTS):
		var end_point = position + directions[i] * radius * danger[i]
		canvas.draw_line(position, end_point, Color(1, 0, 0, 0.5), 2.0)
