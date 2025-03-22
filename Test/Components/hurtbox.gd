extends Area2D
class_name Hurtbox

@onready var owner_entity: ProjectileBase = get_owner()  

func _ready():
	connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body):
	if body.is_in_group("enemies") and body.has_node("HealthComponent"):
		var health_component = body.get_node("HealthComponent")
		
		# Chamada ao método process_on_hit (se existir)
		if owner_entity.has_method("process_on_hit"):
			owner_entity.process_on_hit(body)
		
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
		
		# Verifica se o projétil deve ser destruído após atingir um alvo
		if owner_entity and owner_entity is ProjectileBase:
			if owner_entity.piercing:
				# Verifica se o projétil tem um contador de atravessamentos
				var current_count = 0
				if owner_entity.has_meta("current_pierce_count"):
					current_count = owner_entity.get_meta("current_pierce_count")
				
				# Incrementa o contador de inimigos atravessados
				current_count += 1
				owner_entity.set_meta("current_pierce_count", current_count)
				
				# Obtém o limite máximo de atravessamentos adicionais
				var max_pierce = 1  # Valor padrão para inimigos adicionais
				if owner_entity.has_meta("piercing_count"):
					max_pierce = owner_entity.get_meta("piercing_count")
				
				print("Flecha atravessou ", current_count, " de ", max_pierce + 1, " inimigos possíveis")
				
				# Se já atravessou mais do que o máximo permitido, destrói o projétil
				# max_pierce = número de inimigos ADICIONAIS, então a flecha pode atingir max_pierce + 1 no total
				if current_count > max_pierce:
					print("Limite de atravessamento atingido, destruindo flecha")
					owner_entity.queue_free()
			else:
				# Se não for perfurante, destrói após o primeiro hit
				owner_entity.queue_free()
	
	return body
