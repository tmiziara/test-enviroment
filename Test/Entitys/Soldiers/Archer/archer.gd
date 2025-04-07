extends SoldierBase
class_name ArcherBase

# ======== REFERÊNCIAS E EXPORTS ========
@onready var arrow_spawn: Marker2D = $ArrowSpawn
@onready var buff_display_container = $BuffDisplayContainer

# ======== CONFIGURAÇÕES ESPECÍFICAS DO ARQUEIRO ========
@export var cost_coin: int = 10
@export var cost_food: int = 10
@export var attack_upgrades: Array[BaseProjectileStrategy] = []

# ======== SISTEMA DE TALENTOS ========
var unlocked_talents = {0: true}  # Talento básico (0) já desbloqueado
var talent_points = 10
var talent_system: ArcherTalentSystem  # Agora usando ArcherTalentSystem em vez de ArcherTalentManager

# ======== MÉTODO DE INICIALIZAÇÃO DO SOLDADO ========
func _init_soldier() -> void:
	# Configurações base específicas do arqueiro
	base_attack_range = 300.0
	base_move_speed = 25.0
	base_damage = 15
	main_stat = 10  # DEX para arqueiros
	
	# Criação do gerenciador de talentos
	# Agora usamos o ArcherTalentSystem em vez do ArcherTalentManager
	talent_system = ArcherTalentSystem.new(self)
	add_child(talent_system)
	
	# Conexão do sinal de mudança de alvo ao talent_system
	connect("target_change", talent_system._on_target_change)

func _ready():
	# Chama o _ready do pai primeiro
	super._ready()
	
	# Configurações específicas do arqueiro
	icon_texture = preload("res://Test/Assets/Icons/SoldierIcons/Bows000.png")
	
	# Inicia o timer de ataque
	attack_timer.wait_time = attack_cooldown
	attack_timer.start()
	
	# Aplica efeitos de talentos
	apply_talent_effects()

# ======== MÉTODOS DE SELEÇÃO DE ALVO ========
func select_closest_target() -> Node:
	# Encontra todos os inimigos
	var enemies = get_tree().get_nodes_in_group("enemies")
	var closest_enemy = null
	var closest_dist = INF
	
	# Procura pelo inimigo mais próximo
	for enemy in enemies:
		if not is_instance_valid(enemy) or not enemy.has_node("HealthComponent"):
			continue
			
		var dist = global_position.distance_to(enemy.global_position)
		if dist < closest_dist and dist <= attack_range:
			closest_dist = dist
			closest_enemy = enemy
	
	return closest_enemy

func _update_target() -> void:
	# Se não tivermos um alvo ou ele não for válido, procura um novo
	if not current_target or not is_instance_valid(current_target):
		var new_target = select_closest_target()
		if new_target:
			set_target(new_target)

# ======== MÉTODOS DE ATAQUE E ANIMAÇÃO ========
func _on_attack_timeout():
	if current_target and is_instance_valid(current_target) and is_target_in_range(current_target):
		if not is_attacking:  # Evita disparos duplicados
			is_attacking = true
			update_animation_speed()
			play_shooting_animation()
			
			# Sincroniza o spawn da flecha com a animação
			var animation_duration = get_animation_duration(get_active_blend_animation())
			
			# Verifica se o arqueiro tem Double Shot ativo
			if has_meta("double_shot_active") and get_meta("double_shot_active"):
				spawn_double_shot_after_delay(animation_duration)
			else:
				spawn_arrow_after_delay(animation_duration)
			
			# Ajusta o cooldown do timer para evitar sobreposição
			attack_timer.wait_time = max(attack_cooldown, animation_duration)
			attack_timer.start()
	else:
		select_closest_target()

func play_shooting_animation():
	if current_target and is_instance_valid(current_target):
		update_animation_blend_position_to_target(current_target.global_position)
	
	# Ativa a animação de tiro
	animation_tree.set("parameters/StateMachine/conditions/is_moving", false)
	animation_tree.set("parameters/StateMachine/conditions/idle", false)
	animation_tree.set("parameters/StateMachine/conditions/shooting", true)
	animation_tree.advance(0)  # Força a atualização imediata da animação

# Sobrescreve para configurar a duração da animação de tiro
func get_animation_duration(animation_name: String) -> float:
	match animation_name:
		"Shoot":
			# Ajuste a duração conforme a animação específica do arqueiro
			return 0.4 / attack_animation_speed
		_:
			return super.get_animation_duration(animation_name)

# Spawna uma flecha após um atraso sincronizado com a animação
func spawn_arrow_after_delay(delay: float):
	get_tree().create_timer(delay).timeout.connect(func():
		if is_attacking:  # Confirma que ainda está no ciclo de ataque
			spawn_arrow()
			reset_attack()
	)

# Método para spawnar flecha dupla após atraso
func spawn_double_shot_after_delay(delay: float):
	get_tree().create_timer(delay).timeout.connect(func():
		if is_attacking:  # Confirma que ainda está no ciclo de ataque
			spawn_double_shot_arrows()
			reset_attack()
	)

# ======== MÉTODOS DE SPAWN DE PROJÉTEIS ========
func spawn_arrow():
	if not current_target or not is_instance_valid(current_target):
		return  
	
	var arrow_scene = preload("res://Test/Projectiles/Archer/Arrow.tscn")  
	var arrow = arrow_scene.instantiate()
	
	# Configurações básicas da flecha
	arrow.global_position = arrow_spawn.global_position
	arrow.direction = (current_target.global_position - arrow_spawn.global_position).normalized()
	arrow.rotation = arrow.direction.angle()
	
	# IMPORTANTE: Define o atirador ANTES de adicionar a flecha à árvore
	arrow.shooter = self
	
	# Calcula o acerto crítico
	if "crit_chance" in arrow:
		arrow.crit_chance = crit_chance
	if arrow.has_method("_calculate_critical_hit"):
		arrow.is_crit = arrow._calculate_critical_hit()
	
	# Se tiver um calculador de dano, inicializa
	if arrow.has_node("DmgCalculatorComponent"):
		var dmg_calc = arrow.get_node("DmgCalculatorComponent")
		dmg_calc.initialize_from_shooter(self)
	
	# Aplica upgrades de talentos
	for upgrade in attack_upgrades:
		if upgrade:
			upgrade.apply_upgrade(arrow)
	
	# Usa o talent_system para aplicar efeitos compilados
	if talent_system:
		var effects = talent_system.compile_archer_effects()
		talent_system.apply_effects_to_projectile(arrow, effects)
	
	# Adiciona a flecha à cena
	get_parent().add_child(arrow)

# Método para spawnar flechas duplas (Double Shot)
func spawn_double_shot_arrows():
	if not current_target or not is_instance_valid(current_target):
		return
	
	# Obtém ângulo de separação dos metadados ou usa valor padrão
	var angle_spread = get_meta("double_shot_angle", 15.0)
	
	# Calcula os ângulos para as duas flechas
	var target_dir = (current_target.global_position - arrow_spawn.global_position).normalized()
	var angle_left = target_dir.rotated(deg_to_rad(-angle_spread/2))
	var angle_right = target_dir.rotated(deg_to_rad(angle_spread/2))
	
	# Spawn da primeira flecha (ângulo esquerdo)
	var arrow_scene = preload("res://Test/Projectiles/Archer/Arrow.tscn")
	var arrow_left = arrow_scene.instantiate()
	
	# Configuração da flecha esquerda
	arrow_left.global_position = arrow_spawn.global_position
	arrow_left.direction = angle_left
	arrow_left.rotation = angle_left.angle()
	arrow_left.shooter = self
	arrow_left.set_meta("is_double_shot", true)
	arrow_left.set_meta("is_left_arrow", true)
	
	# Segunda flecha (ângulo direito)
	var arrow_right = arrow_scene.instantiate()
	
	# Configuração da flecha direita
	arrow_right.global_position = arrow_spawn.global_position
	arrow_right.direction = angle_right
	arrow_right.rotation = angle_right.angle()
	arrow_right.shooter = self
	arrow_right.set_meta("is_double_shot", true)
	arrow_right.set_meta("is_right_arrow", true)
	
	# Inicializa calculadores de dano
	if arrow_left.has_node("DmgCalculatorComponent"):
		arrow_left.get_node("DmgCalculatorComponent").initialize_from_shooter(self)
	
	if arrow_right.has_node("DmgCalculatorComponent"):
		arrow_right.get_node("DmgCalculatorComponent").initialize_from_shooter(self)
	
	# Calcula acertos críticos independentemente
	if "crit_chance" in self:
		if arrow_left.has_method("_calculate_critical_hit"):
			arrow_left.crit_chance = self.crit_chance
			arrow_left.is_crit = arrow_left._calculate_critical_hit()
		
		if arrow_right.has_method("_calculate_critical_hit"):
			arrow_right.crit_chance = self.crit_chance
			arrow_right.is_crit = arrow_right._calculate_critical_hit()
	
	# Aplica efeitos de talentos
	for upgrade in attack_upgrades:
		if upgrade and not upgrade is DoubleShot:  # Evita loop infinito
			upgrade.apply_upgrade(arrow_left)
			upgrade.apply_upgrade(arrow_right)
	
	# Usa o talent_system para aplicar efeitos compilados
	if talent_system:
		var effects = talent_system.compile_archer_effects()
		talent_system.apply_effects_to_projectile(arrow_left, effects)
		talent_system.apply_effects_to_projectile(arrow_right, effects)
	
	# Adiciona à cena
	get_parent().add_child(arrow_left)
	get_parent().add_child(arrow_right)

# ======== MÉTODOS DE SISTEMA DE TALENTOS ========
func add_attack_upgrade(upgrade: BaseProjectileStrategy):
	if upgrade not in attack_upgrades:
		attack_upgrades.append(upgrade)
		
		# Se for o upgrade de Double Shot, inicializa-o especialmente
		if upgrade is DoubleShot:
			upgrade.initialize_with_archer(self)

func apply_talent_effects():
	# Reseta efeitos para evitar duplicação
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
	
	# Refresh nos talentos através do sistema
	if talent_system:
		var effects = talent_system.compile_archer_effects()
		talent_system.apply_effects_to_soldier(self, effects)
	
	# Marca que os talentos foram atualizados
	set_meta("talents_updated", true)
	
	# Recalcula os stats para aplicar modificadores
	recalculate_stats()

func reset_talent_effects():
	# Limpa upgrades existentes
	attack_upgrades.clear()
	
	# Reseta modificadores aos valores padrão
	damage_multiplier = 1.0
	range_multiplier = 1.0
	cooldown_multiplier = 1.0
	speed_multiplier = 1.0
	
	# Reseta Double Shot e outros metadados
	if has_meta("double_shot_active"):
		remove_meta("double_shot_active")
	if has_meta("has_double_shot"):
		remove_meta("has_double_shot")
	if has_meta("double_shot_angle"):
		remove_meta("double_shot_angle")
	if has_meta("double_shot_damage_modifier"):
		remove_meta("double_shot_damage_modifier")

func find_talent_node(talent_id: int) -> Node:
	# Busca em todos os botões de talento na cena
	var skill_buttons = get_tree().get_nodes_in_group("skill_buttons")
	for button in skill_buttons:
		if button.talent_id == talent_id:
			return button
	return null

# Helper function to convert degrees to radians
func deg_to_rad(degrees: float) -> float:
	return degrees * (PI / 180.0)
