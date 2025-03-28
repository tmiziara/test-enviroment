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
	# O sistema fica pronto para ser usado, mas não
	# cria nenhum pool automaticamente
	pass

# Cria um novo pool
func create_pool(name: String, scene: PackedScene, parent: Node = self, initial_count: int = 0) -> void:
	if name in pools:
		printerr("Pool já existe: ", name)
		return
		
	var count = initial_count if initial_count > 0 else pre_instantiate_count
	pools[name] = Pool.new(scene, parent, count)

# Obtém um projétil do pool
func get_projectile(pool_name: String) -> Node:
	# Verifica se o pool existe
	if not pool_name in pools:
		printerr("Pool não existe: ", pool_name)
		return null
		
	var pool = pools[pool_name]
	
	# Se não houver objetos disponíveis, expande o pool
	if pool.available.size() == 0:
		_expand_pool(pool_name)
	
	# Retorna um objeto do pool
	if pool.available.size() > 0:
		var projectile = pool.available.pop_back()
		pool.active.append(projectile)
		projectile.process_mode = Node.PROCESS_MODE_INHERIT
		projectile.visible = true
		
		# Emite sinal para monitoramento
		emit_signal("projectile_reused", pool_name)
		
		return projectile
	
	# Se ainda não houver objetos disponíveis (máximo atingido)
	return null

# Devolve um projétil ao pool
func return_projectile(pool_name: String, projectile: Node) -> void:
	# Verifica se o pool existe
	if not pool_name in pools:
		printerr("Pool não existe: ", pool_name)
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
		printerr("Pool não existe: ", pool_name)
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
	
	# Limpa metadados, exceto pooled e initialized
	_clear_meta_properties(projectile)

# Expande o pool criando mais instâncias
func _expand_pool(pool_name: String) -> void:
	var pool = pools[pool_name]
	
	# Verifica limite
	var total_size = pool.available.size() + pool.active.size()
	if total_size >= max_pool_size:
		print("Limite máximo de pool atingido: ", pool_name)
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
		
	print("Pool expandido: ", pool_name, ", novas instâncias: ", create_count)

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
			printerr("Não foi possível carregar a cena da flecha")
			return null
			
		create_pool(pool_name, arrow_scene, archer.get_parent())
	
	# Obtém uma flecha do pool
	var arrow = get_projectile(pool_name)
	if not arrow:
		return null
	
	# Reset completo
	reset_projectile(arrow)
	
	# Configura o atirador
	arrow.shooter = archer
	
	# Verifica se o arqueiro tem um gerenciador de talentos
	# IMPORTANTE: Use apenas um método, não ambos!
	if archer.has_node("ArcherTalentManager"):
		var talent_manager = archer.get_node("ArcherTalentManager")
		print("Aplicando talentos VIA TALENT MANAGER")
		talent_manager.apply_talents_to_projectile(arrow)
	else:
		print("WARNING: Archer não tem TalentManager, não aplicando talentos")
	
	return arrow
# Retorna uma flecha ao seu pool de arqueiro
func return_arrow_to_pool(arrow: Node) -> void:
	if not is_pooled(arrow) or not arrow.shooter:
		# Se não for do pool ou não tiver atirador, ignora
		return
		
	var archer = arrow.shooter
	var pool_name = "arrow_" + str(archer.get_instance_id())
	
	# Verifica se o pool existe
	if not pool_name in pools:
		printerr("Pool não existe: ", pool_name)
		return
	
	# Devolve ao pool
	return_projectile(pool_name, arrow)
