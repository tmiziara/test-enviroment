extends Node
class_name HealthComponent

@export var max_health: int = 100  # Vida máxima


var current_health: int  # Vida atual
var active_debuffs = {}  # Dicionário para armazenar debuffs ativos
var active_dots = {}   # Lista para armazenar DoTs ativos

# Sinais
signal health_changed(new_health, amount, is_crit, damage_type)  # Para números de dano
signal died  # Evento de morte
signal dot_ended(dot_type)
# Referência ao componente de defesa
var defense_component = null

func _ready():
	current_health = max_health
	
	# Tenta encontrar o componente de defesa no pai
	var parent = get_parent()
	if parent.has_node("DefenseComponent"):
		defense_component = parent.get_node("DefenseComponent")
		print("HealthComponent: DefenseComponent encontrado com armadura:", defense_component.armor)
	else:
		print("HealthComponent: DefenseComponent NÃO encontrado!")

# Função básica que aplica dano direto à vida
func take_damage(amount: int, is_crit: bool = false, damage_type: String = ""):
	print("take_damage chamado com:", amount, is_crit, damage_type)
	
	# Aplica redução de dano se possível
	var final_amount = amount
	if defense_component and defense_component.has_method("reduce_damage"):
		print("Aplicando redução via DefenseComponent")
		final_amount = defense_component.reduce_damage(amount, damage_type)
		print("Dano após redução:", final_amount)
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
	print("take_complex_damage chamado com:", damage_package)
	
	# Aplica redução de dano se houver componente de defesa
	var final_damage = damage_package.duplicate(true)
	if defense_component and defense_component.has_method("apply_reductions"):
		print("HealthComponent: Aplicando reduções de dano via DefenseComponent")
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
	
	print("Dano total após reduções:", total_damage)
	
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
	
	print("Vida após dano:", current_health, "/", max_health)
	
	# Atualiza a barra de vida diretamente
	update_health_bar()
	
	# Verifica morte
	if current_health <= 0:
		died.emit()
	
	# Processa efeitos DoT
	var dot_effects = final_damage.get("dot_effects", [])
	for dot in dot_effects:
		apply_dot(
			dot.get("damage", 0),
			dot.get("duration", 3.0),
			dot.get("interval", 1.0),
			dot.get("type", "generic")
		)

# Aplica um debuff no personagem
func apply_debuff(debuff_name: String, duration: float, effect_func: Callable):
	# Se o componente de defesa existir e tiver um método específico para debuffs, use-o
	if defense_component and defense_component.has_method("apply_debuff"):
		defense_component.apply_debuff(debuff_name, duration, effect_func)
		return
	
	# Caso contrário, use a implementação atual
	if debuff_name in active_debuffs:
		return  # Evita reaplicar um debuff já ativo

	active_debuffs[debuff_name] = get_tree().create_timer(duration)
	active_debuffs[debuff_name].timeout.connect(func():
		active_debuffs.erase(debuff_name)  # Remove o debuff após o tempo
	)
	effect_func.call()  # Aplica o efeito imediato

# Versão melhorada do método apply_dot
func apply_dot(damage: int, duration: float, interval: float, dot_type: String = "generic"):
	# Log de diagnóstico
	print("Applying DOT: ", dot_type)
	print("Original Damage: ", damage)
	print("Duration: ", duration)
	print("Interval: ", interval)

	# Verifica se o componente de defesa pode reduzir o DoT
	if defense_component and defense_component.has_method("reduce_dot_damage"):
		damage = defense_component.reduce_dot_damage(damage, dot_type)
		print("Damage after reduction: ", damage)
	
	# Se o dano for reduzido a zero ou menos, não aplica o DoT
	if damage <= 0:
		print("Damage reduced to 0 or less - DoT not applied")
		return
	
	# Verifica se já existe um DoT desse tipo
	if dot_type in active_dots:
		var existing_dot = active_dots[dot_type]
		
		# Atualiza o dano se o novo for maior
		if damage > existing_dot.damage:
			existing_dot.damage = damage
			print("Updated existing DoT damage to: ", damage)
		
		# Renova o timer de duração
		if existing_dot.duration_timer and is_instance_valid(existing_dot.duration_timer):
			existing_dot.duration_timer.stop()
			existing_dot.duration_timer.wait_time = duration
			existing_dot.duration_timer.start()
			print("Renewed existing DoT duration")
		
		# Não cria um novo DoT, apenas retorna
		return
	
	# Se não existe um DoT desse tipo, cria um novo
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
	
	# Armazena informações do DoT
	active_dots[dot_type] = {
		"damage": damage,
		"interval": interval,
		"duration": duration,
		"dot_timer": dot_timer,
		"duration_timer": duration_timer
	}
	
	# Função para processar dano periódico
	var damage_func = func():
		# Aplica dano periódico, já considerando as resistências
		var dot_damage = damage
		
		# Verificação adicional de dano
		if defense_component and defense_component.has_method("reduce_dot_damage"):
			dot_damage = defense_component.reduce_dot_damage(dot_damage, dot_type)
		
		if dot_damage > 0:
			# Adiciona tag de dano para identificação
			var damage_type = dot_type if dot_type != "generic" else ""
			take_damage(dot_damage, false, damage_type)
			
			# Log de diagnóstico
			print("DoT Tick: ", dot_type, " damage: ", dot_damage)
			
			# Efeitos visuais específicos
			match dot_type:
				"fire":
					# Adicionar efeito visual de fogo
					pass
				"bleeding":
					# Adicionar efeito visual de sangramento
					pass
	
	# Conecta os sinais dos timers
	dot_timer.timeout.connect(damage_func)
	
	duration_timer.timeout.connect(func():
		# Remove o DoT após o término da duração
		if is_instance_valid(dot_timer):
			dot_timer.stop()
			dot_timer.queue_free()
		
		if is_instance_valid(duration_timer):
			duration_timer.queue_free()
		
		# Remove das dots ativas
		active_dots.erase(dot_type)
		
		# Emite sinal de que o DoT terminou
		emit_signal("dot_ended", dot_type)
		
		# Log de diagnóstico
		print("DoT ", dot_type, " ended")
	)
	
	# Inicia os timers
	dot_timer.start()
	duration_timer.start()
	
	# Adiciona o debuff
	var parent = get_parent()
	var debuff_component = parent.get_node_or_null("DebuffComponent")
	
	# Verificação de segurança para o DebuffComponent
	if debuff_component:
		# Mapeamento de tipos de DoT para tipos de debuff
		var debuff_type = GlobalDebuffSystem.map_dot_to_debuff_type(dot_type)
		
		# Log de diagnóstico
		print("Mapped Debuff Type: ", debuff_type)
		
		# Verifica se o tipo de debuff é válido
		if debuff_type != GlobalDebuffSystem.DebuffType.NONE:
			debuff_component.add_debuff(
				debuff_type, 
				duration,
				{
					"max_stacks": 1,
					"source_damage": damage  # Opcional: adiciona informação de origem
				}
			)
			
			print("Debuff added: ", debuff_type)
	else:
		print("WARNING: No DebuffComponent found")

	# Log final
	print("DoT Application Complete")
func get_health_percent() -> float:
	return float(current_health) / max_health
