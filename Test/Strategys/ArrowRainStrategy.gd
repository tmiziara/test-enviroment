extends BaseProjectileStrategy
class_name ArrowRainStrategy

@export var arrow_count: int = 5          # Número de flechas na chuva
@export var damage_per_arrow: int = 3     # Dano causado por cada flecha
@export var radius: float = 50.0          # Raio da área afetada
@export var min_height: float = 200.0     # Altura mínima de spawn das flechas
@export var max_height: float = 250.0     # Altura máxima de spawn das flechas
@export var rain_attack_cooldown: float = 1.5  # Novo cooldown para o ataque de chuva
@export var impact_radius: float = 25.0   # Raio da área de impacto de cada flecha

# Armazena os cooldowns originais para restaurar depois
var original_cooldowns = {}

func _on_destroy_timer_timeout(arrow):
	if arrow and is_instance_valid(arrow):
		arrow.queue_free()

# Executado quando uma flecha chega ao seu ponto de impacto
func on_arrow_impact(impact_position, arrow, shadow, shooter):
	# Busca inimigos dentro da área de impacto
	var space_state = arrow.get_world_2d().direct_space_state
	
	# Configura o shape query para buscar inimigos na área de impacto
	var query = PhysicsShapeQueryParameters2D.new()
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = impact_radius
	query.shape = circle_shape
	query.transform = Transform2D(0, impact_position)
	query.collision_mask = 2  # Camada de colisão dos inimigos
	
	# Executa a busca por sobreposição
	var results = space_state.intersect_shape(query)
	
	# Para cada inimigo na zona de impacto
	for result in results:
		var body = result.collider
		if body.is_in_group("enemies") and body.has_node("HealthComponent"):
			var health = body.get_node("HealthComponent")
			
			# Aplica dano conforme o pacote de dano da flecha
			if arrow.has_method("get_damage_package"):
				var damage_package = arrow.get_damage_package()
				health.take_complex_damage(damage_package)
			else:
				# Fallback para método básico de dano
				health.take_damage(arrow.damage, arrow.is_crit)
	
	# Cria efeito visual de impacto
	create_impact_effect(impact_position)
	
	# Remove a sombra - garantindo que o tween seja interrompido antes
	if shadow and is_instance_valid(shadow):
		# Interrompe o tween (se existir)
		if shadow.has_meta("tween"):
			var shadow_tween = shadow.get_meta("tween")
			if shadow_tween and is_instance_valid(shadow_tween):
				shadow_tween.kill()  # Interrompe o tween
		shadow.queue_free()
	
	# Destroi a flecha
	if arrow and is_instance_valid(arrow):
		arrow.queue_free()

# Cria um efeito visual no ponto de impacto
func create_impact_effect(position):
	# Implementação básica - você pode expandir conforme necessário
	pass

# Cria uma sombra no ponto de impacto
func create_shadow_at_impact(impact_position, parent_node):
	# Cria o nó da sombra
	var shadow = Node2D.new()
	shadow.name = "ImpactShadow"
	
	# Cria o sprite da sombra como um círculo preto simples
	var shadow_sprite = Sprite2D.new()
	
	# Cria uma imagem preta redonda
	var img = Image.create(16, 16, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))  # Inicialmente transparente
	
	# Desenha um círculo preto
	for x in range(16):
		for y in range(16):
			# Distância normalizada do centro
			var dx = (x - 8) / 8.0
			var dy = (y - 8) / 8.0
			var dist = sqrt(dx*dx + dy*dy)
			
			# Se estiver dentro do círculo
			if dist <= 1.0:
				# Intensidade baseada na distância do centro
				var alpha = 0.4 * (1.0 - dist)
				img.set_pixel(x, y, Color(0, 0, 0, alpha))
	
	# Cria uma textura a partir da imagem
	var texture = ImageTexture.create_from_image(img)
	shadow_sprite.texture = texture
	
	# Define o tamanho da sombra
	shadow_sprite.scale = Vector2(0.8, 0.5)  # Formato oval maior
	
	# Adiciona o sprite à sombra
	shadow.add_child(shadow_sprite)
	
	# Posiciona a sombra
	shadow.global_position = impact_position
	
	# Ajusta z_index para ficar abaixo de tudo
	shadow.z_index = -10
	
	# Adiciona a sombra à cena
	parent_node.add_child(shadow)
	
	# Adiciona um efeito de "piscar" com número limitado de loops
	var tween = parent_node.create_tween()
	tween.tween_property(shadow_sprite, "modulate:a", 0.8, 0.2)
	tween.tween_property(shadow_sprite, "modulate:a", 0.3, 0.2)
	
	# Define um número específico de loops (10 é mais que suficiente)
	tween.set_loops(10)
	
	# Armazena a referência do tween no nó de sombra para poder interrompê-lo depois
	shadow.set_meta("tween", tween)
	
	return shadow

# Função para estender o _physics_process da flecha
func add_custom_physics_process(arrow, impact_position, fall_time):
	# Criar um script customizado para substituir o comportamento padrão
	var custom_script = GDScript.new()
	custom_script.source_code = """
	extends Node
	
	var start_position: Vector2
	var impact_position: Vector2
	var total_time: float
	var elapsed_time: float = 0.0
	
	func _ready():
		var arrow = get_parent()
		start_position = arrow.global_position
		
		# Armazena a posição original para cálculos
		if arrow.has_meta("impact_position"):
			impact_position = arrow.get_meta("impact_position")
		
		if arrow.has_meta("fall_time"):
			total_time = arrow.get_meta("fall_time")
			
		# Define imediatamente a direção correta da flecha
		var direction = (impact_position - start_position).normalized()
		arrow.direction = direction
		
		# Aplica a rotação correta no início
		# IMPORTANTE: A flecha deve apontar na direção do movimento
		arrow.rotation = direction.angle()
		
		# Ajusta qualquer deslocamento do sprite se necessário
		# Isso depende de como o sprite da flecha está orientado
		# Para uma flecha que aponta para a direita por padrão
		if direction.x < 0:
			# Se a flecha vai para a esquerda
			arrow.get_node("Sprite2D").flip_h = true
	
	func _physics_process(delta):
		var arrow = get_parent()
		
		# Incrementa o tempo decorrido
		elapsed_time += delta
		
		# Calcula a porcentagem de progresso (0 a 1)
		var progress = min(elapsed_time / total_time, 1.0)
		
		# Interpolação linear da posição
		var new_position = start_position.lerp(impact_position, progress)
		
		# Adiciona efeito de arco para movimento mais natural
		var arc_height = start_position.distance_to(impact_position) * 0.05
		var arc_offset = sin(progress * PI) * arc_height
		
		# Aplica o offset do arco à posição Y
		new_position.y -= arc_offset
		
		# Atualiza a posição da flecha
		arrow.global_position = new_position
		
		# Calcula a direção atual baseada no próximo ponto da trajetória
		# Usando um pequeno offset para calcular a direção tangente à curva
		var next_progress = min(progress + 0.01, 1.0)
		var next_position = start_position.lerp(impact_position, next_progress)
		
		# Adiciona o mesmo efeito de arco ao próximo ponto
		var next_arc_offset = sin(next_progress * PI) * arc_height
		next_position.y -= next_arc_offset
		
		# Calcula a direção tangente
		var direction = (next_position - arrow.global_position).normalized()
		
		# Atualiza a direção e rotação apenas se a direção for significativa
		if direction.length() > 0.1:
			arrow.direction = direction
			arrow.rotation = direction.angle()
		
		# Se chegou ao destino, termina o movimento
		if progress >= 1.0:
			# A flecha deve estar exatamente na posição de impacto
			arrow.global_position = impact_position
			set_physics_process(false)
	"""
	
	# Adiciona o script como um nó filho
	var custom_processor = Node.new()
	custom_processor.name = "CustomPhysicsProcessor"
	custom_processor.set_script(custom_script)
	
	# Armazena dados importantes como metadados
	arrow.set_meta("impact_position", impact_position)
	arrow.set_meta("fall_time", fall_time)
	
	arrow.add_child(custom_processor)
	
	# Desativa o processamento físico original da flecha
	arrow.set_physics_process(false)

func spawn_rain_arrows(projectile: Node):
	var shooter = projectile.shooter
	if not shooter:
		return
	# Obtém as outras estratégias para aplicar
	var other_strategies = []
	if "attack_upgrades" in shooter:
		for strategy in shooter.attack_upgrades:
			if not strategy is ArrowRainStrategy:
				other_strategies.append(strategy)
	
	# Captura informações do projétil original
	var original_damage = projectile.damage if "damage" in projectile else 10
	var original_crit_chance = projectile.crit_chance if "crit_chance" in projectile else 0.1
	var original_tags = projectile.tags.duplicate() if "tags" in projectile else []
	
	# Captura dados do calculador de dano
	var original_dmg_calc_data = {}
	if projectile.has_node("DmgCalculatorComponent"):
		var dmg_calc = projectile.get_node("DmgCalculatorComponent")
		original_dmg_calc_data = {
			"base_damage": dmg_calc.base_damage if "base_damage" in dmg_calc else original_damage,
			"elemental_damage": dmg_calc.elemental_damage if "elemental_damage" in dmg_calc else {},
			"dot_effects": dmg_calc.dot_effects if "dot_effects" in dmg_calc else []
		}
	
	# Define a posição do alvo
	var target_position = Vector2.ZERO
	var target = null
	
	# Encontra o alvo
	if shooter.has_method("get_current_target"):
		target = shooter.get_current_target()
	elif "current_target" in shooter:
		target = shooter.current_target
	
	# Define a posição do alvo
	if target and is_instance_valid(target):
		target_position = target.global_position
	else:
		# Fallback: usa a direção do projétil
		target_position = projectile.global_position + projectile.direction * 300
	
	# Carrega a cena da flecha
	var arrow_scene = preload("res://Test/Projectiles/Archer/Arrow.tscn")
	
	for i in range(arrow_count):
		var arrow = arrow_scene.instantiate()
		
		# Posição de queda com dispersão
		var fall_position = target_position
		
		if arrow_count > 1:
			# Gera um vetor de offset dentro de um círculo verdadeiro
			var angle = randf() * TAU  # Ângulo aleatório completo
			var rand_radius = sqrt(randf()) * radius  # Distribuição uniforme dentro do círculo
			
			var random_offset = Vector2(
				cos(angle) * rand_radius,
				sin(angle) * rand_radius
			)
			
			fall_position += random_offset
		
		# IMPORTANTE: Define a posição de impacto imediatamente
		var impact_position = fall_position
		
		# Cria uma sombra no ponto de impacto
		var shadow = create_shadow_at_impact(impact_position, shooter.get_parent())
		
		# Altura inicial de spawn
		var random_height = randf_range(min_height, max_height)
		
		# Posição inicial com um deslocamento horizontal aleatório para variar o ângulo de queda
		var horizontal_offset = randf_range(-50, 50)
		arrow.global_position = Vector2(fall_position.x + horizontal_offset, fall_position.y - random_height)
		
		# Configurações básicas da flecha
		arrow.damage = damage_per_arrow
		arrow.crit_chance = original_crit_chance
		arrow.shooter = shooter
		arrow.speed = 500.0  # Velocidade padrão, será ignorada pelo nosso sistema customizado
		
		# A direção inicial (será substituída pelo sistema de movimento personalizado)
		var initial_direction = (impact_position - arrow.global_position).normalized()
		arrow.direction = initial_direction
		
		# Definir a rotação inicial baseada na direção para o ponto de impacto
		arrow.rotation = initial_direction.angle()
		
		# Adiciona tag para identificação
		arrow.add_tag("rain_arrow")
		
		# Transfere tags originais
		for tag in original_tags:
			if not tag in arrow.tags:
				arrow.add_tag(tag)
		
		# Configura o calculador de dano
		if arrow.has_node("DmgCalculatorComponent"):
			var dmg_calc = arrow.get_node("DmgCalculatorComponent")
			
			if original_dmg_calc_data:
				# Configura dano base
				dmg_calc.base_damage = original_dmg_calc_data.get("base_damage", original_damage)
				
				# Copia danos elementais
				var original_elemental_damage = original_dmg_calc_data.get("elemental_damage", {})
				if original_elemental_damage:
					for element in original_elemental_damage:
						dmg_calc.add_damage_modifier("elemental_damage", 
							{element: original_elemental_damage[element]})
				
				# Copia efeitos DoT
				var original_dot_effects = original_dmg_calc_data.get("dot_effects", [])
				for effect in original_dot_effects:
					# Configura os efeitos DoT
					dmg_calc.add_dot_effect(
						effect.get("damage", 0),
						effect.get("duration", 3.0),
						effect.get("interval", 1.0),
						effect.get("type", "generic")
					)
		
		# IMPORTANTE: Desativa TODAS as colisões da flecha
		
		# 1. Desativa a hurtbox
		if arrow.has_node("Hurtbox"):
			var hurtbox = arrow.get_node("Hurtbox")
			hurtbox.monitoring = false
			hurtbox.monitorable = false
		
		# 2. Desativa a colisão do próprio CharacterBody2D
		if arrow is CharacterBody2D:
			# Desativa temporariamente todas as colisões
			arrow.collision_layer = 0
			arrow.collision_mask = 0
			
			# Desativa todos os collisionshapes
			for child in arrow.get_children():
				if child is CollisionShape2D or child is CollisionPolygon2D:
					child.disabled = true
		
		# Calcula o tempo estimado até o impacto baseado na distância
		var fall_distance = arrow.global_position.distance_to(impact_position)
		var fall_time = fall_distance / arrow.speed
		
		# 3. Substitui a física padrão por um movimento controlado que atinge exatamente o alvo
		add_custom_physics_process(arrow, impact_position, fall_time)
		
		# Aplica outras estratégias (exceto ArrowRainStrategy para evitar recursão)
		for strategy in other_strategies:
			if strategy and is_instance_valid(strategy):
				strategy.apply_upgrade(arrow)
		
		# Adiciona à cena
		shooter.get_parent().add_child(arrow)
		
		# Cria um timer para aplicar o dano na área de impacto quando a flecha "atingir" o solo
		var impact_timer = Timer.new()
		impact_timer.one_shot = true
		impact_timer.wait_time = fall_time
		arrow.add_child(impact_timer)
		
		# Referências fracas para evitar captura de lambdas que causam erros
		var arrow_ref = weakref(arrow)
		var shadow_ref = weakref(shadow)
		var shooter_ref = weakref(shooter)
		
		impact_timer.timeout.connect(func():
			var arrow_inst = arrow_ref.get_ref()
			var shadow_inst = shadow_ref.get_ref()
			var shooter_inst = shooter_ref.get_ref()
			
			if arrow_inst and shadow_inst and shooter_inst:
				on_arrow_impact(impact_position, arrow_inst, shadow_inst, shooter_inst)
				
			# Auto-limpeza do timer
			impact_timer.queue_free()
		)
		impact_timer.start()
		
		# Adiciona um timer adicional para destruir a flecha por segurança
		var destroy_timer = Timer.new()
		destroy_timer.one_shot = true
		destroy_timer.wait_time = fall_time + 0.5
		arrow.add_child(destroy_timer)
		
		destroy_timer.timeout.connect(func():
			var arrow_inst = arrow_ref.get_ref()
			if arrow_inst:
				_on_destroy_timer_timeout(arrow_inst)
				
			# Auto-limpeza do timer
			destroy_timer.queue_free()
		)
		destroy_timer.start()

func apply_upgrade(projectile: Node) -> void:
	# Spawna as flechas de chuva
	spawn_rain_arrows(projectile)
	
	# Remove o projétil original
	projectile.queue_free()
