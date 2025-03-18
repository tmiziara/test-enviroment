extends Soldier_Base

@onready var arrow_spawn: Marker2D = $Aim  # Local de onde as flechas são disparadas

@export var cost_coin: int = 10
@export var cost_food: int = 10

# Lista de estratégias aplicadas às flechas
@export var attack_upgrades: Array[BaseProjectileStrategy] = []

# Referência ao DamageDealerComponent
var damage_dealer: Node

func _ready():
	attack_range = 300.0
	move_speed = 25.0
	icon_texture = preload("res://Test/Assets/Icons/SoldierIcons/Bows000.png")
	
	# Inicializa o componente de dano
	setup_damage_dealer()
	
	# Define dano de fogo manualmente
	damage_dealer.physical_mod = 0.7
	damage_dealer.fire_mod = 0.5
	damage_dealer.dot_duration = 3.0
	damage_dealer.dot_interval = 0.5
	
	super._ready()
	attack_timer.wait_time = 1.0
	attack_timer.start()

func setup_damage_dealer():
	# Cria ou obtém o componente
	if has_node("DamageDealerComponent"):
		damage_dealer = get_node("DamageDealerComponent")
	else:
		damage_dealer = DamageDealerComponent.new()
		damage_dealer.name = "DamageDealerComponent"
		add_child(damage_dealer)
	
	# Configuração básica
	damage_dealer.base_damage = 10
	damage_dealer.crit_chance = 0.1
	damage_dealer.physical_mod = 1.0

func _physics_process(delta):
	super._physics_process(delta)

func _on_attack_timeout():
	if current_target and is_instance_valid(current_target) and is_target_in_range(current_target):
		if not is_attacking:
			is_attacking = true
			update_animation_speed()
			play_shooting_animation()
			var animation_duration = get_animation_duration(get_active_blend_animation())
			spawn_arrow_after_delay(animation_duration)
			attack_timer.wait_time = max(1.0, animation_duration)
	else:
		select_closest_target()

func play_shooting_animation():
	if current_target and is_instance_valid(current_target):
		update_animation_blend_position_to_target(current_target.global_position)
	animation_tree.set("parameters/StateMachine/conditions/is_moving", false)
	animation_tree.set("parameters/StateMachine/conditions/idle", false)
	animation_tree.set("parameters/StateMachine/conditions/shooting", true)
	animation_tree.advance(0)

func spawn_arrow_after_delay(delay: float):
	get_tree().create_timer(delay).timeout.connect(func():
		if is_attacking:
			spawn_arrow()
			reset_attack())

func spawn_arrow():
	if not current_target or not is_instance_valid(current_target):
		return  
	
	var arrow_scene = preload("res://Test/Projectiles/Archer/Arrow.tscn")  
	var arrow = arrow_scene.instantiate() as ProjectileBase  
	arrow.global_position = arrow_spawn.global_position  
	arrow.direction = (current_target.global_position - arrow_spawn.global_position).normalized()
	arrow.rotation = arrow.direction.angle()
	
	# Configura o dano base da flecha
	arrow.damage = damage_dealer.base_damage
	arrow.crit_chance = damage_dealer.crit_chance
	arrow.is_crit = randf() < arrow.crit_chance
	
	print("Antes do upgrade - crit_chance da flecha:", arrow.crit_chance)
	
	# Define tipos de dano manualmente
	if arrow.has_node("DamageInfo"):
		arrow.get_node("DamageInfo").queue_free()
	
	var damage_info = Node.new()
	damage_info.name = "DamageInfo"
	var damage_types = {}
	
	# Define tipos de dano diretamente
	damage_types[DamageCalculator.DamageType.PHYSICAL] = int(arrow.damage * 0.7)
	damage_types[DamageCalculator.DamageType.FIRE] = int(arrow.damage * 0.5)
	
	damage_info.set_meta("damage_types", damage_types)
	damage_info.set_meta("dot_duration", 3.0)
	damage_info.set_meta("dot_interval", 0.5)
	
	arrow.add_child(damage_info)
	
	print("Tipos de dano definidos manualmente:", damage_types)
	
	# Aplica as estratégias
	for upgrade in attack_upgrades:
		print("Aplicando upgrade:", upgrade)
		upgrade.apply_upgrade(arrow)
	
	# Verifica os tipos de dano após as estratégias
	damage_types = damage_info.get_meta("damage_types")
	print("Tipos de dano após estratégias:", damage_types)
	
	# Adiciona efeito visual de fogo
	if not arrow.has_node("FireParticles") and arrow is Node2D:
		var particles = CPUParticles2D.new()
		particles.name = "FireParticles"
		particles.amount = 15
		particles.lifetime = 0.5
		particles.color = Color(1.0, 0.5, 0.0, 0.8)
		particles.direction = Vector2.UP
		particles.gravity = Vector2(0, 0)
		particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
		particles.emission_sphere_radius = 2.0
		
		arrow.add_child(particles)
		particles.emitting = true
	
	# Adiciona um rastro de fogo simples
	if damage_types.has(DamageCalculator.DamageType.FIRE) and not arrow.has_node("FireTrail"):
		var trail = Line2D.new()
		trail.name = "FireTrail"
		trail.width = 3.0
		trail.default_color = Color(1.0, 0.5, 0.0, 0.7)  # Cor de fogo
		arrow.add_child(trail)
		
		# Adiciona script para o rastro
		var script = GDScript.new()
		script.source_code = """
extends Line2D

var max_points = 20
var target: Node2D

func _ready():
	target = get_parent()
	top_level = true
	global_position = Vector2.ZERO
	add_point(target.global_position)

func _process(_delta):
	if not is_instance_valid(target):
		queue_free()
		return
		
	add_point(target.global_position)
	
	if points.size() > max_points:
		remove_point(0)
"""
		script.reload()
		trail.set_script(script)
	
	print("Depois do upgrade - crit_chance da flecha:", arrow.crit_chance)
	
	# Adiciona a flecha à cena
	get_parent().add_child(arrow)

func add_attack_upgrade(upgrade: BaseProjectileStrategy):
	attack_upgrades.append(upgrade)
	
	if upgrade is DamageModifierStrategy:
		update_damage_dealer_from_strategy(upgrade)

func update_damage_dealer_from_strategy(strategy: DamageModifierStrategy):
	if not damage_dealer:
		return
	
	if strategy.physical_mod > 0:
		damage_dealer.physical_mod = strategy.physical_mod
	if strategy.fire_mod > 0:
		damage_dealer.fire_mod = strategy.fire_mod
	if strategy.ice_mod > 0:
		damage_dealer.ice_mod = strategy.ice_mod
	if strategy.wind_mod > 0:
		damage_dealer.wind_mod = strategy.wind_mod
	if strategy.electric_mod > 0:
		damage_dealer.electric_mod = strategy.electric_mod
	if strategy.poison_mod > 0:
		damage_dealer.poison_mod = strategy.poison_mod
	if strategy.bleed_mod > 0:
		damage_dealer.bleed_mod = strategy.bleed_mod
	if strategy.magic_mod > 0:
		damage_dealer.magic_mod = strategy.magic_mod
	
	if strategy.dot_duration > 0:
		damage_dealer.dot_duration = strategy.dot_duration
		damage_dealer.dot_interval = strategy.dot_interval

func get_predominant_damage_type(damage_types: Dictionary) -> int:
	var strongest_type = DamageCalculator.DamageType.PHYSICAL
	var strongest_value = 0
	
	for dmg_type in damage_types:
		if damage_types[dmg_type] > strongest_value:
			strongest_value = damage_types[dmg_type]
			strongest_type = dmg_type
	
	return strongest_type

func reset_attack():
	is_attacking = false
	animation_tree.set("parameters/TimeScale/scale", 1)
