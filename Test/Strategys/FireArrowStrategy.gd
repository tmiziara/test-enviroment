extends BaseProjectileStrategy
class_name FireArrowStrategy

# Valores para os modificadores
@export var physical_mod: float = 0.7
@export var fire_mod: float = 0.5
@export var dot_duration: float = 3.0
@export var dot_interval: float = 0.5

func apply_upgrade(projectile: Node) -> void:
	print("Aplicando FireArrowStrategy")
	
	# 1. Adiciona informações de tipo de dano ao projétil
	if not projectile.has_node("DamageInfo"):
		var damage_info = Node.new()
		damage_info.name = "DamageInfo"
		damage_info.set_meta("damage_types", {})
		projectile.add_child(damage_info)
	
	var damage_info = projectile.get_node("DamageInfo")
	var damage_types = damage_info.get_meta("damage_types")
	
	# Calcula o dano para cada tipo
	var base_damage = projectile.damage
	damage_types[DamageCalculator.DamageType.PHYSICAL] = int(base_damage * physical_mod)
	damage_types[DamageCalculator.DamageType.FIRE] = int(base_damage * fire_mod)
	
	# Atualiza os metadados
	damage_info.set_meta("damage_types", damage_types)
	
	# Configura DoT
	if dot_duration > 0:
		damage_info.set_meta("dot_duration", dot_duration)
		damage_info.set_meta("dot_interval", dot_interval)
	
	# 2. Atualiza o DamageDealerComponent do arqueiro (proprietário)
	var owner_entity = projectile.get_parent()
	if owner_entity and owner_entity.has_node("DamageDealerComponent"):
		var damage_dealer = owner_entity.get_node("DamageDealerComponent")
		damage_dealer.physical_mod = physical_mod
		damage_dealer.fire_mod = fire_mod
		damage_dealer.dot_duration = dot_duration
		damage_dealer.dot_interval = dot_interval
		
		print("DamageDealerComponent atualizado: fire_mod =", damage_dealer.fire_mod)
	
	# 3. Adiciona efeito visual de fogo
	if not projectile.has_node("FireParticles") and projectile is Node2D:
		var particles = CPUParticles2D.new()
		particles.name = "FireParticles"
		particles.amount = 15
		particles.lifetime = 0.5
		particles.color = Color(1.0, 0.5, 0.0, 0.8)
		particles.direction = Vector2.UP
		particles.gravity = Vector2(0, 0)
		particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
		particles.emission_sphere_radius = 2.0
		
		projectile.add_child(particles)
		particles.emitting = true
	
	print("Tipos de dano após FireArrowStrategy:", damage_types)
	print("Flecha de fogo aplicada! Dano total:", projectile.damage)
