extends CharacterBody2D

var direction: Vector2 = Vector2.ZERO
var speed: float = 400.0
var damage: int = 5
var crit_chance: float = 0.1  # Chance de crítico padrão
var tags: Array[String] = []
var piercing: bool = false
var ricochet: bool = false
var explosion_radius: float = 0.0
var slow_effect: float = 0.0
var dot_damage: int = 0  # Dano ao longo do tempo (DoT)
var dot_duration: float = 0.0  # Duração do DoT
var dot_interval: float = 1.0  # Tempo entre os ticks do DoT

var hit_enemies := {}  # Dicionário para armazenar os inimigos já atingidos

func _physics_process(delta):
	velocity = direction * speed
	move_and_slide()

	# Verifica todas as colisões ocorridas no frame
	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()

		if collider and collider.is_in_group("enemies") and collider not in hit_enemies:
			hit_enemies[collider] = true  # Marca esse inimigo como atingido
			
			# Verifica se o inimigo tem um HealthComponent
			if collider.has_node("HealthComponent"):
				var health_component = collider.get_node("HealthComponent")
				var is_crit = health_component.is_critical_hit(crit_chance)  # Verifica se foi crítico
				
				# Aplica dano normal ou crítico
				health_component.take_damage(damage, is_crit)

				# Aplica efeito DoT se existir
				if dot_damage > 0 and dot_duration > 0:
					health_component.apply_dot(dot_damage, dot_duration, dot_interval)

				# Aplica lentidão, se houver
				if slow_effect > 0:
					collider.apply_slow(slow_effect, 2.0)  # Reduz velocidade por 2 segundos

			if explosion_radius > 0:
				explode()

			if not piercing:  # Se não for perfurante, destruir o projétil
				queue_free()

# Lógica para explosão, causando dano em área
func explode():
	var enemies_in_radius = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies_in_radius:
		if global_position.distance_to(enemy.global_position) <= explosion_radius:
			if enemy.has_node("HealthComponent"):
				var health_component = enemy.get_node("HealthComponent")
				var is_crit = health_component.is_critical_hit(crit_chance)
				health_component.take_damage(damage, is_crit)
	queue_free()
