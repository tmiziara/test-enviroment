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

func _ready():
	# Initialize talent system
	talent_manager = ArcherTalentManager.new(self)
	add_child(talent_manager)
	
	# Connect target change signal to talent manager
	connect("target_change", talent_manager._on_target_change)

	# Initialize stats
	attack_range = 300.0
	move_speed = 25.0
	crit_chance = 0.1
	crit_multi = 2.0
	icon_texture = preload("res://Test/Assets/Icons/SoldierIcons/Bows000.png")
	
	# Call parent _ready
	super._ready()
	
	# Initialize attack timer
	attack_timer.wait_time = attack_cooldown
	attack_timer.start()
	
	# Apply talent effects
	apply_talent_effects()

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

# Spawn the arrow and apply upgrades
func spawn_arrow():
	if not current_target or not is_instance_valid(current_target):
		return  
	
	var arrow_scene = preload("res://Test/Projectiles/Archer/Arrow.tscn")  
	var arrow = arrow_scene.instantiate() as NewProjectileBase  
	
	# Arrow configuration
	arrow.global_position = arrow_spawn.global_position  
	arrow.direction = (current_target.global_position - arrow_spawn.global_position).normalized()
	arrow.rotation = arrow.direction.angle()
	
	# IMPORTANT: Set the shooter BEFORE adding the arrow to the tree
	arrow.shooter = self
	
	# Initialize DmgCalculator before applying upgrades
	if arrow.dmg_calculator:
		arrow.dmg_calculator.initialize_from_shooter(self)
	
	# Apply upgrades using talent manager
	arrow = talent_manager.apply_talents_to_projectile(arrow)
	
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
	# Clear existing effects
	reset_talent_effects()
	
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
	talent_manager.refresh_talents()

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
