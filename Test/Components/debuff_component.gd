# debuff_component.gd
class_name DebuffComponent
extends Node

# Sinal para notificar mudanças nos debuffs
signal debuff_added(debuff_type)
signal debuff_removed(debuff_type)

# Dicionário de debuffs ativos
var active_debuffs: Dictionary = {}
var active_timers: Dictionary = {}

func _ready():
	var health_component = get_parent().get_node("HealthComponent")
	if health_component:
		health_component.connect("dot_ended", _on_dot_ended)
# Adiciona ou atualiza um debuff
func add_debuff(debuff_type: int, duration: float, data: Dictionary = {}) -> void:
	var existing_debuff = active_debuffs.get(debuff_type)
	
	# Remove o timer existente se houver
	if debuff_type in active_timers:
		var old_timer = active_timers[debuff_type]
		if is_instance_valid(old_timer):
			old_timer.stop()
			old_timer.queue_free()
		active_timers.erase(debuff_type)
	
	if existing_debuff:
		# Atualiza duração
		existing_debuff.duration = duration
		
		# Atualiza stack count, se fornecido
		var max_stacks = data.get("max_stacks", existing_debuff.max_stacks)
		existing_debuff.stack_count = min(
			existing_debuff.stack_count + 1, 
			max_stacks
		)
	else:
		# Cria novo debuff
		var new_debuff = GlobalDebuffSystem.DebuffData.new()
		new_debuff.type = debuff_type
		new_debuff.duration = duration
		new_debuff.data = data
		new_debuff.max_stacks = data.get("max_stacks", 1)
		new_debuff.stack_count = 1
		
		active_debuffs[debuff_type] = new_debuff
		emit_signal("debuff_added", debuff_type)
	
	# Em vez de remover diretamente, vamos verificar se o DoT ainda existe
	var timer = Timer.new()
	timer.wait_time = duration
	timer.one_shot = true
	add_child(timer)
	
	timer.timeout.connect(func():
		var health_component = get_parent().get_node_or_null("HealthComponent")
		if health_component:
			var dot_type = GlobalDebuffSystem.map_debuff_to_dot_type(debuff_type)
			
			# Verifica se o DoT ainda está ativo
			if not (dot_type in health_component.active_dots):
				remove_debuff(debuff_type)
			else:
				# O DoT ainda está ativo, vamos criar um novo timer para verificar periodicamente
				schedule_debuff_check(debuff_type)
		else:
			# Se não encontrarmos o HealthComponent, removemos normalmente
			remove_debuff(debuff_type)
	)
	timer.start()
	
	# Armazena referência do timer
	active_timers[debuff_type] = timer

# Nova função para agendar verificações periódicas
func schedule_debuff_check(debuff_type: int) -> void:
	var check_timer = Timer.new()
	check_timer.wait_time = 0.5  # Verifica a cada meio segundo
	check_timer.one_shot = true
	add_child(check_timer)
	
	check_timer.timeout.connect(func():
		var health_component = get_parent().get_node_or_null("HealthComponent")
		if health_component:
			var dot_type = GlobalDebuffSystem.map_debuff_to_dot_type(debuff_type)
			
			# Verifica se o DoT ainda está ativo
			if not (dot_type in health_component.active_dots):
				remove_debuff(debuff_type)
				check_timer.queue_free()
			else:
				# Ainda ativo, agenda nova verificação
				check_timer.start()
		else:
			remove_debuff(debuff_type)
			check_timer.queue_free()
	)
	check_timer.start()
	
	
func _on_dot_ended(dot_type: String):
	var debuff_type = GlobalDebuffSystem.map_dot_to_debuff_type(dot_type)
	remove_debuff(debuff_type)
	
func remove_debuff(debuff_type: int) -> void:
	print("Removendo debuff: ", debuff_type)  # Debug print
	
	if debuff_type in active_debuffs:
		active_debuffs.erase(debuff_type)
		emit_signal("debuff_removed", debuff_type)
	
	# Remove timer associado, se existir
	if debuff_type in active_timers:
		var timer = active_timers[debuff_type]
		if is_instance_valid(timer):
			timer.stop()
			timer.queue_free()
		active_timers.erase(debuff_type)

# Adicione este método para verificar debuffs ativos
func get_active_debuffs() -> Array:
	return active_debuffs.keys()

# Verifica se tem um debuff específico
func has_debuff(debuff_type: int) -> bool:
	return debuff_type in active_debuffs

# Obtém dados de um debuff específico
func get_debuff_data(debuff_type: int) -> GlobalDebuffSystem.DebuffData:
	return active_debuffs.get(debuff_type)

# Atualiza debuffs (opcional, se quiser processar efeitos periódicos)
func _process(delta: float) -> void:
	for debuff_type in active_debuffs.keys():
		var debuff = active_debuffs[debuff_type]
		debuff.duration -= delta
		
		# Processamento específico de debuffs
		match debuff_type:
			GlobalDebuffSystem.DebuffType.BURNING:
				_process_burning_debuff(debuff, delta)
			GlobalDebuffSystem.DebuffType.FREEZING:
				_process_freezing_debuff(debuff, delta)
			GlobalDebuffSystem.DebuffType.BLEEDING:
				_process_bleeding_debuff(debuff, delta)


# Processamento de debuff de burning
func _process_burning_debuff(debuff: GlobalDebuffSystem.DebuffData, delta: float) -> void:
	pass

# Processamento de debuff de congelamento
func _process_freezing_debuff(debuff: GlobalDebuffSystem.DebuffData, delta: float) -> void:
	var parent = get_parent()
	
	if parent.has_method("apply_slow"):
		parent.apply_slow(0.5)  # Reduz velocidade em 50%

func _process_bleeding_debuff(debuff: GlobalDebuffSystem.DebuffData, delta: float) -> void:
	pass
