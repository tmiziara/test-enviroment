extends Soldier_Base
@onready var arrow_spawn: Marker2D = $Aim

@export var cost_coin: int = 10
@export var cost_food: int = 10
var unlocked_talents = {0: true}  # O talento 0 (básico) já está desbloqueado
var talent_points = 10
@export var attack_upgrades: Array[BaseProjectileStrategy] = []

func _ready():
	# Inicializa unlocked_talents se não existir
	if not unlocked_talents.has("0"):
		unlocked_talents = {"0": true}
	
	# Demais inicializações
	attack_range = 300.0
	move_speed = 25.0
	icon_texture = preload("res://Test/Assets/Icons/SoldierIcons/Bows000.png")
	super._ready()
	attack_timer.wait_time = 1.0
	attack_timer.start()
	
	# Aplica os efeitos dos talentos desbloqueados
	apply_talent_effects()
	
func _physics_process(delta):
	super._physics_process(delta)

# Sobrescreve a lógica de ataque
func _on_attack_timeout():
	if current_target and is_instance_valid(current_target) and is_target_in_range(current_target):
		if not is_attacking:  # Evita disparos duplicados
			is_attacking = true
			update_animation_speed()
			play_shooting_animation()
			
			# Sincroniza o spawn da flecha com a animação
			var animation_duration = get_animation_duration(get_active_blend_animation())
			
			spawn_arrow_after_delay(animation_duration)
			
			# Ajusta o cooldown do timer para evitar sobreposição
			attack_timer.wait_time = max(attack_cooldown, animation_duration)
			attack_timer.start()
	else:
		select_closest_target()

func play_shooting_animation():
	if current_target and is_instance_valid(current_target):
		update_animation_blend_position_to_target(current_target.global_position)
	animation_tree.set("parameters/StateMachine/conditions/is_moving", false)
	animation_tree.set("parameters/StateMachine/conditions/idle", false)
	animation_tree.set("parameters/StateMachine/conditions/shooting", true)
	animation_tree.advance(0)

# Spawna uma flecha após um atraso sincronizado com a animação
func spawn_arrow_after_delay(delay: float):
	get_tree().create_timer(delay).timeout.connect(func():
		if is_attacking:  # Confirma que ainda está no ciclo de ataque
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
	
	# Aplicar os upgrades
	for upgrade in attack_upgrades:
		upgrade.apply_upgrade(arrow)
	
	# IMPORTANTE: Force a inicialização do calculador de dano antes de adicionar à árvore
	if arrow.dmg_calculator:
		arrow.dmg_calculator.initialize_from_shooter(self)
	
	# Adiciona a flecha à cena
	get_parent().add_child(arrow)

func add_attack_upgrade(upgrade: BaseProjectileStrategy):
	attack_upgrades.append(upgrade)

func apply_talent_effects():
	# Limpa efeitos existentes
	reset_talent_effects()
	
	# Percorre os talentos desbloqueados
	for key in unlocked_talents.keys():
		# Determina o ID do talento (sempre como número)
		var talent_id = int(key)
		
		# Checa se está desbloqueado
		if unlocked_talents[key]:
			# Encontra o nó do talento correspondente
			var skill_node = find_talent_node(talent_id)
			
			# Se o talento tiver uma estratégia, aplica-a
			if skill_node and skill_node.talent_strategy:
				add_attack_upgrade(skill_node.talent_strategy)
			else:
				print("Talento", talent_id, "não tem estratégia ou nó não encontrado")

func reset_talent_effects():
	# Limpa upgrades existentes
	attack_upgrades.clear()
	
	# Reinicia outros atributos afetados por talentos
	# (Você pode adicionar mais resets conforme necessário)

func find_talent_node(talent_id: int) -> SkillNode:
	# Busca em todos os botões de talento na cena
	var skill_buttons = get_tree().get_nodes_in_group("skill_buttons")
	for button in skill_buttons:
		if button.talent_id == talent_id:
			return button
	return null

func get_current_target() -> Node2D:
	if current_target and is_instance_valid(current_target):
		return current_target
	return null
