extends Soldier_Base

@onready var arrow_spawn: Marker2D = $Aim  # Local de onde as flechas são disparadas

@export var cost_coin: int = 10
@export var cost_food: int = 10


@export var attack_upgrades: Array[BaseProjectileStrategy] = []  # Lista de estratégias aplicadas às flechas

func _ready():
	attack_range = 300.0
	move_speed = 25.0
	icon_texture = preload("res://Test/Assets/Icons/SoldierIcons/Bows000.png")
	super._ready()
	attack_timer.wait_time = 1.0  # Tempo fixo entre ataques
	attack_timer.start()
		# Adiciona a estratégia de crítico ao arqueiro no início do jogo

func _physics_process(delta):
	super._physics_process(delta)

# Controla o ataque automático
func _on_attack_timeout():
	if current_target and is_instance_valid(current_target) and is_target_in_range(current_target):
		if not is_attacking:
			is_attacking = true
			update_animation_speed()
			play_shooting_animation()
			var animation_duration = get_animation_duration(get_active_blend_animation())
			spawn_arrow_after_delay(animation_duration)
			attack_timer.wait_time = max(1.0, animation_duration)  # Tempo de recarga fixo
	else:
		select_closest_target()

# Inicia a animação de ataque
func play_shooting_animation():
	if current_target and is_instance_valid(current_target):
		update_animation_blend_position_to_target(current_target.global_position)
	animation_tree.set("parameters/StateMachine/conditions/is_moving", false)
	animation_tree.set("parameters/StateMachine/conditions/idle", false)
	animation_tree.set("parameters/StateMachine/conditions/shooting", true)
	animation_tree.advance(0)

# Dispara a flecha sincronizada com a animação
func spawn_arrow_after_delay(delay: float):
	get_tree().create_timer(delay).timeout.connect(func():
		if is_attacking:
			spawn_arrow()
			reset_attack())

# Spawna a flecha e aplica os upgrades
func spawn_arrow():
	if not current_target or not is_instance_valid(current_target):
		return  
	var arrow_scene = preload("res://Test/Projectiles/Archer/Arrow.tscn")  
	var arrow = arrow_scene.instantiate() as ProjectileBase  
	
	# Configurações da flecha
	arrow.global_position = arrow_spawn.global_position  
	arrow.direction = (current_target.global_position - arrow_spawn.global_position).normalized()
	arrow.rotation = arrow.direction.angle()
	
	# IMPORTANTE: Defina o atirador ANTES de adicionar a flecha à árvore
	arrow.shooter = self
	print("Archer: Definindo shooter da flecha. Main stat:", main_stat)
	
	# Aplicar os upgrades
	for upgrade in attack_upgrades:
		print("Aplicando upgrade:", upgrade)
		upgrade.apply_upgrade(arrow)
	
	# IMPORTANTE: Force a inicialização do calculador de dano antes de adicionar à árvore
	if arrow.dmg_calculator:
		arrow.dmg_calculator.initialize_from_shooter(self)
	
	# Adiciona a flecha à cena
	get_parent().add_child(arrow)

# Método para adicionar upgrades ao ataque do arqueiro
func add_attack_upgrade(upgrade: BaseProjectileStrategy):
	attack_upgrades.append(upgrade)
