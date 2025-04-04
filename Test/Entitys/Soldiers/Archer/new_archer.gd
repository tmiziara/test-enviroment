extends Soldier_Base
class_name ArcherBase

@onready var arrow_spawn: Marker2D = $Aim
@onready var buff_display_container: BuffDisplayContainer = $BuffDisplayContainer

# Base stats
@export var cost_coin: int = 10
@export var cost_food: int = 10
@export var attack_upgrades: Array[BaseProjectileStrategy] = []

# Talent data
var unlocked_talents = {0: true}  # Basic talent (0) is already unlocked
var talent_points = 10

# Talent management
var talent_manager: ArcherTalentManager

func _init():
	# Base stats
	attack_range = 300.0
	move_speed = 25.0
	crit_chance = 0.1  # Set to 10%
	crit_multi = 2.0
	
func _ready():
	# Initialize talent system
	talent_manager = ArcherTalentManager.new(self)
	add_child(talent_manager)
	
	# Connect target change signal to talent manager
	connect("target_change", talent_manager._on_target_change)

	icon_texture = preload("res://Test/Assets/Icons/SoldierIcons/Bows000.png")
	
	# Call parent _ready
	super._ready()
	
	# Initialize attack timer
	attack_timer.wait_time = attack_cooldown
	attack_timer.start()
	
	# Apply talent effects
	apply_talent_effects()
	
	# Inicializa o pool de flechas para este arqueiro depois que o nó estiver pronto
	call_deferred("_initialize_arrow_pools")

func _initialize_arrow_pools() -> void:
	# Verifica se o sistema de pool está disponível
	if ProjectilePool and ProjectilePool.instance:
		# Carrega a cena da flecha
		var arrow_scene = preload("res://Test/Projectiles/Archer/Arrow.tscn")
		if arrow_scene:
			# Cria o nome do pool baseado no ID do arqueiro
			var pool_name = "arrow_" + str(get_instance_id())
			# Cria o pool com uma quantidade inicial de flechas
			ProjectilePool.instance.create_pool(pool_name, arrow_scene, get_parent(), 20)

func _physics_process(delta):
	super._physics_process(delta)

# Override attack logic
func _on_attack_timeout():
	if current_target and is_instance_valid(current_target) and is_target_in_range(current_target):
		if not is_attacking:  # Prevent duplicate shots
			is_attacking = true
			update_animation_speed()
			play_shooting_animation()
			
			# Synchronize arrow spawn with animation
			var animation_duration = get_animation_duration(get_active_blend_animation())
			
			# Verifica se o arqueiro tem Double Shot ativo
			if has_meta("double_shot_active") and get_meta("double_shot_active"):
				spawn_double_shot_after_delay(animation_duration)
			else:
				spawn_arrow_after_delay(animation_duration)
			
			# Adjust timer cooldown to prevent overlap
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

# Spawn an arrow after a delay synchronized with the animation
func spawn_arrow_after_delay(delay: float):
	get_tree().create_timer(delay).timeout.connect(func():
		if is_attacking:  # Confirm still in attack cycle
			spawn_arrow()
			reset_attack())

# Novo método para spawnar duas flechas simultaneamente
func spawn_double_shot_after_delay(delay: float):
	get_tree().create_timer(delay).timeout.connect(func():
		if is_attacking:  # Confirm still in attack cycle
			spawn_double_shot_arrows()
			reset_attack())

# Método para spawnar flecha regular
func spawn_arrow():
	if not current_target or not is_instance_valid(current_target):
		return
	
	# Fall back to original method
	var arrow_scene = preload("res://Test/Projectiles/Archer/Arrow.tscn")  
	var arrow = arrow_scene.instantiate() as NewProjectileBase
	
	# Arrow configuration
	arrow.global_position = arrow_spawn.global_position  
	arrow.direction = (current_target.global_position - arrow_spawn.global_position).normalized()
	arrow.rotation = arrow.direction.angle()
	
	# IMPORTANT: Set the shooter BEFORE adding the arrow to the tree
	arrow.shooter = self
	
	# CRITICAL FIX: Calculate critical hit after shooter is set
	if "crit_chance" in self and arrow.has_method("is_critical_hit"):
		arrow.crit_chance = self.crit_chance
		arrow.is_crit = arrow.is_critical_hit(arrow.crit_chance)
	
	# Initialize DmgCalculator before applying upgrades
	if arrow.dmg_calculator:
		arrow.dmg_calculator.initialize_from_shooter(self)
	
	# Apply upgrades
	for upgrade in attack_upgrades:
		if upgrade:
			upgrade.apply_upgrade(arrow)
	
	# Add the arrow to the scene
	get_parent().add_child(arrow)

# Novo método para spawnar duas flechas simultaneamente (Double Shot)
func spawn_double_shot_arrows():
	if not current_target or not is_instance_valid(current_target):
		return
	
	# Get angle spread from metadata or use default
	var angle_spread = get_meta("double_shot_angle", 15.0)
	
	# Calculando os ângulos para as duas flechas
	var target_dir = (current_target.global_position - arrow_spawn.global_position).normalized()
	var angle_left = target_dir.rotated(deg_to_rad(-angle_spread/2))
	var angle_right = target_dir.rotated(deg_to_rad(angle_spread/2))
	
	# Spawn first arrow (left angle)
	var arrow_scene = preload("res://Test/Projectiles/Archer/Arrow.tscn")
	var arrow_left = arrow_scene.instantiate()
	
	# Configure left arrow
	arrow_left.global_position = arrow_spawn.global_position
	arrow_left.direction = angle_left
	arrow_left.rotation = angle_left.angle()
	arrow_left.shooter = self
	arrow_left.set_meta("is_double_shot", true)
	arrow_left.set_meta("is_left_arrow", true)
	
	# Spawn second arrow (right angle)
	var arrow_right = arrow_scene.instantiate()
	
	# Configure right arrow
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
		if arrow_left.has_method("is_critical_hit"):
			arrow_left.crit_chance = self.crit_chance
			arrow_left.is_crit = arrow_left.is_critical_hit(arrow_left.crit_chance)
		
		if arrow_right.has_method("is_critical_hit"):
			arrow_right.crit_chance = self.crit_chance
			arrow_right.is_crit = arrow_right.is_critical_hit(arrow_right.crit_chance)
	
	# Apply talent effects
	for upgrade in attack_upgrades:
		if upgrade and upgrade is DoubleShot:
			# Skip the Double Shot upgrade to prevent recursion
			continue
			
		if upgrade:
			upgrade.apply_upgrade(arrow_left)
			upgrade.apply_upgrade(arrow_right)
	
	# Add to scene
	get_parent().add_child(arrow_left)
	get_parent().add_child(arrow_right)

# Add attack upgrade
func add_attack_upgrade(upgrade: BaseProjectileStrategy):
	if upgrade not in attack_upgrades:
		attack_upgrades.append(upgrade)
		
		# Se for o upgrade de Double Shot, inicializa-o especialmente
		if upgrade is DoubleShot:
			upgrade.initialize_with_archer(self)

# Apply all talent effects
func apply_talent_effects():
	var talent_manager = get_node_or_null("ArcherTalentManager")
	if talent_manager:
		talent_manager.refresh_talents()
	
	# Find and apply all unlocked talents
	for key in unlocked_talents.keys():
		# Determine the talent ID (always as a number)
		var talent_id = int(key)
		
		# Check if it's unlocked
		if unlocked_talents[key]:
			# Find the corresponding talent node
			var skill_node = find_talent_node(talent_id)
			
			# If the talent has a strategy, apply it
			if skill_node and skill_node.talent_strategy:
				add_attack_upgrade(skill_node.talent_strategy)
			else:
				print("Talent", talent_id, "doesn't have a strategy or node not found")
	
	# Refresh talent system after changes
	if talent_manager:
		talent_manager.refresh_talents()
	
	# Mark that talents have been updated - important for pool system
	set_meta("talents_updated", true)

func reset_talent_effects():
	# Clear existing upgrades
	attack_upgrades.clear()
	
	# Reset attack range to base value before applying talent effects
	# This prevents multiple applications of range modifiers
	var original_range = 300.0  # Default base range
	if has_meta("original_attack_range"):
		original_range = get_meta("original_attack_range")
	else:
		set_meta("original_attack_range", original_range)
	
	attack_range = original_range
	
	# Reset Double Shot status
	if has_meta("double_shot_active"):
		remove_meta("double_shot_active")
	if has_meta("has_double_shot"):
		remove_meta("has_double_shot")
	if has_meta("double_shot_angle"):
		remove_meta("double_shot_angle")
	if has_meta("double_shot_damage_modifier"):
		remove_meta("double_shot_damage_modifier")

func find_talent_node(talent_id: int) -> SkillNode:
	# Look for all talent buttons in the scene
	var skill_buttons = get_tree().get_nodes_in_group("skill_buttons")
	for button in skill_buttons:
		if button.talent_id == talent_id:
			return button
	return null

# Override to provide better target access to talent systems
func get_current_target() -> Node2D:
	if current_target and is_instance_valid(current_target):
		return current_target
	return null

# Return main stat for damage calculations
func get_main_stat() -> int:
	return main_stat

# Return weapon damage for damage calculations  
func get_weapon_damage() -> int:
	# Check for equipped weapon
	if "Weapons" in equipment_slots and equipment_slots["Weapons"] != null:
		return equipment_slots["Weapons"].damage
	return 10  # Default damage if no weapon equipped

# Helper function to convert degrees to radians
func deg_to_rad(degrees: float) -> float:
	return degrees * (PI / 180.0)
