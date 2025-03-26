extends BaseProjectileStrategy
class_name Talent_16

@export var bleeding_damage_percent: float = 0.3
@export var bleeding_duration: float = 4.0
@export var dot_interval: float = 0.5
@export var talent_id: int = 16

func get_strategy_name() -> String:
	return "Serrated Arrows"

func apply_upgrade(projectile: Node) -> void:
	print("Aplicando Serrated Arrows - Flechas serrilhadas que causam sangramento em acertos críticos")
	
	# Adiciona tag para identificação
	if "tags" in projectile and projectile.has_method("add_tag"):
		projectile.add_tag("bleeding")
	elif "tags" in projectile:
		if not "bleeding" in projectile.tags:
			projectile.tags.append("bleeding")
	
	# Se for uma flecha Arrow, melhora o processamento de hit
	if projectile is Arrow:
		enhance_arrow_hit_processing(projectile)
	else:
		# Para outros tipos de projéteis, usa metadados como fallback
		print("Serrated Arrows: Aplicando efeito de sangramento via metadados")
		
		# Se for possível, conecta ao processamento de hit
		if projectile.has_signal("on_hit"):
			projectile.connect("on_hit", func(target, proj):
				if proj == projectile and is_instance_valid(target) and projectile.is_crit:
					apply_bleeding_effect(target, projectile)
			)

func enhance_arrow_hit_processing(arrow: Arrow) -> void:
	print("Aprimorando flecha Arrow com efeito de sangramento em acertos críticos")
	
	# Conecta ao sinal on_hit se existir
	if arrow.has_signal("on_hit"):
		arrow.connect("on_hit", func(target, proj):
			if proj == arrow and is_instance_valid(target) and arrow.is_crit:
				# Aplica sangramento diretamente no alvo
				apply_bleeding_effect(target, arrow)
		)

func apply_bleeding_effect(target: Node, projectile: Node) -> void:
	# Verifica se o alvo tem um DebuffComponent
	if target.has_node("DebuffComponent"):
		var debuff_component = target.get_node("DebuffComponent")
		
		# Calcula dano de sangramento (30% do dano base)
		var base_damage = 0
		if "damage" in projectile:
			base_damage = projectile.damage
		elif projectile.has_node("DmgCalculatorComponent"):
			var dmg_calc = projectile.get_node("DmgCalculatorComponent")
			if "base_damage" in dmg_calc:
				base_damage = dmg_calc.base_damage
		
		var damage_per_tick = int(base_damage * bleeding_damage_percent)
		
		# Aplica dano via HealthComponent
		if target.has_node("HealthComponent"):
			var health_component = target.get_node("HealthComponent")
			health_component.apply_dot(
				damage_per_tick,
				bleeding_duration,
				dot_interval,
				"bleeding"
			)
		
		# Se tiver DebuffComponent, atualiza ícone
		if target.has_node("DebuffDisplayComponent"):
			target.get_node("DebuffDisplayComponent").update_debuffs()
		# Cria efeito visual de sangramento
		create_bleeding_effect(target)

# Mantém a função de efeito visual igual ao script original
func create_bleeding_effect(target: Node) -> void:
	# Código do efeito visual permanece o mesmo
	var bleeding_effect = CPUParticles2D.new()
	bleeding_effect.name = "BleedingEffect"
	bleeding_effect.position = Vector2(0, -10)
	
	# Configurações de partículas (mantidas do script original)
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
	bleeding_effect.color = Color(0.8, 0.1, 0.1, 0.8)
	
	# Adiciona ao alvo
	target.add_child(bleeding_effect)
	
	# Timer para auto-destruição
	var timer = Timer.new()
	timer.wait_time = bleeding_duration + 0.5
	timer.one_shot = true
	bleeding_effect.add_child(timer)
	timer.timeout.connect(func(): bleeding_effect.queue_free())
	timer.start()
	
	# Mantém o script para emissões periódicas
	var emission_timer = Timer.new()
	emission_timer.wait_time = 0.5
	bleeding_effect.add_child(emission_timer)
	
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
