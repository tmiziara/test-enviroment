extends Node
class_name HealthComponent

@export var max_health: int = 100  # Vida máxima

var current_health: int  # Vida atual

# Sinais
signal health_changed(new_health, amount, is_crit, damage_type)  # Para números de dano
signal died  # Evento de morte
signal dot_ended(dot_type)  # Kept for backward compatibility

# Referência ao componente de defesa
var defense_component = null

func _ready():
	current_health = max_health
	
	# Tenta encontrar o componente de defesa no pai
	var parent = get_parent()
	if parent.has_node("DefenseComponent"):
		defense_component = parent.get_node("DefenseComponent")
	else:
		print("HealthComponent: DefenseComponent NÃO encontrado!")

# Função básica que aplica dano direto à vida
func take_damage(amount: int, is_crit: bool = false, damage_type: String = ""):
	# Aplica redução de dano se possível
	var final_amount = amount
	if defense_component and defense_component.has_method("reduce_damage"):
		final_amount = defense_component.reduce_damage(amount, damage_type)
	else:
		print("DefenseComponent não encontrado ou não tem método reduce_damage")
	
	# Aplica dano à vida do personagem
	current_health -= int(final_amount)
	current_health = max(current_health, 0)
	
	# Emite sinal com informações do dano (para números de dano)
	health_changed.emit(current_health, final_amount, is_crit, damage_type)
	
	# Atualiza a barra de vida diretamente
	update_health_bar()
	
	# Verifica se o personagem morreu
	if current_health <= 0:
		died.emit()

# Função para atualizar a barra de vida diretamente
func update_health_bar():
	# Tenta acessar a healthbar no nó pai (Enemy)
	var parent = get_parent()
	if parent and parent.has_node("Healthbar"):
		var healthbar = parent.get_node("Healthbar")
		if healthbar.has_method("_set_health"):
			healthbar._set_health(current_health)
		else:
			print("ERRO: Healthbar não tem método _set_health")
	else:
		print("AVISO: Não foi possível encontrar Healthbar")

# Processa um pacote completo de dano
func take_complex_damage(damage_package: Dictionary):
	# Aplica redução de dano se houver componente de defesa
	var final_damage = damage_package.duplicate(true)
	if defense_component and defense_component.has_method("apply_reductions"):
		final_damage = defense_component.apply_reductions(final_damage)
	else:
		print("HealthComponent: Sem reduções de dano - DefenseComponent não encontrado")
	
	# Obtém todos os componentes de dano após reduções
	var physical_damage = final_damage.get("physical_damage", 0)
	var is_critical = final_damage.get("is_critical", false)
	var elemental_damage = final_damage.get("elemental_damage", {})
	
	# Calcula o dano total
	var total_damage = physical_damage
	for element_type in elemental_damage:
		total_damage += elemental_damage[element_type]
	# Mostra números de dano para dano físico
	if physical_damage > 0:
		health_changed.emit(current_health, physical_damage, is_critical, "")
	
	# Mostra números de dano para danos elementais
	for element_type in elemental_damage:
		var element_damage = elemental_damage[element_type]
		if element_damage > 0:
			health_changed.emit(current_health, element_damage, false, element_type)
	
	# Agora aplica o dano total de uma vez
	current_health -= total_damage
	current_health = max(current_health, 0)
	# Atualiza a barra de vida diretamente
	update_health_bar()
	
	# Verifica morte
	if current_health <= 0:
		died.emit()
	
# No método take_complex_damage do HealthComponent, ajuste o processamento de DoT:

# Processa efeitos DoT
	var dot_effects = final_damage.get("dot_effects", [])
	for dot in dot_effects:
		# Verifica se DoTManager está disponível
		var dot_manager = get_node_or_null("/root/DoTManager")
		if dot_manager and dot_manager.has_method("apply_dot"):
			# Usa DoTManager para aplicar o DoT
			var entity = get_parent()
			dot_manager.apply_dot(
				entity,
				dot.get("damage", 0),
				dot.get("duration", 3.0),
				dot.get("interval", 1.0),
				dot.get("type", "generic"),
				null  # Sem fonte específica
			)
		else:  # Corrigido aqui: substituído { por :
			# Fallback para o método tradicional
			apply_dot(
				dot.get("damage", 0),
				dot.get("duration", 3.0),
				dot.get("interval", 1.0),
				dot.get("type", "generic")
			)

# Aplica um debuff no personagem (deprecated - use DebuffComponent)
func apply_debuff(debuff_name: String, duration: float, effect_func: Callable):
	# Se o componente de defesa existir e tiver um método específico para debuffs, use-o
	if defense_component and defense_component.has_method("apply_debuff"):
		defense_component.apply_debuff(debuff_name, duration, effect_func)
		return
	
	# For backward compatibility - get parent's debuff component
	var parent = get_parent()
	var debuff_component = parent.get_node_or_null("DebuffComponent")
	if debuff_component:
		# Convert string to enum
		var debuff_type = GlobalDebuffSystem.DebuffType.NONE
		match debuff_name:
			"burning": debuff_type = GlobalDebuffSystem.DebuffType.BURNING
			"freezing": debuff_type = GlobalDebuffSystem.DebuffType.FREEZING
			"stunned": debuff_type = GlobalDebuffSystem.DebuffType.STUNNED
			"knocked": debuff_type = GlobalDebuffSystem.DebuffType.KNOCKED
			"slowed": debuff_type = GlobalDebuffSystem.DebuffType.SLOWED
			"bleeding": debuff_type = GlobalDebuffSystem.DebuffType.BLEEDING
			"poisoned": debuff_type = GlobalDebuffSystem.DebuffType.POISONED
			"marked_for_death": debuff_type = GlobalDebuffSystem.DebuffType.MARKED_FOR_DEATH
		
		if debuff_type != GlobalDebuffSystem.DebuffType.NONE:
			debuff_component.add_debuff(debuff_type, duration, {})
		
		# Still call the effect function for compatibility
		effect_func.call()
		return
	# Legacy implementation
	print("WARNING: Using deprecated debuff system in HealthComponent")
	var debuffs = {}
	debuffs[debuff_name] = get_tree().create_timer(duration)
	debuffs[debuff_name].timeout.connect(func():
		debuffs.erase(debuff_name)  # Remove o debuff após o tempo
	)
	effect_func.call()  # Aplica o efeito imediato

# Simplified DoT application that delegates to DoTManager
func apply_dot(damage: int, duration: float, interval: float, dot_type: String = "generic") -> void:
	# Check if DoTManager is available
	if not DoTManager.instance:
		_legacy_apply_dot(damage, duration, interval, dot_type)
		return
	# Get parent entity
	var entity = get_parent()
	if not entity:
		return
	
	# Apply DoT through manager
	var dot_id = DoTManager.instance.apply_dot(
		entity,
		damage,
		duration,
		interval,
		dot_type,
		null   # No source specified
	)

# Legacy implementation for backward compatibility
func _legacy_apply_dot(damage: int, duration: float, interval: float, dot_type: String = "generic") -> void:
	print("WARNING: Using legacy DoT system")
	
	# Verifica se o componente de defesa pode reduzir o DoT
	if defense_component and defense_component.has_method("reduce_dot_damage"):
		damage = defense_component.reduce_dot_damage(damage, dot_type)
	
	# Se o dano for reduzido a zero ou menos, não aplica o DoT
	if damage <= 0:
		return
	
	# Cria um timer para aplicar o dano periodicamente
	var dot_timer = Timer.new()
	dot_timer.wait_time = interval
	dot_timer.one_shot = false
	add_child(dot_timer)
	
	# Cria um timer para controlar a duração total
	var duration_timer = Timer.new()
	duration_timer.wait_time = duration
	duration_timer.one_shot = true
	add_child(duration_timer)
	
	# Conecta os sinais dos timers
	dot_timer.timeout.connect(func():
		take_damage(damage, false, dot_type)
	)
	
	duration_timer.timeout.connect(func():
		dot_timer.stop()
		dot_timer.queue_free()
		duration_timer.queue_free()
		
		# Emite sinal de que o DoT terminou
		emit_signal("dot_ended", dot_type)
	)
	
	# Inicia os timers
	dot_timer.start()
	duration_timer.start()
	
	# Apply debuff via DebuffComponent if available
	var parent = get_parent()
	var debuff_component = parent.get_node_or_null("DebuffComponent")
	if debuff_component:
		var debuff_type = GlobalDebuffSystem.map_dot_to_debuff_type(dot_type)
		if debuff_type != GlobalDebuffSystem.DebuffType.NONE:
			debuff_component.add_debuff(debuff_type, duration, {"source_damage": damage})

func get_health_percent() -> float:
	return float(current_health) / max_health
