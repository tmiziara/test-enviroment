extends Resource
class_name RangedAttack

@export var name: String = "Ataque Básico"  # Nome do ataque
@export var damage: int = 5  # Dano do ataque
@export var speed: float = 400.0  # Velocidade do projétil
@export var cooldown: float = 1.0  # Tempo de recarga do ataque
@export var tags: Array[String] = ["physical", "projectile"]  # Tags do ataque
@export var piercing: bool = false  # Flechas atravessam inimigos?
@export var ricochet: bool = false  # Flechas ricocheteiam?
@export var explosion_radius: float = 0.0  # Explosão ao impacto
@export var slow_effect: float = 0.0  # Lentidão aplicada
@export var projectile_count: int = 1  # Quantidade de projéteis disparados
@export var spread_angle: float = 0.0  # Ângulo de dispersão (caso dispare múltiplos projéteis)

# Aplica os atributos do ataque ao projétil
func apply_to_arrow(arrow):
	arrow.damage = damage
	arrow.speed = speed
	arrow.tags = tags.duplicate()  # Evita referências diretas"res://Test/basic_ranged_attack.tres"
	arrow.piercing = piercing
	arrow.ricochet = ricochet
	arrow.explosion_radius = explosion_radius
	arrow.slow_effect = slow_effect
