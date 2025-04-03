extends Node
class_name ProjectilePoolSystem

# Configurações do pool
@export var pre_instantiate_count: int = 20
@export var expand_pool_size: int = 5
@export var max_pool_size: int = 100

# Dicionário de pools de projéteis por tipo
var pools: Dictionary = {}

# Sinais para monitoramento de desempenho
signal projectile_created(pool_name)
signal projectile_reused(pool_name)
signal projectile_returned(pool_name)

# Estrutura para um pool específico
class Pool:
	var scene: PackedScene
	var available: Array[Node] = []
	var active: Array[Node] = []
	var parent_node: Node
	
	func _init(scene_resource: PackedScene, parent: Node, initial_count: int):
		scene = scene_resource
		parent_node = parent
		# Adiar a instanciação para evitar erros
		call_deferred("_initialize_pool", initial_count)
	
	# Método deferido para inicialização segura
	func _initialize_pool(initial_count: int) -> void:
		# Pré-instancia os objetos
		for i in range(initial_count):
			var instance = scene.instantiate()
			instance.process_mode = Node.PROCESS_MODE_DISABLED
			instance.visible = false
			instance.set_meta("pooled", true)
			parent_node.call_deferred("add_child", instance)
			available.append(instance)

# Inicializa o sistema
func _ready():
	# Use o nome exato do singleton
	var performance_monitor = get_tree().root.get_node_or_null("PoolPerformanceMonitor2")
	if performance_monitor:
		performance_monitor.connect_to_pool_system(self)
	else:
		print("ERRO: Monitor de desempenho NÃO ENCONTRADO")

# Cria um novo pool
func create_pool(name: String, scene: PackedScene, parent: Node = self, initial_count: int = 0) -> void:
	if name in pools:
		return
		
	var count = initial_count if initial_count > 0 else pre_instantiate_count
	pools[name] = Pool.new(scene, parent, count)

func get_projectile(pool_name: String) -> Node:
	# Verifica se o pool existe
	if not pool_name in pools:
		return null
		
	var pool = pools[pool_name]
	
	# Se não houver objetos disponíveis, expande o pool
	if pool.available.size() == 0:
		_expand_pool(pool_name)
	
	# Retorna um objeto do pool
	if pool.available.size() > 0:
		var projectile = pool.available.pop_back()
		pool.active.append(projectile)
		
		projectile.set_meta("pooled", true)
		
		projectile.process_mode = Node.PROCESS_MODE_INHERIT
		projectile.visible = true
		
		# Emite sinal para monitoramento
		emit_signal("projectile_reused", pool_name)
		
		return projectile
	
	return null

# Devolve um projétil ao pool
func return_projectile(pool_name: String, projectile: Node) -> void:
	# Verifica se o pool existe
	if not pool_name in pools:
		return
		
	var pool = pools[pool_name]
	
	# Remove do array de ativos
	var index = pool.active.find(projectile)
	if index >= 0:
		pool.active.remove_at(index)
	
	# Reseta o projétil - use call_deferred para propriedades físicas
	projectile.call_deferred("set", "process_mode", Node.PROCESS_MODE_DISABLED)
	projectile.call_deferred("set", "visible", false)
	
	# Reset collision properties safely
	if projectile is CollisionObject2D:
		projectile.call_deferred("set", "monitoring", false)
		projectile.call_deferred("set", "monitorable", false)
	
	# For CharacterBody2D, reset collision layers
	if projectile is CharacterBody2D:
		projectile.call_deferred("set", "collision_layer", 0)
		projectile.call_deferred("set", "collision_mask", 0)
	
	# Adiciona ao array de disponíveis
	pool.available.append(projectile)
	
	# Emite sinal para monitoramento
	emit_signal("projectile_returned", pool_name)

# Devolve todos os projéteis ativos ao pool
func return_all_projectiles(pool_name: String) -> void:
	# Verifica se o pool existe
	if not pool_name in pools:
		return
		
	var pool = pools[pool_name]
	
	# Copia o array para não modificar enquanto itera
	var active_copy = pool.active.duplicate()
	
	# Devolve cada projétil ao pool
	for projectile in active_copy:
		return_projectile(pool_name, projectile)

# Reseta um projétil para estado inicial
func reset_projectile(projectile: Node) -> void:
	# Propriedades básicas que todos os projéteis teriam
	if "velocity" in projectile:
		projectile.velocity = Vector2.ZERO
	
	if "damage" in projectile:
		# Reset para dano base
		if "base_damage" in projectile:
			projectile.damage = projectile.base_damage
	
	# Reseta DmgCalculatorComponent
	if projectile.has_node("DmgCalculatorComponent"):
		var dmg_calc = projectile.get_node("DmgCalculatorComponent")
		dmg_calc.damage_multiplier = 1.0
		dmg_calc.armor_penetration = 0.0
		dmg_calc.elemental_damage = {}
		dmg_calc.additional_effects = []
		dmg_calc.dot_effects = []
	
	# Se for um Arrow, usa seu método específico
	if projectile.has_method("reset_for_reuse"):
		projectile.reset_for_reuse()
	else:
		# Reset genérico
		# Reseta tags
		if "tags" in projectile:
			projectile.tags.clear()
		
		# Reseta a física
		projectile.set_physics_process(true)
		
		# Reseta o Hurtbox se existir
		if projectile.has_node("Hurtbox"):
			var hurtbox = projectile.get_node("Hurtbox")
			hurtbox.call_deferred("set", "monitoring", true)
			hurtbox.call_deferred("set", "monitorable", true)
		
		# Reseta colisões - use call_deferred
		if projectile is CharacterBody2D:
			projectile.call_deferred("set", "collision_layer", 4)
			projectile.call_deferred("set", "collision_mask", 2)
			
			# Ativa todos os shapes de colisão
			for child in projectile.get_children():
				if child is CollisionShape2D or child is CollisionPolygon2D:
					child.call_deferred("set", "disabled", false)
	if projectile.get_parent():
		projectile.get_parent().remove_child(projectile)
	# Limpa metadados, exceto pooled e initialized
	_clear_meta_properties(projectile)

# Expande o pool criando mais instâncias
func _expand_pool(pool_name: String) -> void:
	var pool = pools[pool_name]
	
	# Verifica limite
	var total_size = pool.available.size() + pool.active.size()
	if total_size >= max_pool_size:
		return
	
	# Determina quantos objetos criar
	var create_count = min(expand_pool_size, max_pool_size - total_size)
	
	# Cria novas instâncias
	for i in range(create_count):
		var instance = pool.scene.instantiate()
		instance.process_mode = Node.PROCESS_MODE_DISABLED
		instance.visible = false
		instance.set_meta("pooled", true)
		pool.parent_node.call_deferred("add_child", instance)
		pool.available.append(instance)
		
		# Emite sinal para monitoramento
		emit_signal("projectile_created", pool_name)
		

# Limpa todas as propriedades de metadados
func _clear_meta_properties(node: Node) -> void:
	var meta_properties = node.get_meta_list()
	for prop in meta_properties:
		# Preserva certas metadados importantes
		if prop != "pooled" and prop != "initialized":
			node.remove_meta(prop)

# Método utilitário para verificar se um projétil é do pool
func is_pooled(projectile: Node) -> bool:
	return projectile.has_meta("pooled") and projectile.get_meta("pooled")

# Método integrado com o ArcherTalentManager para obter e configurar uma flecha
func get_arrow_with_talents(pool_name: String, archer: Soldier_Base, talent_manager: ArcherTalentManager) -> Node:
	# Obtém o projétil do pool
	var projectile = get_projectile(pool_name)
	if not projectile:
		return null
		
	# Reset completo do projétil
	reset_projectile(projectile)
	
	# Configura o atirador
	projectile.shooter = archer
	
	# Aplica talentos via TalentManager
	talent_manager.apply_talents_to_projectile(projectile)
	
	return projectile

func get_arrow_for_archer(archer: Soldier_Base) -> Node:
	# Nome do pool para flechas do arqueiro
	var pool_name = "arrow_" + str(archer.get_instance_id())
	# Verifica se o pool existe, caso contrário cria
	if not pool_name in pools:
		var arrow_scene = load("res://Test/Projectiles/Archer/Arrow.tscn")
		if not arrow_scene:
			return null
			
		create_pool(pool_name, arrow_scene, archer.get_parent())
	
	# MUDANÇA: Obtenha TODAS as flechas disponíveis
	var available_arrows = []
	for arrow in pools[pool_name].available:
		# Verifica se a flecha está marcada como parte de Arrow Rain
		if not arrow.has_meta("is_rain_arrow") and not arrow.has_meta("active_rain_processor_id"):
			available_arrows.append(arrow)
	
	# Se não houver flechas disponíveis, expande o pool
	if available_arrows.size() == 0:
		_expand_pool(pool_name)
		
		# Tenta novamente após expandir
		for arrow in pools[pool_name].available:
			if not arrow.has_meta("is_rain_arrow") and not arrow.has_meta("active_rain_processor_id"):
				available_arrows.append(arrow)
	
	# Se ainda não houver flechas disponíveis, cria uma nova
	if available_arrows.size() == 0:
		print("AVISO: Nenhuma flecha disponível mesmo após expandir o pool. Criando uma nova...")
		var arrow_scene = load("res://Test/Projectiles/Archer/Arrow.tscn")
		if not arrow_scene:
			return null
			
		var new_arrow = arrow_scene.instantiate()
		new_arrow.set_meta("pooled", true)
		
		# Adiciona à cena, mas não ao pool (flecha temporária)
		archer.get_parent().call_deferred("add_child", new_arrow)
		return new_arrow
	
	# Obtém a primeira flecha válida
	var arrow = available_arrows[0]
	
	# Remove do array de disponíveis
	var index = pools[pool_name].available.find(arrow)
	if index >= 0:
		pools[pool_name].available.remove_at(index)
	
	# Adiciona ao array de ativos
	pools[pool_name].active.append(arrow)
	
	# Prepara a flecha
	arrow.process_mode = Node.PROCESS_MODE_INHERIT
	arrow.visible = true
	
	# Emite sinal para monitoramento
	emit_signal("projectile_reused", pool_name)
	
	# Marca como pooled
	arrow.set_meta("pooled", true)
	
	print("Obtendo flecha do pool: ", arrow, " para uso normal")
	
	return arrow

# Função especial para obter flechas especificamente para Arrow Rain
func get_arrow_for_rain(archer: Soldier_Base) -> Node:
	# Nome do pool para flechas do arqueiro
	var pool_name = "arrow_" + str(archer.get_instance_id())
	# Verifica se o pool existe, caso contrário cria
	if not pool_name in pools:
		var arrow_scene = load("res://Test/Projectiles/Archer/Arrow.tscn")
		if not arrow_scene:
			return null
			
		create_pool(pool_name, arrow_scene, archer.get_parent())
	
	# Tenta encontrar uma flecha sem uso no pool
	var arrow = null
	
	# Primeiro, verifica no array de disponíveis
	if pools[pool_name].available.size() > 0:
		arrow = pools[pool_name].available[0]
		pools[pool_name].available.remove_at(0)
		pools[pool_name].active.append(arrow)
	else:
		# Se não houver disponíveis, expande o pool
		_expand_pool(pool_name)
		
		# Tenta novamente
		if pools[pool_name].available.size() > 0:
			arrow = pools[pool_name].available[0]
			pools[pool_name].available.remove_at(0)
			pools[pool_name].active.append(arrow)
		else:
			# Ainda sem flechas disponíveis, cria uma nova
			var arrow_scene = load("res://Test/Projectiles/Archer/Arrow.tscn")
			if not arrow_scene:
				return null
				
			arrow = arrow_scene.instantiate()
			arrow.set_meta("pooled", true)
			
			# A nova flecha vai direto para o array de ativos
			pools[pool_name].active.append(arrow)
	
	# Configura a flecha para uso
	arrow.process_mode = Node.PROCESS_MODE_INHERIT
	arrow.visible = true
	
	# IMPORTANTE: Marca a flecha como sendo usada para Arrow Rain
	arrow.set_meta("is_rain_arrow", true)
	
	# Emite sinal para monitoramento
	emit_signal("projectile_reused", pool_name)
	
	print("Obtendo flecha do pool: ", arrow, " para Arrow Rain")
	
	return arrow

func get_arrow_for_double_shot(archer: Soldier_Base) -> Node:
	# Pool name for the archer's second arrows
	var pool_name = "second_arrow_" + str(archer.get_instance_id())
	
	# Create pool if it doesn't exist
	if not pool_name in pools:
		var arrow_scene = load("res://Test/Projectiles/Archer/Arrow.tscn")
		if not arrow_scene:
			return null
			
		create_pool(pool_name, arrow_scene, archer.get_parent(), 10)  # Start with smaller pool
	
	# Get arrow from pool
	var arrow = null
	
	# Try to get an available arrow first
	if pools[pool_name].available.size() > 0:
		# Get the first available arrow
		arrow = pools[pool_name].available[0]
		
		# Make sure the arrow doesn't have a parent
		if arrow.get_parent():
			arrow.get_parent().remove_child(arrow)
			
		# Remove from available and add to active
		pools[pool_name].available.remove_at(0)
		pools[pool_name].active.append(arrow)
		
		# Reset arrow properties for reuse
		_reset_pooled_arrow(arrow)
		
		# Mark as pooled
		arrow.set_meta("pooled", true)
		
		# Mark as second arrow and no double shot
		arrow.set_meta("is_second_arrow", true)
		arrow.set_meta("no_double_shot", true)
		
		# Emit signal
		emit_signal("projectile_reused", pool_name)
		
		return arrow
	
	# If no available arrows, expand the pool
	_expand_pool(pool_name)
	
	# Try again
	if pools[pool_name].available.size() > 0:
		arrow = pools[pool_name].available[0]
		
		# Make sure the arrow doesn't have a parent
		if arrow.get_parent():
			arrow.get_parent().remove_child(arrow)
			
		# Remove from available and add to active
		pools[pool_name].available.remove_at(0)
		pools[pool_name].active.append(arrow)
		
		# Reset arrow properties for reuse
		_reset_pooled_arrow(arrow)
		
		# Mark as pooled
		arrow.set_meta("pooled", true)
		
		# Mark as second arrow and no double shot
		arrow.set_meta("is_second_arrow", true)
		arrow.set_meta("no_double_shot", true)
		
		# Emit signal
		emit_signal("projectile_reused", pool_name)
		
		return arrow
	
	# Fallback to instantiation if pool still fails
	var arrow_scene = load("res://Test/Projectiles/Archer/Arrow.tscn")
	if arrow_scene:
		var new_arrow = arrow_scene.instantiate()
		new_arrow.set_meta("pooled", true)
		new_arrow.set_meta("is_second_arrow", true)
		new_arrow.set_meta("no_double_shot", true)
		
		# Add to the active pool
		pools[pool_name].active.append(new_arrow)
		
		return new_arrow
		
	return null
# Helper function to reset a pooled arrow
func _reset_pooled_arrow(arrow: Node) -> void:
	# Reset basic properties
	arrow.process_mode = Node.PROCESS_MODE_INHERIT
	arrow.visible = true
	
	# Reset collision properties
	if arrow.has_node("Hurtbox"):
		var hurtbox = arrow.get_node("Hurtbox")
		hurtbox.set_deferred("monitoring", true)
		hurtbox.set_deferred("monitorable", true)
	
	# Reset layers
	if arrow is CharacterBody2D:
		arrow.set_deferred("collision_layer", 4)  # Projectile layer
		arrow.set_deferred("collision_mask", 2)   # Enemy layer
	
	# Call the arrow's reset method if available
	if arrow.has_method("reset_for_reuse"):
		arrow.reset_for_reuse()
		
func return_second_arrow_to_pool(arrow: Node) -> void:
	if not is_pooled(arrow) or not arrow.shooter:
		arrow.queue_free()
		return
	
	var archer = arrow.shooter
	var pool_name = "second_arrow_" + str(archer.get_instance_id())
	
	# Check if pool exists
	if not pool_name in pools:
		arrow.queue_free()
		return
	
	# First ensure the arrow is removed from parent
	if arrow.get_parent():
		# Handle this deferring instead of immediately to avoid errors
		arrow.get_parent().call_deferred("remove_child", arrow)
	
	# Reset arrow state for returning to pool
	arrow.call_deferred("set", "process_mode", Node.PROCESS_MODE_DISABLED)
	arrow.call_deferred("set", "visible", false)
	
	# Reset collision properties safely
	if arrow is CollisionObject2D:
		arrow.call_deferred("set", "monitoring", false)
		arrow.call_deferred("set", "monitorable", false)
	
	# For CharacterBody2D, reset collision layers
	if arrow is CharacterBody2D:
		arrow.call_deferred("set", "collision_layer", 0)
		arrow.call_deferred("set", "collision_mask", 0)
	
	# Find in active pool and move to available
	var index = pools[pool_name].active.find(arrow)
	if index >= 0:
		pools[pool_name].active.remove_at(index)
		
		# Add to available pool
		# Important: Add a small delay to ensure it's fully removed from parent first
		await arrow.get_tree().create_timer(0.05).timeout
		
		# Double-check it doesn't have a parent before adding to available
		if arrow.get_parent():
			print("WARNING: Arrow still has parent when returning to pool, force removing")
			arrow.get_parent().remove_child(arrow)
			
		pools[pool_name].available.append(arrow)
	
	# Emit signal for monitoring
	emit_signal("projectile_returned", pool_name)

# Retorna uma flecha ao seu pool de arqueiro
func return_arrow_to_pool(arrow: Node) -> void:
	if not is_pooled(arrow) or not arrow.shooter:
		print("AVISO: Tentativa de retornar flecha não-pooled ou sem atirador")
		return
		
	var archer = arrow.shooter
	var pool_name = "arrow_" + str(archer.get_instance_id())
	# Verifica se o pool existe
	if not pool_name in pools:
		print("AVISO: Pool não encontrado para: ", pool_name)
		return
	
	# LIMPEZA ESPECIAL para Arrow Rain
	if arrow.has_meta("is_rain_arrow") or arrow.has_meta("active_rain_processor_id"):
		print("Limpando flecha de Arrow Rain: ", arrow)
		
		# Remove os processadores
		var processors = []
		for child in arrow.get_children():
			if child.get_class() == "RainArrowProcessor" or (child.get_script() and "RainArrowProcessor" in child.get_script().get_path()):
				processors.append(child)
		
		for processor in processors:
			processor.queue_free()
		if has_meta("is_second_arrow"):
			ProjectilePool.instance.return_second_arrow_to_pool(self)
		else:
			ProjectilePool.instance.return_arrow_to_pool(self)
		# Remove metadados de Arrow Rain
		if arrow.has_meta("is_rain_arrow"):
			arrow.remove_meta("is_rain_arrow")
		if arrow.has_meta("active_rain_processor_id"):
			arrow.remove_meta("active_rain_processor_id")
		if arrow.has_meta("rain_start_pos"):
			arrow.remove_meta("rain_start_pos")
		if arrow.has_meta("rain_target_pos"):
			arrow.remove_meta("rain_target_pos")
		if arrow.has_meta("rain_time"):
			arrow.remove_meta("rain_time")
		if arrow.has_meta("rain_arc_height"):
			arrow.remove_meta("rain_arc_height")
		var current_parent = arrow.get_parent()
		current_parent.remove_child(arrow)
	# Continua com o processo normal de retorno
	return_projectile(pool_name, arrow)
	
# Method to run before returning to pool
func prepare_for_pool() -> void:
	# Remove any processors that could affect behavior when reused
	for child in get_children():
		if child is RainArrowProcessor or child.name == "RainArrowProcessor":
			child.queue_free()
	
	# Reset physics processing
	set_physics_process(false)
	
	# Only set velocity if the property exists
	if "velocity" in self:
		self.velocity = Vector2.ZERO
	
	# Clear all metadata except pooled flag
	var meta_list = get_meta_list()
	for prop in meta_list:
		if prop != "pooled":
			remove_meta(prop)
