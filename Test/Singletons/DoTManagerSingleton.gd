# This file should be placed in a singleton location
# Add to your project's AutoLoad settings

extends Node

# This is a simple wrapper around the DoTManager to make it available as a singleton
# The actual implementation is in the DoTManager class

var dot_manager: DoTManager

func _ready():
	# Criar e adicionar o DoTManager como filho
	dot_manager = DoTManager.new()
	dot_manager.name = "DoTManager"
	add_child(dot_manager)
	
	# Opcionalmente, definir a instância estática se a classe DoTManager tiver tal campo
	DoTManager.instance = dot_manager
	
	print("DoTManager singleton initialized")

# Forward method calls to the DoTManager instance
func apply_dot(entity: Node, damage: int, duration: float, interval: float, 
			   dot_type: String = "generic", source: Node = null, 
			   should_stack: bool = false, max_stacks: int = 1) -> String:
	return dot_manager.apply_dot(entity, damage, duration, interval, dot_type, source, should_stack, max_stacks)

func has_dots(entity: Node) -> bool:
	return dot_manager.has_dots(entity)

func has_dot_type(entity: Node, dot_type: String) -> bool:
	return dot_manager.has_dot_type(entity, dot_type)

func get_entity_dots(entity: Node) -> Array:
	return dot_manager.get_entity_dots(entity)

func remove_all_dots(entity: Node) -> void:
	dot_manager.remove_all_dots(entity)

func remove_dots_of_type(entity: Node, dot_type: String) -> void:
	dot_manager.remove_dots_of_type(entity, dot_type)
