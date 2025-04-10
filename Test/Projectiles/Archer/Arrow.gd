extends ProjectileBase
class_name Arrow

# ======== PROPRIEDADES ESPECÍFICAS DE FLECHA ========

# Propriedades de Chain Shot
var chain_shot_enabled: bool = false
var chain_chance: float = 0.3
var chain_range: float = 150.0
var chain_damage_decay: float = 0.2
var max_chains: int = 1
var current_chains: int = 0
var hit_targets: Array = []
var will_chain: bool = false
var is_processing_chain: bool = false

# Propriedades de direcionamento
var homing_enabled: bool = false
var homing_strength: float = 5.0
var homing_target = null

# Propriedades visuais
@export var trail_enabled: bool = true
@onready var trail_particles = $TrailEffect if has_node("TrailEffect") else null

func _ready():
	super._ready()
	if dmg_calculator:
		print(dmg_calculator.debug_damage_calculation())
	# Configurações específicas para flechas
	if trail_enabled and trail_particles:
		trail_particles.emitting = true
	
	# Verifica se tem processador de ArrowRain
	if has_meta("is_rain_arrow") and not has_node("RainArrowProcessor"):
		_add_rain_arrow_processor()

func _physics_process(delta):
	# Lógica de Homing (direcionamento)
	if homing_enabled and homing_target and is_instance_valid(homing_target):
		_apply_homing(delta)
	
	# Chama o comportamento padrão de movimento
	super._physics_process(delta)

# ======== MÉTODOS DE HOMING E DIRECIONAMENTO ========
func _apply_homing(delta: float) -> void:
	# Calcula distância ao alvo
	var target_position = homing_target.global_position
	var distance = global_position.distance_to(target_position)
	
	# Aumenta força de homing conforme se aproxima para garantir o acerto
	var adaptive_strength = homing_strength * (1.0 + (500.0 / max(distance, 50.0)))
	
	# Calcula direção ideal para o alvo
	var ideal_direction = (target_position - global_position).normalized()
	
	# Suaviza transição da direção atual para a ideal
	direction = direction.lerp(ideal_direction, delta * adaptive_strength).normalized()
	
	# Atualiza rotação e velocidade
	rotation = direction.angle()
	
	# Opcional: aumenta ligeiramente a velocidade para alcançar alvos em movimento
	speed += delta * 50.0

# ======== MÉTODOS DE PROCESSAMENTO DE HIT ========
func process_on_hit(target: Node) -> void:
	# Verifica se target é válido
	if not target or not is_instance_valid(target):
		return
	
	# Adiciona alvo à lista de alvos atingidos
	if not target in hit_targets:
		hit_targets.append(target)
	
	# Define alvo atual para cálculos de dano
	set_meta("current_target", target)
	
	# Já está processando chain? Evita loops
	if is_processing_chain:
		return
	
	# Processa Chain Shot
	if chain_shot_enabled and current_chains < max_chains:
		# Determina se esta flecha vai encadear apenas na primeira vez
		if current_chains == 0:
			will_chain = randf() <= chain_chance
		
		if will_chain:
			is_processing_chain = true
			call_deferred("find_chain_target", target)
			return
	
	# Processa efeitos especiais
	_process_special_effects(target)
	
	# Para flechas perfurantes, prepara para próximo hit
	if piercing:
		var max_pierce = 1
		
		if has_meta("piercing_count"):
			max_pierce = get_meta("piercing_count")
		
		var current_pierce_count = hit_targets.size() - 1  # -1 porque o primeiro hit não conta como pierce
		
		if current_pierce_count < max_pierce:
			# Prepara para próximo hit
			if hitbox:
				hitbox.set_deferred("monitoring", true)
				hitbox.set_deferred("monitorable", true)
			
			# Move a flecha ligeiramente para evitar ficar presa
			global_position += direction * 10
			return

# Processa efeitos especiais de talentos
func _process_special_effects(target: Node) -> void:
	# Verifica Bloodseeker
	if has_meta("has_bloodseeker_effect") and shooter and is_instance_valid(shooter):
		var should_increment = true
		
		# Casos especiais onde não incrementamos stacks
		if has_meta("is_second_arrow") or current_chains > 0 or has_meta("is_rain_arrow"):
			should_increment = false
		
		if should_increment and shooter.has_method("apply_bloodseeker_hit"):
			shooter.apply_bloodseeker_hit(target)
	
	# Verifica Mark for Death para acertos críticos
	if has_meta("has_mark_effect") and is_crit:
		_apply_mark_effect(target)
	
	# Verifica Bleeding
	if has_meta("has_bleeding_effect") and is_crit:
		_apply_bleeding_effect(target)
	
	# Verifica Explosion
	if has_meta("has_explosion_effect"):
		_create_explosion_effect(target)

# ======== MÉTODOS DE CHAIN SHOT ========
func find_chain_target(original_target) -> void:
	if current_chains >= max_chains:
		will_chain = false
		is_processing_chain = false
		_prepare_for_destruction()
		return
	
	# Aguarda um frame para garantir que o processamento de hit foi concluído
	await get_tree().process_frame
	
	# Inicializa a lista de hit_targets se estiver nula
	if hit_targets == null:
		hit_targets = []
	
	# Adiciona o alvo original à lista se ainda não estiver lá
	if original_target and not original_target in hit_targets:
		hit_targets.append(original_target)
		
	# Busca inimigos próximos que ainda não atingimos
	var space_state = get_world_2d().direct_space_state
	
	# Cria query de círculo
	var query = PhysicsShapeQueryParameters2D.new()
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = chain_range
	query.shape = circle_shape
	query.transform = Transform2D(0, global_position)
	query.collision_mask = 2  # Layer de inimigo
	
	# Executa query
	var results = space_state.intersect_shape(query)
	
	# Filtra e coleta informações de alvos com velocidade
	var target_info = []
	for result in results:
		var body = result.collider
		
		# Pula alvo original e alvos já atingidos
		if body in hit_targets:
			continue
			
		# Verifica se é um inimigo com saúde
		if (body.is_in_group("enemies") or body.get_collision_layer_value(2)) and body.has_node("HealthComponent"):
			# Calcula velocidade do alvo se for um CharacterBody2D
			var target_velocity = Vector2.ZERO
			if body is CharacterBody2D:
				target_velocity = body.velocity
			
			# Armazena alvo com velocidade e posição
			target_info.append({
				"body": body,
				"position": body.global_position,
				"velocity": target_velocity
			})
	
	# Se encontrou pelo menos um alvo válido
	if target_info.size() > 0:
		# Escolhe alvo aleatório
		var target_data = target_info[randi() % target_info.size()]
		var next_target = target_data.body
		var target_position = target_data.position
		var target_velocity = target_data.velocity
		
		# IMPORTANTE: Incrementa contador de chain ANTES de continuar
		current_chains += 1
		set_meta("is_part_of_chain", true)
		
		# Verifica se atingiu o limite de chains
		if current_chains >= max_chains:
			will_chain = false
		
		# Adiciona o novo alvo à lista
		hit_targets.append(next_target)
		
		# Aplica redução de dano
		if dmg_calculator:
			# Reduz dano base
			if "base_damage" in dmg_calculator:
				dmg_calculator.base_damage = int(dmg_calculator.base_damage * (1.0 - chain_damage_decay))
			
			# Reduz multiplicador de dano
			if "damage_multiplier" in dmg_calculator:
				dmg_calculator.damage_multiplier *= (1.0 - chain_damage_decay * 0.5)  # Metade do efeito no multiplicador
			
			# Reduz dano elemental
			if "elemental_damage" in dmg_calculator and not dmg_calculator.elemental_damage.is_empty():
				for element_type in dmg_calculator.elemental_damage.keys():
					dmg_calculator.elemental_damage[element_type] = int(dmg_calculator.elemental_damage[element_type] * (1.0 - chain_damage_decay))
		
		# Reduz dano direto
		damage = int(damage * (1.0 - chain_damage_decay))
		
		# Reabilita física antes de redefinir trajetória
		set_physics_process(true)
		
		# Desativa colisão durante redirecionamento
		if hitbox:
			hitbox.set_deferred("monitoring", false)
			hitbox.set_deferred("monitorable", false)
		
		# Calcula tempo para flecha alcançar o alvo
		var distance = global_position.distance_to(target_position)
		var flight_time = distance / speed
		
		# Prediz posição do alvo com base em velocidade e tempo de voo
		var predicted_position = target_position + (target_velocity * flight_time)
		
		# Adiciona um pequeno desvio para garantir acerto mesmo com movimento irregular
		var lead_factor = 1.2  # Ajuste conforme necessário
		var lead_position = target_position + (target_velocity * flight_time * lead_factor)
		
		# Atualiza direção para posição predita
		direction = (lead_position - global_position).normalized()
		rotation = direction.angle()
		
		# Ativa camadas de colisão
		collision_layer = 4   # Camada de projétil
		collision_mask = 2    # Camada de inimigo
		
		# Configura direcionamento para o novo alvo
		homing_enabled = true
		homing_target = next_target
		homing_strength = 5.0
		
		# Move um pouco para evitar colisões
		global_position += direction * 20
		
		# Reseta velocidade para movimento correto
		velocity = direction * speed
		
		# Cria um timer curto para reativar colisão
		get_tree().create_timer(0.1).timeout.connect(func():
			if is_instance_valid(self):
				if hitbox:
					hitbox.set_deferred("monitoring", true)
					hitbox.set_deferred("monitorable", true)
		)
		
		# Reseta flag de processamento
		is_processing_chain = false
	else:
		# Sem alvos válidos encontrados, limpa flecha
		_prepare_for_destruction()

# ======== MÉTODOS DE EFEITOS ESPECIAIS ========
func _apply_mark_effect(target: Node) -> void:
	# Verifica se o projétil tem efeito de marca configurado
	if not target.has_node("DebuffComponent"):
		return
		
	# Obtém parâmetros da marca dos metadados
	var mark_duration = get_meta("mark_duration", 4.0)
	var mark_crit_bonus = get_meta("mark_crit_bonus", 1.0)
	
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

func _apply_bleeding_effect(target: Node) -> void:
	# Verifica se DoTManager está disponível
	if not DoTManager.instance or not target.has_node("HealthComponent"):
		return
	
	# Obtém dados de sangramento dos metadados
	var bleed_damage_percent = get_meta("bleeding_damage_percent", 0.3)
	var bleed_duration = get_meta("bleeding_duration", 4.0)
	var bleed_interval = get_meta("bleeding_interval", 0.5)
	
	# Agora usamos dmg_calculator diretamente para obter o dano
	var total_damage = damage  # Valor base caso não tenha calculador
	
	if dmg_calculator:
		var damage_package = dmg_calculator.calculate_damage()
		total_damage = damage_package.get("physical_damage", damage)
		
		# Adiciona danos elementais
		var elemental_damage = damage_package.get("elemental_damage", {})
		for element_type in elemental_damage:
			total_damage += elemental_damage[element_type]
	
	# Calcula dano de sangramento por tick
	var bleed_damage_per_tick = int(total_damage * bleed_damage_percent)
	bleed_damage_per_tick = max(1, bleed_damage_per_tick)
	
	# Aplica sangramento via DoTManager
	var dot_id = DoTManager.instance.apply_dot(
		target,
		bleed_damage_per_tick,
		bleed_duration,
		bleed_interval,
		"bleeding",
		self  # Source é esta flecha
	)

func _create_explosion_effect(target: Node) -> void:
	# Obtém dados de explosão
	var explosion_damage_percent = get_meta("explosion_damage_percent", 0.5)
	var explosion_radius = get_meta("explosion_radius", 30.0)
	
	# Agora usamos dmg_calculator diretamente para obter o dano
	var base_damage = damage  # Valor base caso não tenha calculador
	
	if dmg_calculator:
		var damage_package = dmg_calculator.calculate_damage()
		base_damage = damage_package.get("physical_damage", damage)
	
	var explosion_damage = int(base_damage * explosion_damage_percent)
	
	# Aplica dano em área
	var space_state = get_world_2d().direct_space_state
	
	var query = PhysicsShapeQueryParameters2D.new()
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = explosion_radius
	query.shape = circle_shape
	query.transform = Transform2D(0, global_position)
	query.collision_mask = 2  # Layer de inimigo
	
	var results = space_state.intersect_shape(query)
	
	# Aplica dano a cada inimigo
	for result in results:
		var body = result.collider
		if body != target and body.is_in_group("enemies") and body.has_node("HealthComponent"):
			var health = body.get_node("HealthComponent")
			
			# Cria versão reduzida do pacote de dano
			var explosion_package = {
				"physical_damage": explosion_damage,
				"is_critical": false,
				"tags": ["explosion"]
			}
			
			# Adiciona proporção do dano elemental se disponível
			if dmg_calculator and "elemental_damage" in dmg_calculator:
				explosion_package["elemental_damage"] = {}
				for element in dmg_calculator.elemental_damage:
					explosion_package["elemental_damage"][element] = int(dmg_calculator.elemental_damage[element] * explosion_damage_percent)
			
			# Aplica dano
			health.take_complex_damage(explosion_package)
	
	# Efeito visual
	_create_explosion_visual_effect(global_position, explosion_radius)

func _create_explosion_visual_effect(position: Vector2, radius: float) -> void:
	# Cria nó para efeito
	var explosion = Node2D.new()
	explosion.name = "ExplosionEffect"
	explosion.position = position
	get_parent().add_child(explosion)
	
	# Criação de sprite ou partículas para explosão
	var particles = CPUParticles2D.new()
	particles.emitting = true
	particles.one_shot = true
	particles.explosiveness = 0.8
	particles.amount = 30
	particles.lifetime = 0.5
	particles.direction = Vector2.UP
	particles.spread = 180.0
	particles.gravity = Vector2(0, 98)
	particles.initial_velocity_min = 40.0
	particles.initial_velocity_max = 80.0
	particles.scale_amount_min = 2.0
	particles.scale_amount_max = 4.0
	particles.color = Color(1.0, 0.5, 0.1, 1.0)
	explosion.add_child(particles)
	
	# Timer para auto-destruição
	var timer = Timer.new()
	timer.wait_time = 1.0
	timer.one_shot = true
	timer.autostart = true
	timer.timeout.connect(func(): explosion.queue_free())
	explosion.add_child(timer)

# ======== MÉTODOS DE ARROW RAIN ========
func _add_rain_arrow_processor() -> void:
	# Verifica metadados necessários
	if not has_meta("rain_target_pos") or not has_meta("rain_start_pos"):
		return
	
	# Cria o processador
	var processor_script = load("res://Test/Processors/RainArrowProcessor.gd")
	if processor_script:
		var processor = processor_script.new()
		processor.name = "RainArrowProcessor"
		add_child(processor)
		
		# Configura trajetória
		processor.start_position = get_meta("rain_start_pos")
		processor.target_position = get_meta("rain_target_pos")
		processor.arc_height = get_meta("rain_arc_height", 250.0)
		processor.total_time = get_meta("rain_time", 1.0)
		
		# Verifica se deve criar onda de pressão
		if has_meta("pressure_wave_enabled") and get_meta("pressure_wave_enabled"):
			processor.create_pressure_wave = true
			processor.knockback_force = get_meta("knockback_force", 150.0)
			processor.slow_percent = get_meta("slow_percent", 0.3)
			processor.slow_duration = get_meta("slow_duration", 0.5)
			processor.wave_visual_enabled = get_meta("wave_visual_enabled", true)
			processor.ground_effect_duration = get_meta("ground_duration", 3.0)
