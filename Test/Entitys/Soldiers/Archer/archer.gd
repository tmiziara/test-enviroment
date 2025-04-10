extends SoldierBase
class_name ArcherBase

# ======== REFERENCES AND COMPONENTS ========
@onready var arrow_spawn: Marker2D = $Aim
@onready var buff_display_container = get_node_or_null("BuffDisplayContainer")

# For debug purposes
@onready var debug_label = get_node_or_null("DebugLabel")

# ======== ARCHER-SPECIFIC PROPERTIES ========
@export var cost_coin: int = 10
@export var cost_food: int = 10
@export var attack_upgrades: Array[BaseProjectileStrategy] = []

# ======== TALENT SYSTEM ========
var unlocked_talents = {0: true}  # Basic talent (0) is already unlocked
var talent_points = 10
var talent_system = null  # Will be initialized in _ready

# Debug properties
var debug_mode = false  # Set to false in production
var debug_monitor_timer: Timer

# ======== INITIALIZATION ========
func _init_soldier():
	# Base stats initialization
	attack_range = 300.0
	move_speed = 25.0
	crit_chance = 0.1
	crit_multi = 2.0
	base_damage = 15
	main_stat = 10  # DEX for archers
	main_stat_type = "dexterity"
	
	# Store original values for reset
	set_meta("original_attack_range", attack_range)
	set_meta("original_attack_cooldown", attack_cooldown)
	
	# Iniciamos o talent_system como null
	talent_system = null
	
	# Agendamos a inicialização para o próximo frame
	call_deferred("_initialize_talent_system")
	
	# NÃO tente conectar sinais aqui ainda!
	# Isso será feito em _initialize_talent_system()

# Function to initialize talent system safely
func _initialize_talent_system():
	# Criar o sistema de talentos com referência adequada
	talent_system = ArcherTalentSystem.new(self)
	talent_system.name = "ArcherTalentSystem"
	add_child(talent_system)
	
	# Conectar o sinal DEPOIS de criar o sistema
	# Verifica se o sinal já não está conectado
	if not is_connected("target_change", talent_system._on_target_change):
		connect("target_change", talent_system._on_target_change)
	
	if debug_mode:
		print("Talent system initialized successfully")

func _ready():
	# Call parent _ready first
	super._ready()
	
	# Set up icon
	icon_texture = preload("res://Test/Assets/Icons/SoldierIcons/Bows000.png")
	
	# Start attack timer
	attack_timer.wait_time = attack_cooldown
	attack_timer.start()
	
	# Apply talent effects
	apply_talent_effects()
	
	if debug_mode:
		print("ArcherBase initialization complete")

# ======== ATTACK FUNCTIONS ========
func _on_attack_timeout():
	if current_target and is_instance_valid(current_target) and is_target_in_range(current_target):
		if not is_attacking:  # Avoid duplicate attacks
			is_attacking = true
			update_animation_speed()
			play_shooting_animation()
			
			# Sync arrow spawn with animation
			var animation_duration = get_animation_duration(get_active_blend_animation())
			
			# Check if archer has Double Shot active
			if has_meta("double_shot_active") and get_meta("double_shot_active"):
				spawn_double_shot_after_delay(animation_duration)
			else:
				spawn_arrow_after_delay(animation_duration)
			
			# Adjust timer cooldown to avoid overlap
			attack_timer.wait_time = max(attack_cooldown, animation_duration)
			attack_timer.start()
	else:
		select_closest_target()

func play_shooting_animation():
	if current_target and is_instance_valid(current_target):
		update_animation_blend_position_to_target(current_target.global_position)
	
	# Set shooting animation
	animation_tree.set("parameters/StateMachine/conditions/is_moving", false)
	animation_tree.set("parameters/StateMachine/conditions/idle", false)
	animation_tree.set("parameters/StateMachine/conditions/shooting", true)
	animation_tree.advance(0)  # Force animation tree to update immediately
	
	if debug_mode:
		print("Shooting animation triggered")

# Spawn an arrow after a delay synchronized with the animation
func spawn_arrow_after_delay(delay: float):
	get_tree().create_timer(delay).timeout.connect(func():
		if is_attacking:  # Confirm still in attack cycle
			spawn_arrow()
			reset_attack()
	)

# Method to spawn double shot after delay
func spawn_double_shot_after_delay(delay: float):
	get_tree().create_timer(delay).timeout.connect(func():
		if is_attacking:  # Confirm still in attack cycle
			spawn_double_shot_arrows()
			reset_attack()
	)

# ======== PROJECTILE SPAWN METHODS ========
func spawn_arrow():
	if not current_target or not is_instance_valid(current_target):
		if debug_mode:
			print("No valid target for arrow")
		return
	
	# Instanciar flecha
	var arrow_scene = load("res://Test/Projectiles/Archer/Arrow.tscn")
	var arrow = arrow_scene.instantiate()
	
	# Configuração básica
	arrow.global_position = arrow_spawn.global_position
	arrow.direction = (current_target.global_position - arrow_spawn.global_position).normalized()
	arrow.rotation = arrow.direction.angle()
	arrow.shooter = self
	
	# Calcular dano base
	var base_damage = get_weapon_damage()  # Usa o método que já calcula dano base do arqueiro
	
	# Definir o dano da flecha com o valor já calculado
	arrow.damage = base_damage
	
	# Aplicar melhorias de talentos
	for upgrade in attack_upgrades:
		if upgrade:
			upgrade.apply_upgrade(arrow)

	# Adicionar à cena
	get_parent().add_child(arrow)

func spawn_double_shot_arrows():
	if not current_target or not is_instance_valid(current_target):
		if debug_mode:
			print("No valid target for double shot")
		return
	
	# Get spread angle from metadata or use default
	var angle_spread = get_meta("double_shot_angle", 15.0)
	
	# Calculate directions for both arrows
	var target_dir = (current_target.global_position - arrow_spawn.global_position).normalized()
	var angle_left = target_dir.rotated(deg_to_rad(-angle_spread/2))
	var angle_right = target_dir.rotated(deg_to_rad(angle_spread/2))
	
	# Load arrow scene
	var arrow_scene = load("res://Test/Projectiles/Archer/Arrow.tscn")
	if not arrow_scene:
		if debug_mode:
			print("ERROR: Could not load arrow scene for double shot")
		return
	
	# Spawn left arrow
	var arrow_left = arrow_scene.instantiate()
	
	# Left arrow configuration
	arrow_left.global_position = arrow_spawn.global_position
	arrow_left.direction = angle_left
	arrow_left.rotation = angle_left.angle()
	arrow_left.shooter = self
	arrow_left.set_meta("is_double_shot", true)
	arrow_left.set_meta("is_left_arrow", true)
	
	# Second arrow (right angle)
	var arrow_right = arrow_scene.instantiate()
	
	# Right arrow configuration
	arrow_right.global_position = arrow_spawn.global_position
	arrow_right.direction = angle_right
	arrow_right.rotation = angle_right.angle()
	arrow_right.shooter = self
	arrow_right.set_meta("is_double_shot", true)
	arrow_right.set_meta("is_right_arrow", true)
	
	# Initialize damage calculators
	if arrow_left.has_node("DmgCalculatorComponent"):
		arrow_left.get_node("DmgCalculatorComponent").initialize_from_shooter(self)
	
	if arrow_right.has_node("DmgCalculatorComponent"):
		arrow_right.get_node("DmgCalculatorComponent").initialize_from_shooter(self)
	
	# Calculate critical hits independently
	if "crit_chance" in self:
		if arrow_left.has_method("_calculate_critical_hit"):
			arrow_left.crit_chance = self.crit_chance
			arrow_left.is_crit = arrow_left._calculate_critical_hit()
		
		if arrow_right.has_method("_calculate_critical_hit"):
			arrow_right.crit_chance = self.crit_chance
			arrow_right.is_crit = arrow_right._calculate_critical_hit()
	
	# Apply talent effects
	for upgrade in attack_upgrades:
		if upgrade and not upgrade is DoubleShot:  # Avoid infinite loop
			upgrade.apply_upgrade(arrow_left)
			upgrade.apply_upgrade(arrow_right)
	
	# Use talent_system to apply compiled effects
	if talent_system:
		var effects = talent_system.compile_archer_effects()
		talent_system.apply_effects_to_projectile(arrow_left, effects)
		talent_system.apply_effects_to_projectile(arrow_right, effects)
	
	# Add to scene
	get_parent().add_child(arrow_left)
	get_parent().add_child(arrow_right)
	
	if debug_mode:
		print("Double shot arrows spawned successfully")

# ======== TALENT SYSTEM METHODS ========
func add_attack_upgrade(upgrade: BaseProjectileStrategy):
	if upgrade not in attack_upgrades:
		attack_upgrades.append(upgrade)
		
		# If it's Double Shot upgrade, initialize it specially
		if upgrade is DoubleShot:
			upgrade.initialize_with_archer(self)

func apply_talent_effects():
	# Reset effects to avoid duplication
	reset_talent_effects()
	
	# Go through unlocked talents
	for key in unlocked_talents.keys():
		# Determine talent ID (always as a number)
		var talent_id = int(key)
		
		# Check if it's unlocked
		if unlocked_talents[key]:
			# Find corresponding talent node
			var skill_node = find_talent_node(talent_id)
			
			# If talent has a strategy, apply it
			if skill_node and skill_node.talent_strategy:
				add_attack_upgrade(skill_node.talent_strategy)
	
	# Refresh talents through the system
	if talent_system:
		var effects = talent_system.compile_archer_effects()
		talent_system.apply_effects_to_soldier(self, effects)
	
	# Mark that talents have been updated
	set_meta("talents_updated", true)

func reset_talent_effects():
	# Clear existing upgrades
	attack_upgrades.clear()
	
	# Reset modifiers to default values
	damage_multiplier = 1.0
	range_multiplier = 1.0
	cooldown_multiplier = 1.0
	speed_multiplier = 1.0
	
	# Reset Double Shot and other metadata
	if has_meta("double_shot_active"):
		remove_meta("double_shot_active")
	if has_meta("has_double_shot"):
		remove_meta("has_double_shot")
	if has_meta("double_shot_angle"):
		remove_meta("double_shot_angle")
	if has_meta("double_shot_damage_modifier"):
		remove_meta("double_shot_damage_modifier")

func find_talent_node(talent_id: int) -> Node:
	# Search all skill buttons in the scene
	var skill_buttons = get_tree().get_nodes_in_group("skill_buttons")
	for button in skill_buttons:
		if button.talent_id == talent_id:
			return button
	return null

# Helper function to convert degrees to radians
func deg_to_rad(degrees: float) -> float:
	return degrees * (PI / 180.0)
