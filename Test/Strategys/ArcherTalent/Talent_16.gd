extends BaseProjectileStrategy
class_name Talent_16

# Serrated Arrows parameters
@export var bleeding_damage_percent: float = 0.3  # 30% do dano base como sangramento
@export var bleeding_duration: float = 4.0        # Duração do efeito de sangramento em segundos
@export var bleeding_interval: float = 0.5        # Intervalo entre os ticks de dano
@export var talent_id: int = 16                   # ID para esse talento na árvore de talentos

# Nome para o painel de debug
func get_strategy_name() -> String:
	return "Serrated Arrows"

# Método principal de aplicação do upgrade
func apply_upgrade(projectile: Node) -> void:
	print("Aplicando Serrated Arrows - Flechas serrilhadas que causam sangramento em acertos críticos")
	
	# Verifica se o projétil já tem efeito de sangramento para evitar duplicação
	if projectile.has_meta("has_bleeding_effect"):
		print("Serrated Arrows: Este projétil já tem efeito de sangramento")
		return
		
	# Adiciona tag para identificação
	if "tags" in projectile and projectile.has_method("add_tag"):
		projectile.add_tag("bleeding")
	elif "tags" in projectile:
		if not "bleeding" in projectile.tags:
			projectile.tags.append("bleeding")
	
	# Marca a flecha como tendo efeito de sangramento
	projectile.set_meta("has_bleeding_effect", true)
	
	# Armazena parâmetros do efeito de sangramento na flecha
	projectile.set_meta("bleeding_damage_percent", bleeding_damage_percent)
	projectile.set_meta("bleeding_duration", bleeding_duration)
	projectile.set_meta("bleeding_interval", bleeding_interval)
	
	# Se for uma flecha Arrow, podemos melhorar sua funcionalidade diretamente
	if projectile is Arrow:
		enhance_arrow_hit_processing(projectile)
	else:
		# Para outros tipos de projéteis, usa metadados como fallback
		print("Serrated Arrows: Aplicando efeito de sangramento via metadados")
		
		# Armazena referência a esta estratégia
		projectile.set_meta("bleeding_strategy", weakref(self))
		
		# Se for possível, conecta ao processamento de hit
		if projectile.has_signal("on_hit"):
			projectile.connect("on_hit", func(target, proj):
				if proj == projectile and is_instance_valid(target):
					apply_bleeding_effect(projectile, target)
			)

# Aprimora o processamento de hit de uma flecha Arrow
func enhance_arrow_hit_processing(arrow: Arrow) -> void:
	print("Aprimorando flecha Arrow com efeito de sangramento em acertos críticos")
	
	# Verificamos se a flecha tem o método process_on_hit
	if arrow.has_method("process_on_hit"):
		# Não podemos armazenar o método diretamente
		# Então vamos usar metadata para marcar a flecha
		arrow.set_meta("has_bleeding_on_crit", true)
	
	# Armazena referência à estratégia
	var self_ref = weakref(self)
	
	# Conecta ao sinal on_hit se disponível
	if arrow.has_signal("on_hit"):
		arrow.connect("on_hit", func(target, proj):
			if proj == arrow and is_instance_valid(target):
				# Verifica se foi um acerto crítico
				if arrow.is_crit:
					# Obtém referência à estratégia
					var strategy = self_ref.get_ref()
					if strategy:
						strategy.apply_bleeding_effect(arrow, target)
		)
		print("Serrated Arrows: Conectado ao sinal on_hit da flecha")
	else:
		print("Serrated Arrows: Flecha não tem sinal on_hit, usando metadados")
		arrow.set_meta("bleeding_strategy", self_ref)

# Aplica o efeito de sangramento a um alvo
func apply_bleeding_effect(projectile: Node, target: Node) -> void:
	print("Applying bleeding effect to target")
	
	# Verifica se foi um acerto crítico
	var is_critical = false
	if "is_crit" in projectile:
		is_critical = projectile.is_crit
	elif projectile.has_meta("is_crit"):
		is_critical = projectile.get_meta("is_crit")
	
	# Só aplica sangramento em acertos críticos
	if not is_critical:
		print("Serrated Arrows: Não foi um acerto crítico, não aplicando sangramento")
		return
	
	# Verifica se o alvo tem um componente de saúde
	if not target.has_node("HealthComponent"):
		print("Serrated Arrows: Alvo não tem HealthComponent")
		return
		
	var health_component = target.get_node("HealthComponent")
	
	# Calcula o dano de sangramento com base no dano do projétil
	var base_damage = 0
	
	# Tenta obter o dano base do projétil de várias maneiras
	if "damage" in projectile:
		base_damage = projectile.damage
	elif projectile.has_node("DmgCalculatorComponent"):
		var dmg_calc = projectile.get_node("DmgCalculatorComponent")
		if "base_damage" in dmg_calc:
			base_damage = dmg_calc.base_damage
	
	if base_damage <= 0:
		print("Serrated Arrows: Não foi possível determinar o dano base")
		return
	
	# Calcula dano de sangramento (30% do dano base)
	var bleeding_percent = projectile.get_meta("bleeding_damage_percent", bleeding_damage_percent)
	var bleeding_damage = int(base_damage * bleeding_percent)
	
	if bleeding_damage <= 0:
		bleeding_damage = 1  # Garante dano mínimo de 1
	
	# Obtém parâmetros do efeito
	var duration = projectile.get_meta("bleeding_duration", bleeding_duration)
	var interval = projectile.get_meta("bleeding_interval", bleeding_interval)
	
	print("Serrated Arrows: Aplicando efeito de sangramento - ", bleeding_damage, 
		  " de dano a cada ", interval, "s por ", duration, "s")
	
	# Aplica efeito DoT de sangramento
	if health_component.has_method("apply_dot"):
		health_component.apply_dot(bleeding_damage, duration, interval, "bleeding")
		
		# Feedback visual para o jogador
		create_bleeding_effect(target)
	else:
		print("Serrated Arrows: HealthComponent não tem método apply_dot")

# Cria um efeito visual de sangramento no alvo
func create_bleeding_effect(target: Node) -> void:
	# Cria um efeito visual de partículas para indicar sangramento
	var bleeding_effect = CPUParticles2D.new()
	bleeding_effect.name = "BleedingEffect"
	bleeding_effect.position = Vector2(0, -10)  # Posição ligeiramente acima do centro
	
	# Configura aparência das partículas
	bleeding_effect.amount = 10
	bleeding_effect.lifetime = 0.8
	bleeding_effect.explosiveness = 0.1
	bleeding_effect.randomness = 0.5
	bleeding_effect.direction = Vector2(0, 1)
	bleeding_effect.spread = 60
	bleeding_effect.gravity = Vector2(0, 150)
	bleeding_effect.initial_velocity_min = 10
	bleeding_effect.initial_velocity_max = 30
	bleeding_effect.scale_amount_min = 1.0
	bleeding_effect.scale_amount_max = 2.0
	bleeding_effect.color = Color(0.8, 0.1, 0.1, 0.8)  # Cor vermelha para sangue
	
	# Adiciona ao alvo
	target.add_child(bleeding_effect)
	
	# Timer para auto-destruição
	var timer = Timer.new()
	timer.wait_time = bleeding_duration + 0.5  # Duração do efeito + margem
	timer.one_shot = true
	bleeding_effect.add_child(timer)
	timer.timeout.connect(func(): bleeding_effect.queue_free())
	timer.start()
	
	# Faz com que as partículas sejam emitidas periodicamente
	var emission_timer = Timer.new()
	emission_timer.wait_time = 0.5  # Intervalo entre emissões
	bleeding_effect.add_child(emission_timer)
	
	# Cria um script para controlar as emissões periódicas
	var script = GDScript.new()
	script.source_code = """
	extends Timer
	
	var particles_node
	
	func _ready():
		particles_node = get_parent()
		timeout.connect(_on_emission_timeout)
		start()
	
	func _on_emission_timeout():
		if is_instance_valid(particles_node):
			particles_node.restart()
			particles_node.emitting = true
	"""
	
	emission_timer.set_script(script)
