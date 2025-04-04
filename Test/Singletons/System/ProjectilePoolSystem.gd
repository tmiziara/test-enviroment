extends Node
class_name ProjectilePoolSystem

# Configurações do pool
@export var pre_instantiate_count: int = 20
@export var expand_pool_size: int = 5
@export var max_pool_size: int = 100

# Organização de pools por categoria
var pool_categories = {
	"regular": {},     # Flechas regulares
	"double_shot": {}, # Flechas específicas para Double Shot
	"arrow_rain": {}   # Flechas específicas para Arrow Rain
}

# Sinais para monitoramento de desempenho
signal projectile_created(category, pool_name)
signal projectile_reused(category, pool_name)
signal projectile_returned(category, pool_name)

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
		print("Monitor de desempenho NÃO ENCONTRADO")

# Cria um novo pool em uma categoria específica
func create_category_pool(category: String, name: String, scene: PackedScene, parent: Node = self, initial_count: int = 0) -> void:
	# Validar a categoria
	if not category in pool_categories:
		print("Categoria de pool desconhecida: ", category)
		return
		
	# Verificar se já existe
	if name in pool_categories[category]:
		print("Pool já existe em ", category, ": ", name)
		return
		
	var count = initial_count if initial_count > 0 else pre_instantiate_count
	pool_categories[category][name] = Pool.new(scene, parent, count)
	print("Pool criado em ", category, ": ", name, " com ", count, " objetos")

# Adicione este método ao seu ProjectilePoolSystem.gd para compatibilidade
func create_pool(name: String, scene: PackedScene, parent: Node = self, initial_count: int = 0) -> void:
	# Compatibilidade com o sistema antigo - redireciona para o pool "regular"
	create_category_pool("regular", name, scene, parent, initial_count)

# Obtém um projétil de uma categoria e pool específicos
func get_projectile_from_category(category: String, name: String) -> Node:
	# Validar a categoria
	if not category in pool_categories:
		print("Categoria de pool desconhecida: ", category)
		return null
		
	# Verificar se o pool existe
	if not name in pool_categories[category]:
		print("Pool não encontrado em ", category, ": ", name)
		return null
		
	var pool = pool_categories[category][name]
	
	# Se não houver objetos disponíveis, expande o pool
	if pool.available.size() == 0:
		_expand_category_pool(category, name)
	
	# Retorna um objeto do pool
	if pool.available.size() > 0:
		var projectile = pool.available.pop_back()
		pool.active.append(projectile)
		
		projectile.set_meta("pooled", true)
		projectile.set_meta("pool_category", category)
		projectile.set_meta("pool_name", name)
		
		projectile.process_mode = Node.PROCESS_MODE_INHERIT
		projectile.visible = true
		
		# Emite sinal para monitoramento
		emit_signal("projectile_reused", category, name)
		
		return projectile
	
	return null

# Expande um pool específico de uma categoria
func _expand_category_pool(category: String, name: String) -> void:
	if not category in pool_categories or not name in pool_categories[category]:
		return
		
	var pool = pool_categories[category][name]
	
	# Verifica limite
	var total_size = pool.available.size() + pool.active.size()
	if total_size >= max_pool_size:
		print("Limite máximo de pool atingido para ", category, ": ", name)
		return
	
	# Determina quantos objetos criar
	var create_count = min(expand_pool_size, max_pool_size - total_size)
	
	# Cria novas instâncias
	for i in range(create_count):
		var instance = pool.scene.instantiate()
		instance.process_mode = Node.PROCESS_MODE_DISABLED
		instance.visible = false
		instance.set_meta("pooled", true)
		instance.set_meta("pool_category", category)
		instance.set_meta("pool_name", name)
		pool.parent_node.call_deferred("add_child", instance)
		pool.available.append(instance)
		
		# Emite sinal para monitoramento
		emit_signal("projectile_created", category, name)

# Devolve um projétil ao seu pool de origem
func return_projectile_to_category(projectile: Node) -> void:
	if not projectile.has_meta("pooled") or not projectile.has_meta("pool_category") or not projectile.has_meta("pool_name"):
		print("AVISO: Projétil não contém metadados de pool completos")
		return
		
	var category = projectile.get_meta("pool_category")
	var name = projectile.get_meta("pool_name")
	
	# Verifica se a categoria e o pool existem
	if not category in pool_categories or not name in pool_categories[category]:
		print("AVISO: Pool não encontrado para ", category, ": ", name)
		return
	
	var pool = pool_categories[category][name]
	
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
	
	# Reset the projectile before returning to pool
	reset_projectile(projectile)
	
	# Adiciona ao array de disponíveis
	pool.available.append(projectile)
	
	# Emite sinal para monitoramento
	emit_signal("projectile_returned", category, name)

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
	
	# Limpa metadados, exceto pooled, pool_category e pool_name
	_clear_meta_properties(projectile)

# Limpa todas as propriedades de metadados, preservando as relacionadas ao pool
func _clear_meta_properties(node: Node) -> void:
	var meta_properties = node.get_meta_list()
	for prop in meta_properties:
		# Preserva certas metadados importantes
		if prop != "pooled" and prop != "initialized" and prop != "pool_category" and prop != "pool_name":
			node.remove_meta(prop)

# Método utilitário para verificar se um projétil é do pool
func is_pooled(projectile: Node) -> bool:
	return projectile.has_meta("pooled") and projectile.get_meta("pooled") == true

# Obtém estatísticas de uma categoria de pool
func get_category_stats(category: String) -> Dictionary:
	if not category in pool_categories:
		return {}
		
	var available = 0
	var active = 0
	
	for pool_name in pool_categories[category]:
		var pool = pool_categories[category][pool_name]
		available += pool.available.size()
		active += pool.active.size()
	
	return {
		"available": available,
		"active": active,
		"total": available + active,
		"pools": pool_categories[category].size()
	}

#===== Métodos específicos para o arqueiro =====

# Inicializa os pools do arqueiro
func initialize_archer_pools(archer: Soldier_Base) -> void:
	var arrow_scene = load("res://Test/Projectiles/Archer/Arrow.tscn")
	if not arrow_scene:
		print("ERRO: Não foi possível carregar a cena da flecha")
		return
		
	var archer_id = str(archer.get_instance_id())
	
	# Cria um pool para flechas regulares
	create_category_pool("regular", archer_id, arrow_scene, archer.get_parent(), 20)
	
	# Cria um pool para Double Shot
	create_category_pool("double_shot", archer_id, arrow_scene, archer.get_parent(), 10)
	
	# Cria um pool para Arrow Rain
	create_category_pool("arrow_rain", archer_id, arrow_scene, archer.get_parent(), 30)
	
	print("Pools do arqueiro ", archer_id, " inicializados")

# Obtém uma flecha regular para o arqueiro
func get_regular_arrow(archer: Soldier_Base) -> Node:
	var archer_id = str(archer.get_instance_id())
	return get_projectile_from_category("regular", archer_id)

# Obtém uma flecha para Double Shot
func get_double_shot_arrow(archer: Soldier_Base) -> Node:
	var archer_id = str(archer.get_instance_id())
	return get_projectile_from_category("double_shot", archer_id)

# Obtém uma flecha para Arrow Rain
func get_arrow_rain_arrow(archer: Soldier_Base) -> Node:
	var archer_id = str(archer.get_instance_id())
	return get_projectile_from_category("arrow_rain", archer_id)

# Devolve uma flecha ao pool correto
func return_arrow(arrow: Node) -> void:
	if is_pooled(arrow):
		return_projectile_to_category(arrow)
	else:
		arrow.queue_free()

# Método para limpar todos os pools de um arqueiro
func clear_archer_pools(archer: Soldier_Base) -> void:
	var archer_id = str(archer.get_instance_id())
	
	# Lista de categorias para limpar
	var categories = ["regular", "double_shot", "arrow_rain"]
	
	for category in categories:
		if archer_id in pool_categories[category]:
			var pool = pool_categories[category][archer_id]
			
			# Retorna todas as flechas ativas para inativas
			var active_copy = pool.active.duplicate()
			for arrow in active_copy:
				if is_instance_valid(arrow):
					# Reseta e desativa a flecha
					arrow.set_physics_process(false)
					arrow.visible = false
					arrow.collision_layer = 0
					arrow.collision_mask = 0
					
					# Move da lista de ativos para disponíveis
					var index = pool.active.find(arrow)
					if index >= 0:
						pool.active.remove_at(index)
						pool.available.append(arrow)
					
					emit_signal("projectile_returned", category, archer_id)
			
			print("Pool ", category, " do arqueiro ", archer_id, " limpo: ", active_copy.size(), " flechas retornadas")
