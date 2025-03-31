extends Area2D
class_name Hurtbox

@onready var owner_entity: ProjectileBase = get_owner()  

func _ready():
	connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body):
	if not body.is_in_group("enemies") or not body.has_node("HealthComponent"):
		return
	
	# Verificar se este alvo já foi atingido (para suporte ao piercing)
	if owner_entity.has_meta("hit_targets"):
		var hit_targets = owner_entity.get_meta("hit_targets")
		if body in hit_targets:
			return
			
		# Adiciona o alvo à lista de alvos atingidos
		hit_targets.append(body)
		owner_entity.set_meta("hit_targets", hit_targets)
		
		# Atualiza a contagem de penetração
		if owner_entity.piercing:
			var current_pierce_count = hit_targets.size() - 1
			
			# Obter o máximo de penetrações permitidas
			var max_pierce = 1
			if owner_entity.has_meta("piercing_count"):
				max_pierce = owner_entity.get_meta("piercing_count")
			elif "piercing_count" in owner_entity:
				max_pierce = owner_entity.piercing_count
	
	# Check if this is a chain shot arrow that's already processing a ricochet
	if owner_entity is Arrow and owner_entity.has_method("process_on_hit"):
		if owner_entity.is_processing_ricochet:
			return
		owner_entity.process_on_hit(body)
	else:
		var health_component = body.get_node("HealthComponent")
		
		# Get calculated damage package
		var damage_package = owner_entity.get_damage_package()
		
		# Apply damage to enemy (including DoTs)
		if health_component.has_method("take_complex_damage"):
			health_component.take_complex_damage(damage_package)
		else:
			var physical_damage = damage_package.get("physical_damage", owner_entity.damage)
			var is_crit = damage_package.get("is_critical", owner_entity.is_crit)
			health_component.take_damage(physical_damage, is_crit)
		# managed in the Arrow.process_on_hit method for arrows
	return body
