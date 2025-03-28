extends Node
# Singleton para acesso global ao sistema de pooling de projéteis

# Referência a si mesmo para acesso global
var instance: ProjectilePoolSystem

func _ready():
	# Cria a instância do sistema de pooling de forma segura
	call_deferred("_initialize_pool_system")

# Método deferido para inicialização segura 
func _initialize_pool_system():
	instance = ProjectilePoolSystem.new()
	instance.name = "ProjectilePoolSystem"
	add_child(instance)
	
	# Configurações padrão
	instance.pre_instantiate_count = 30
	instance.expand_pool_size = 10
	instance.max_pool_size = 200

# Método de conveniência para obter flechas para o arqueiro
func get_arrow(archer: Soldier_Base) -> Node:
	# Verifica se a instância já está disponível
	if not instance:
		return null
		
	return instance.get_arrow_for_archer(archer)

# Método de conveniência para retornar flechas ao pool
func return_arrow(arrow: Node) -> void:
	# Verifica se a instância já está disponível
	if not instance:
		return
		
	instance.return_arrow_to_pool(arrow)

# Método para criar um pool específico
func create_pool(name: String, scene: PackedScene, parent: Node = null, initial_count: int = 0) -> void:
	# Verifica se a instância já está disponível
	if not instance:
		return
		
	# Se parent for nulo, usa o nó pai deste singleton
	var pool_parent = parent if parent else get_parent()
	instance.create_pool(name, scene, pool_parent, initial_count)
