extends Area2D
class_name NewHurtbox

@onready var owner_entity: NewProjectileBase = get_owner()  

func _ready():
	connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body):
	print("Hurtbox._on_body_entered called with: ", body)
	
	if not body.is_in_group("enemies") or not body.has_node("HealthComponent"):
		print("Body is not an enemy or doesn't have HealthComponent")
		return
	
	# Verificação de alvos atingidos para piercing
	if owner_entity.has_meta("hit_targets"):
		var hit_targets = owner_entity.get_meta("hit_targets")
		if body in hit_targets:
			print("Este alvo já foi atingido por esta flecha, ignorando.")
			return
			
		# Adiciona o alvo à lista de alvos atingidos
		hit_targets.append(body)
		owner_entity.set_meta("hit_targets", hit_targets)
		
		# Atualiza a contagem de penetração
		if owner_entity.piercing:
			var current_pierce_count = hit_targets.size() - 1
			print("Contagem de penetração atual: ", current_pierce_count)
			
			# Obtém o máximo de penetrações permitidas 
			# Usa a nova forma de obter piercing_count
			var max_pierce = 1
			if owner_entity.has_meta("piercing_count"):
				max_pierce = owner_entity.get_meta("piercing_count")
			
			print("Penetração: ", current_pierce_count, "/", max_pierce)
			
			# Verifica se atingiu o limite de penetração
			if current_pierce_count >= max_pierce:
				print("Limite de penetração alcançado, destruindo projétil")
				owner_entity.queue_free()
				return
	
	# Processamento de hit para Arrow
	if owner_entity is NewArrow and owner_entity.has_method("process_on_hit"):
		if owner_entity.is_processing_ricochet:
			print("Arrow is currently processing ricochet - ignoring hit")
			return
		
		print("Calling Arrow.process_on_hit")
		owner_entity.process_on_hit(body)
	else:
		print("Standard projectile hit processing")
		var health_component = body.get_node("HealthComponent")
		
		# Obtém o pacote de dano calculado
		var damage_package = owner_entity.get_damage_package()
		
		# Aplica dano ao inimigo (incluindo DoTs)
		if health_component.has_method("take_complex_damage"):
			print("Applying complex damage")
			health_component.take_complex_damage(damage_package)
		else:
			# Fallback para método antigo
			print("Applying simple damage")
			var physical_damage = damage_package.get("physical_damage", owner_entity.damage)
			var is_crit = damage_package.get("is_critical", owner_entity.is_crit)
			health_component.take_damage(physical_damage, is_crit)
		
		# Destrói o projétil não-Arrow se não for piercing
		if not owner_entity is NewArrow:
			if not owner_entity.piercing:
				print("Non-piercing projectile hit, destroying")
				owner_entity.queue_free()
	
	return body
