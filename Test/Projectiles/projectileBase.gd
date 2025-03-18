extends CharacterBody2D
class_name ProjectileBase

@export var damage: int = 10
@export var crit_chance: float = 0.1
@export var speed: float = 400.0
@export var piercing: bool = false

var is_crit: bool = false  # O projétil calcula isso ao ser instanciado
var direction: Vector2 = Vector2.ZERO

func _ready():
	print("Projétil criado com crit_chance:", crit_chance)
	is_crit = is_critical_hit(crit_chance)

func _physics_process(delta):
	velocity = direction * speed
	move_and_slide()

func apply_dot(dot_damage: int, duration: float) -> void:
	print("Aplicando DoT de", dot_damage, "por", duration, "segundos")
# Função que verifica se o ataque será crítico
func is_critical_hit(crit_chance: float) -> bool:
	var roll = randf()
	var result = roll < crit_chance
	return result
