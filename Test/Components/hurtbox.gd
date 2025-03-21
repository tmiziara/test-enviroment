extends Area2D
class_name Hurtbox

@onready var owner_entity: ProjectileBase = get_owner()  

func _ready():
	connect("body_entered", Callable(self, "_on_body_entered"))

# No hurtbox.gd
func _on_body_entered(body):
	if body.is_in_group("enemies") and body.has_node("HealthComponent"):
		# Verifica se o projétil tem o talento de Focused Shot
		if owner_entity.has_meta("check_focused_shot"):
			var check_method = owner_entity.get_meta("check_focused_shot")
			check_method.call(owner_entity, body)
		
		# Verifica se o calculador de dano tem o talento de Focused Shot
		if owner_entity.has_node("DmgCalculatorComponent"):
			var dmg_calc = owner_entity.get_node("DmgCalculatorComponent")
			if dmg_calc.has_meta("check_focused_shot"):
				var check_method = dmg_calc.get_meta("check_focused_shot")
				check_method.call(dmg_calc, body)
		
		# Pega o pacote de dano calculado
		var damage_package = owner_entity.get_damage_package()
		
		# Aplica dano ao inimigo (incluindo DoTs)
		if health_component.has_method("take_complex_damage"):
			health_component.take_complex_damage(damage_package)
		else:
			# Fallback para o método antigo
			var physical_damage = damage_package.get("physical_damage", owner_entity.damage)
			var is_crit = damage_package.get("is_critical", owner_entity.is_crit)
			health_component.take_damage(physical_damage, is_crit)
		
		# Garante que o projétil seja destruído corretamente
		if owner_entity and owner_entity is ProjectileBase:
			if not owner_entity.piercing:
				owner_entity.queue_free()
	return body
