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
	call_deferred("_initialize_arrow_pool")

func _initialize_arrow_pool() -> void:
	print("Initializing arrow pool for archer")
	print("ProjectilePool exists: ", ProjectilePool != null)
	print("ProjectilePool instance exists: ", ProjectilePool.instance != null)
	
	# Verifica se o sistema de pool está disponível
	if ProjectilePool and ProjectilePool.instance:
		# Carrega a cena da flecha
		var arrow_scene = preload("res://Test/Projectiles/Archer/Arrow.tscn")
		if arrow_scene:
			# Cria o nome do pool baseado no ID do arqueiro
			var pool_name = "arrow_" + str(get_instance_id())
			print("Pool name: ", pool_name)
			
			# Cria o pool com uma quantidade inicial de flechas
			ProjectilePool.instance.create_pool(pool_name, arrow_scene, get_parent(), 20)
			print("Pool created successfully")

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

func spawn_arrow():
	if not current_target or not is_instance_valid(current_target):
		return
	
	# Check if pool system is available
	if ProjectilePool and ProjectilePool.instance:
		# Get arrow from pool
		var arrow = ProjectilePool.instance.get_arrow_for_archer(self)
		
		if arrow:
			# NOVO: Garante que a flecha não tem parent antes de adicionar à cena
			if arrow.get_parent():
				arrow.get_parent().remove_child(arrow)
			
			# Reset arrow
			if arrow.has_method("reset_for_reuse"):
				arrow.reset_for_reuse()
			
			# Set basic properties
			arrow.global_position = arrow_spawn.global_position
			arrow.direction = (current_target.global_position - arrow_spawn.global_position).normalized()
			arrow.rotation = arrow.direction.angle()
			
			# IMPORTANT: Set shooter BEFORE applying talents
			arrow.shooter = self
			
			# CRÍTICO: Certifique-se de que o DmgCalculator é inicializado corretamente
			if arrow.has_node("DmgCalculatorComponent"):
				var dmg_calc = arrow.get_node("DmgCalculatorComponent")
				dmg_calc.initialize_from_shooter(self)
				print("Inicializando main_stat do atirador: " + str(dmg_calc.main_stat))
			
			# NOW calculate critical hit based on archer stats
			if "crit_chance" in self and arrow.has_method("is_critical_hit"):
				arrow.crit_chance = self.crit_chance
				arrow.is_crit = arrow.is_critical_hit(arrow.crit_chance)
			
			# Apply talents using talent manager
			if talent_manager:
				arrow = talent_manager.apply_talents_to_projectile(arrow)
			else:
				# Fallback only if talent_manager is null
				for upgrade in attack_upgrades:
					if upgrade:
						upgrade.apply_upgrade(arrow)
			
			# Ensure arrow is visible and active
			arrow.visible = true
			arrow.set_physics_process(true)
			
			# IMPORTANTE: Adiciona à cena apenas depois de toda configuração
			get_parent().add_child(arrow)
			
			return
	
	# Fall back to original method if pool system unavailable or failed
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
		print("Critical hit calculation: ", arrow.is_crit, " (chance: ", arrow.crit_chance, ")")
	
	# Initialize DmgCalculator before applying upgrades
	if arrow.dmg_calculator:
		arrow.dmg_calculator.initialize_from_shooter(self)
	
	# Apply upgrades consistently using talent manager
	if talent_manager:
		print("Aplicando talentos via talent_manager no método fallback")
		arrow = talent_manager.apply_talents_to_projectile(arrow)
	else:
		print("ERROR: No talent manager available!")
	
	# Add the arrow to the scene
	get_parent().add_child(arrow)
	
	# Track bloodseeker stacks if enabled
	if current_target and has_meta("bloodseeker_data"):
		talent_manager.apply_bloodseeker_hit(current_target)

# Add attack upgrade
func add_attack_upgrade(upgrade: BaseProjectileStrategy):
	if upgrade not in attack_upgrades:
		attack_upgrades.append(upgrade)

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
	
# Cleanup pools when archer is removed
func _exit_tree():
	if ProjectilePool and ProjectilePool.instance:
		# Clean up any pools specific to this archer
		var pool_name = "arrow_" + str(get_instance_id())
		
		# Return all projectiles to pool first
		if ProjectilePool.instance.pools.has(pool_name):
			ProjectilePool.instance.return_all_projectiles(pool_name)
