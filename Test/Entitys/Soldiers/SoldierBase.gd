class_name SoldierBase
extends CharacterBody2D

# ======== EXPORTED PROPERTIES ========
@export_category("Basic Stats")
@export var icon_texture: Texture2D
@export var attack_range: float = 300.0
@export var move_speed: float = 100.0
@export var attack_cooldown: float = 1.0
@export var max_health: int = 100
@export var base_damage: int = 10

@export_category("Advanced Stats")
@export var main_stat: int = 10  # Atributo principal (DEX para arqueiros, STR para guerreiros, INT para magos)
@export var main_stat_type: String = "dexterity"  # "dexterity", "strength" ou "intelligence"
@export var armor: int = 0
@export var damage_reduction: float = 0.0
@export var crit_chance: float = 0.1
@export var crit_multi: float = 2.0
@export var armor_penetration: float = 0.0

@export_category("Elemental Stats")
@export var fire_damage_modifier: float = 0.0
@export var ice_damage_modifier: float = 0.0
@export var poison_damage_modifier: float = 0.0

@export_category("Movement")
@export var movement_radius: float = 50.0
@export var idle_time: float = 5.0

@export_category("Identity")
@export var soldier_name: String = ""
@export var soldier_preview: PackedScene
@export var type: String = ""
@export var classType: String = ""

# ======== MODIFIERS ========
var damage_multiplier: float = 1.0
var range_multiplier: float = 1.0
var cooldown_multiplier: float = 1.0
var speed_multiplier: float = 1.0

# ======== INTERNAL STATES ========
var is_idle: bool = false
var is_attacking: bool = false
var current_target = null
var team: String = "ally"  # For friendly fire detection
var mobs_in_range: Array = []
var target_position: Vector2
var unique_id: String = ""

# ======== EQUIPMENT ========
var equipment_slots: Dictionary = {
	"Weapons": null,  # Arma
	"Armor": null,   # Armadura
	"Ring": null,    # Anel
	"Amulet": null   # Amuleto
}

# ======== COMPONENTS ========
@onready var animation_tree: AnimationTree = $AnimationTree
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var health_component: HealthComponent = $HealthComponent
@onready var hitbox_component: HitboxComponent = get_node_or_null("HitboxComponent")
@onready var hurtbox_component: HurtboxComponent = get_node_or_null("HurtboxComponent")

# ======== TIMERS ========
var idle_timer: Timer
var attack_timer: Timer

# ======== SIGNALS ========
signal target_change(target)
signal attack_started
signal attack_finished
signal animation_blend_changed(blend_position)

# ======== INITIALIZATION ========
func _ready():
	# Initialize timers
	_initialize_timers()
	
	# Set up components
	_initialize_components()
	
	# Activate animation tree
	animation_tree.active = true
	
	# Initial position
	target_position = get_random_point_within_radius()
	
	# Reset animations to idle state
	reset_animation_state()
	
	# Connect signals for target detection
	_connect_detection_signals()
	
	# Call virtual method for child classes
	_init_soldier()

# Virtual method for child class initialization
func _init_soldier() -> void:
	pass

func _initialize_timers():
	# Create idle timer
	idle_timer = Timer.new()
	idle_timer.name = "IdleTimer"
	idle_timer.one_shot = true
	idle_timer.wait_time = idle_time
	idle_timer.timeout.connect(_on_idle_timeout)
	add_child(idle_timer)
	
	# Create attack timer
	attack_timer = Timer.new()
	attack_timer.name = "AttackTimer"
	attack_timer.one_shot = false
	attack_timer.wait_time = attack_cooldown
	attack_timer.timeout.connect(_on_attack_timeout)
	add_child(attack_timer)

func _initialize_components():
	# Set up health component
	if health_component:
		health_component.max_health = max_health
		health_component.current_health = max_health
		health_component.died.connect(_on_death)
	
	# Set up hurtbox component
	if hurtbox_component:
		hurtbox_component.owner_entity = self
		hurtbox_component.hit_received.connect(_on_hit_received)

func _connect_detection_signals():
	# Find detection area for enemies
	var detection_area = get_node_or_null("DetectionArea")
	if detection_area:
		if not detection_area.body_entered.is_connected(_on_body_entered):
			detection_area.body_entered.connect(_on_body_entered)
		if not detection_area.body_exited.is_connected(_on_body_exited):
			detection_area.body_exited.connect(_on_body_exited)

# ======== MOVEMENT AND PHYSICS ========
func _physics_process(delta):
	if is_attacking or is_idle:
		return
	
	if current_target and is_instance_valid(current_target):
		update_animation_blend_position_to_target(current_target.global_position)
		return
	
	# Check if we've reached our target position
	if global_position.distance_to(target_position) <= 10:
		enter_idle_state()
	else:
		move_to_target(delta)

func move_to_target(_delta):
	if is_idle or is_attacking:
		return
	
	# Calculate direction to destination
	var direction = (target_position - global_position).normalized()
	velocity = direction * move_speed * speed_multiplier
	
	# Move and check for collisions
	move_and_slide()
	
	# Update animation state
	animation_tree.set("parameters/StateMachine/conditions/is_moving", true)
	animation_tree.set("parameters/StateMachine/conditions/idle", false)
	animation_tree.set("parameters/StateMachine/conditions/shooting", false)
	
	# Update animation blend position
	update_animation_blend_position(direction)

func enter_idle_state():
	if is_idle:
		return
	
	velocity = Vector2.ZERO
	is_idle = true
	idle_timer.start()
	reset_animation_state()

func _on_idle_timeout():
	if is_idle:
		is_idle = false
		target_position = get_random_point_within_radius()

func get_random_point_within_radius() -> Vector2:
	var angle = randf() * PI * 2
	var distance = randf() * movement_radius
	return global_position + Vector2(cos(angle), sin(angle)) * distance

# ======== TARGET MANAGEMENT ========
func _on_body_entered(body):
	if body.is_in_group("enemies"):
		mobs_in_range.append(body)
		if current_target == null:
			select_closest_target()

func _on_body_exited(body):
	if body in mobs_in_range:
		mobs_in_range.erase(body)
		if current_target == body:
			select_closest_target()

func select_closest_target():
	# Store previous target for comparison
	var previous_target = current_target
	
	# Filter valid targets
	mobs_in_range = mobs_in_range.filter(func(mob): return is_instance_valid(mob))
	
	if mobs_in_range.is_empty():
		current_target = null
		attack_timer.stop()
		reset_animation_state()
		reset_attack()
		target_position = get_random_point_within_radius()
		
		# Emit signal if target changed
		if previous_target != null:
			emit_signal("target_change", null)
		
		return null
	
	# Find closest target within range
	var closest_target = null
	var closest_distance = INF
	
	for mob in mobs_in_range:
		var distance = global_position.distance_to(mob.global_position)
		if distance < closest_distance and is_target_in_range(mob):
			closest_distance = distance
			closest_target = mob
	
	current_target = closest_target
	
	# Emit signal if target changed
	if current_target != previous_target:
		emit_signal("target_change", current_target)
	
	# Start attack timer if we have a target
	if current_target and not is_attacking:
		attack_timer.start()
	
	return current_target

func is_target_in_range(target) -> bool:
	if not is_instance_valid(target):
		return false
	
	var distance = global_position.distance_to(target.global_position)
	return distance <= attack_range * range_multiplier

func get_current_target():
	if current_target and is_instance_valid(current_target):
		return current_target
	return null

# ======== ATTACK LOGIC ========
func _on_attack_timeout():
	if current_target and is_instance_valid(current_target) and is_target_in_range(current_target):
		if not is_attacking:
			is_attacking = true
			emit_signal("attack_started")
			
			# Update animation speed
			update_animation_speed()
			
			# Update animation blend position
			if current_target:
				update_animation_blend_position_to_target(current_target.global_position)
			
			# Explicitly set animation states
			animation_tree.set("parameters/StateMachine/conditions/is_moving", false)
			animation_tree.set("parameters/StateMachine/conditions/idle", false)
			animation_tree.set("parameters/StateMachine/conditions/shooting", true)
			
			# Force animation update
			animation_tree.advance(0)
			
			# Get animation duration for timing
			var animation_name = get_active_blend_animation()
			var animation_duration = get_animation_duration(animation_name)
			
			# Child classes should override to implement actual attack
			_perform_attack(animation_duration)
			
			# Adjust timer for next attack
			attack_timer.wait_time = max(attack_cooldown * cooldown_multiplier, animation_duration + 0.1)
			attack_timer.start()
	else:
		select_closest_target()

# Virtual method for child classes to implement
func _perform_attack(animation_duration: float) -> void:
	# Base implementation simply resets after animation
	get_tree().create_timer(animation_duration).timeout.connect(func():
		if is_instance_valid(self):
			reset_attack()
	)

func reset_attack():
	is_attacking = false
	animation_tree.set("parameters/TimeScale/scale", 1)
	emit_signal("attack_finished")
	
	# Reset cooldown modifiers if needed
	reset_attack_cooldown()

func reset_attack_cooldown() -> void:
	# Check if we stored an original cooldown
	if has_meta("original_cooldown"):
		var original_cooldown = get_meta("original_cooldown")
		attack_cooldown = original_cooldown
		remove_meta("original_cooldown")
		
		# Update timer
		attack_timer.wait_time = attack_cooldown * cooldown_multiplier
		update_animation_speed()

# ======== ANIMATION FUNCTIONS ========
func update_animation_blend_position(direction: Vector2):
	# Only update if direction magnitude is significant
	if direction.length() > 0.1:
		# Calculate blend position based on dominant axis
		var blend_position: Vector2
		if abs(direction.x) > abs(direction.y):
			blend_position = Vector2(sign(direction.x), 0)
		else:
			blend_position = Vector2(0, sign(direction.y))
		
		# Apply to all blend trees
		animation_tree.set("parameters/StateMachine/move/blend_position", blend_position)
		animation_tree.set("parameters/StateMachine/idle/blend_position", blend_position)
		animation_tree.set("parameters/StateMachine/shoot/blend_position", blend_position)
		
		# Emit signal for external systems
		emit_signal("animation_blend_changed", blend_position)

func update_animation_blend_position_to_target(target_position: Vector2):
	var direction = (target_position - global_position).normalized()
	var blend_position: Vector2
	
	# Calculate blend position based on dominant axis
	if abs(direction.x) > abs(direction.y):
		blend_position = Vector2(sign(direction.x), 0)
	else:
		blend_position = Vector2(0, sign(direction.y))
	
	# Apply to all blend trees
	animation_tree.set("parameters/StateMachine/move/blend_position", blend_position)
	animation_tree.set("parameters/StateMachine/idle/blend_position", blend_position)
	animation_tree.set("parameters/StateMachine/shoot/blend_position", blend_position)
	
	# Emit signal for external systems
	emit_signal("animation_blend_changed", blend_position)

func update_animation_speed():
	if is_attacking:
		var attack_speed_multiplier = 1.0 / (attack_cooldown * cooldown_multiplier)
		attack_speed_multiplier = clamp(attack_speed_multiplier, 0.5, 2.0)  # Limit range for safety
		animation_tree.set("parameters/TimeScale/scale", attack_speed_multiplier)
		return attack_speed_multiplier
	return 1.0

func get_animation_duration(animation_name: String) -> float:
	if not animation_player:
		return attack_cooldown  # Default to cooldown if no player
	
	var attack_speed_multiplier = update_animation_speed()
	
	# Check if animation exists
	if animation_player.has_animation(animation_name):
		# Get base duration
		var base_duration = animation_player.get_animation(animation_name).length
		if base_duration == 0:
			return attack_cooldown  # Fallback to cooldown
		
		# Apply speed multiplier
		if attack_speed_multiplier > 0:
			var adjusted_duration = base_duration / attack_speed_multiplier
			return adjusted_duration
	else:
		# Try to find animation in state machine
		for anim in ["shoot_up", "shoot_down", "shoot_left", "shoot_right"]:
			if animation_player.has_animation(anim):
				var base_duration = animation_player.get_animation(anim).length
				if base_duration > 0 and attack_speed_multiplier > 0:
					return base_duration / attack_speed_multiplier
	
	return attack_cooldown  # Fallback if no animations found

func reset_animation_state():
	is_attacking = false
	
	# Explicitly set all animation states
	animation_tree.set("parameters/StateMachine/conditions/is_moving", false)
	animation_tree.set("parameters/StateMachine/conditions/idle", true)
	animation_tree.set("parameters/StateMachine/conditions/shooting", false)
	
	# Reset animation speed
	animation_tree.set("parameters/TimeScale/scale", 1)

func get_active_blend_animation() -> String:
	var blend_position = animation_tree.get("parameters/StateMachine/shoot/blend_position")
	var animations = {
		Vector2(0, -1): "shoot_up",
		Vector2(0, 1): "shoot_down",
		Vector2(-1, 0): "shoot_left",
		Vector2(1, 0): "shoot_right"
	}
	
	# Check for exact match
	for pos in animations.keys():
		if blend_position == pos:
			return animations[pos]
	
	# If no exact match, find closest
	var closest_key = Vector2(0, 1)  # Default to down
	var closest_distance = INF
	
	for pos in animations.keys():
		var distance = blend_position.distance_to(pos)
		if distance < closest_distance:
			closest_distance = distance
			closest_key = pos
	
	return animations[closest_key]

# ======== DAMAGE AND HEALTH ========
func _on_hit_received(hitbox, hit_data):
	# Base implementation does minimal processing
	print("Soldier hit by ", hitbox.owner_entity.name if hitbox.owner_entity else "unknown")

func _on_death():
	# Disable physics and interactions
	set_physics_process(false)
	
	if hurtbox_component:
		hurtbox_component.set_active(false)
	
	# Play death animation if available
	if animation_tree and animation_tree.has_parameter("parameters/StateMachine/conditions/dead"):
		animation_tree.set("parameters/StateMachine/conditions/is_moving", false)
		animation_tree.set("parameters/StateMachine/conditions/idle", false)
		animation_tree.set("parameters/StateMachine/conditions/shooting", false)
		animation_tree.set("parameters/StateMachine/conditions/dead", true)
		
		# Queue free after animation completes
		get_tree().create_timer(1.0).timeout.connect(func(): queue_free())
	else:
		# No death animation, just queue free
		queue_free()

# ======== STAT METHODS ========
func get_main_stat() -> int:
	return main_stat

func get_weapon_damage() -> int:
	# Check for equipped weapon
	if "Weapons" in equipment_slots and equipment_slots["Weapons"] != null:
		return equipment_slots["Weapons"].damage
	
	# Calculate base damage with main stat bonus
	var base = base_damage + int(main_stat * 0.5)
	return int(base * damage_multiplier)

# Apply or remove item modifiers
func apply_item_modifiers(item: Resource, apply: bool):
	var modifier = 1 if apply else -1
	
	for stat in item.stat_modifiers.keys():
		if stat in self:
			self[stat] += item.stat_modifiers[stat] * modifier
