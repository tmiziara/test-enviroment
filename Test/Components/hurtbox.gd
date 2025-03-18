extends Area2D
class_name Hurtbox

@onready var owner_entity: ProjectileBase = get_owner()  

func _ready():
	connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body):
	print("O owner é ", owner_entity)
	if body.is_in_group("enemies") and body.has_node("HealthComponent"):
		var health_component = body.get_node("HealthComponent")
		# Aplica dano ao inimigo
		health_component.take_damage(get_owner().damage,get_owner().crit_chance, get_owner().is_crit)
		# Garante que o projétil seja destruído corretamente
		if owner_entity and owner_entity is ProjectileBase:
			if not owner_entity.piercing:
				owner_entity.queue_free()
