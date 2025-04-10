# detection_component.gd
extends Area2D
class_name DetectionComponent

@export var base_radius: float = 300.0  # Raio base
@export var radius_multiplier: float = 1.0  # Multiplicador para talentos

@onready var collision_shape: CollisionShape2D = null

# Referência ao soldado para sincronizar attack_range
var soldier: Node = null

func _ready():
	# Configura collision shape
	if not has_node("CollisionShape2D"):
		collision_shape = CollisionShape2D.new()
		var circle_shape = CircleShape2D.new()
		add_child(collision_shape)
	else:
		collision_shape = $CollisionShape2D
	
	# Configura área
	collision_layer = 1
	collision_mask = 2
	
	# Encontra o soldado pai
	soldier = get_parent()
	
	# Sincroniza raio inicial
	if soldier and "attack_range" in soldier:
		base_radius = soldier.attack_range
		update_detection_radius()

# Método para atualizar o raio de detecção
func update_detection_radius(new_multiplier: float = 1.0):
	radius_multiplier = new_multiplier
	
	var circle_shape = collision_shape.shape as CircleShape2D
	if circle_shape:
		# Sincroniza com attack_range do soldado
		if soldier and "attack_range" in soldier:
			soldier.attack_range = base_radius * radius_multiplier
		
		circle_shape.radius = base_radius * radius_multiplier
		print("Detection radius updated to: ", circle_shape.radius)

# Método para ser chamado por talentos
func increase_detection_radius(multiplier: float):
	update_detection_radius(radius_multiplier * multiplier)
