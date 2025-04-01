extends Node
class_name MovementControlComponent

# Movement control component to handle stuns, slows, knockbacks, etc.
# Attach this to entities that need movement control effects

# Signals
signal stun_applied(duration)
signal stun_removed()
signal slow_applied(amount)
signal slow_removed()
signal knockback_applied(direction, force)

# Movement state tracking
var is_stunned: bool = false
var is_slowed: bool = false
var is_knocked_back: bool = false

# Effect values
var slow_amount: float = 0.0
var previous_slow_amount: float = 0.0  # For stacking slows
var knockback_force: float = 0.0
var knockback_direction: Vector2 = Vector2.ZERO

# Timers
var stun_timer: Timer
var slow_timer: Timer
var knockback_timer: Timer

# References
var entity

func _ready():
	entity = get_parent()
	
	# Create timers
	stun_timer = _create_timer("StunTimer")
	slow_timer = _create_timer("SlowTimer")
	knockback_timer = _create_timer("KnockbackTimer")
	
	# Connect timer signals
	stun_timer.timeout.connect(_on_stun_timer_timeout)
	slow_timer.timeout.connect(_on_slow_timer_timeout)
	knockback_timer.timeout.connect(_on_knockback_timer_timeout)

# Apply stun effect
func apply_stun(duration: float = 1.0) -> void:
	if is_stunned:
		# If already stunned, extend duration if new duration is longer
		if stun_timer.time_left < duration:
			stun_timer.stop()
			stun_timer.wait_time = duration
			stun_timer.start()
		return
	
	is_stunned = true
	
	# Apply stun effect to entity
	_modify_entity_for_stun(true)
	
	# Start stun timer
	stun_timer.wait_time = duration
	stun_timer.start()
	
	# Emit signal
	emit_signal("stun_applied", duration)

# Remove stun effect
func remove_stun() -> void:
	if not is_stunned:
		return
	
	is_stunned = false
	
	# Remove stun effect from entity
	_modify_entity_for_stun(false)
	
	# Stop timer
	stun_timer.stop()
	
	# Emit signal
	emit_signal("stun_removed")

# Apply slow effect
func apply_slow(amount: float = 0.3, duration: float = 2.0) -> void:
	# Apply only the strongest slow if already slowed
	if is_slowed:
		if amount > slow_amount:
			previous_slow_amount = slow_amount
			slow_amount = amount
			_modify_entity_for_slow(true)
		
		# Extend duration if new duration is longer
		if slow_timer.time_left < duration:
			slow_timer.stop()
			slow_timer.wait_time = duration
			slow_timer.start()
		return
	
	is_slowed = true
	slow_amount = amount
	
	# Apply slow effect to entity
	_modify_entity_for_slow(true)
	
	# Start slow timer
	slow_timer.wait_time = duration
	slow_timer.start()
	
	# Emit signal
	emit_signal("slow_applied", amount)

# Remove slow effect
func remove_slow() -> void:
	if not is_slowed:
		return
	
	is_slowed = false
	
	# Remove slow effect from entity
	_modify_entity_for_slow(false)
	
	# Reset slow amount
	slow_amount = 0.0
	previous_slow_amount = 0.0
	
	# Stop timer
	slow_timer.stop()
	
	# Emit signal
	emit_signal("slow_removed")

# Apply knockback effect
func apply_knockback(direction: Vector2, force: float = 150.0) -> void:
	is_knocked_back = true
	knockback_direction = direction.normalized()
	knockback_force = force
	
	# Apply knockback to entity
	_modify_entity_for_knockback(true)
	
	# Start knockback timer with short duration
	knockback_timer.wait_time = 0.3
	knockback_timer.start()
	
	# Emit signal
	emit_signal("knockback_applied", direction, force)

# Process movement control - called from _physics_process in derived classes
func process_movement_control(delta: float) -> void:
	# Handle knockback movement
	if is_knocked_back and entity is CharacterBody2D:
		# Gradually reduce knockback force for smoother effect
		knockback_force = max(0, knockback_force - (knockback_force * 5 * delta))
		
		# Apply knockback velocity
		entity.velocity = knockback_direction * knockback_force
		
		# If force is nearly zero, remove knockback
		if knockback_force < 5.0:
			remove_knockback()

# Modify entity for stun
func _modify_entity_for_stun(apply: bool) -> void:
	# Store original state for restoration
	if apply:
		entity.set_meta("pre_stun_process", entity.get_physics_process())
		
		# Get original velocity if it's a CharacterBody2D
		if entity is CharacterBody2D:
			entity.set_meta("pre_stun_velocity", entity.velocity)
		
		# Disable physics process and attack
		entity.set_physics_process(false)
		
		# If it's a CharacterBody2D, zero out velocity
		if entity is CharacterBody2D:
			entity.velocity = Vector2.ZERO
	else:
		# Restore physics process
		if entity.has_meta("pre_stun_process"):
			entity.set_physics_process(entity.get_meta("pre_stun_process"))
			entity.remove_meta("pre_stun_process")
		
		# Restore velocity if it's a CharacterBody2D
		if entity is CharacterBody2D and entity.has_meta("pre_stun_velocity"):
			entity.velocity = entity.get_meta("pre_stun_velocity")
			entity.remove_meta("pre_stun_velocity")

# Modify entity for slow
func _modify_entity_for_slow(apply: bool) -> void:
	# Only apply if entity has movement properties
	if "base_speed" in entity and "move_speed" in entity:
		if apply:
			# Store original speed for restoration if not already stored
			if not entity.has_meta("original_speed"):
				entity.set_meta("original_speed", entity.move_speed)
			
			# Apply slow
			entity.move_speed = entity.base_speed * (1.0 - slow_amount)
		else:
			# Restore original speed
			if entity.has_meta("original_speed"):
				entity.move_speed = entity.get_meta("original_speed")
				entity.remove_meta("original_speed")

# Modify entity for knockback
func _modify_entity_for_knockback(apply: bool) -> void:
	if entity is CharacterBody2D:
		if apply:
			# Store original velocity for restoration
			entity.set_meta("pre_knockback_velocity", entity.velocity)
			
			# Apply knockback velocity
			entity.velocity = knockback_direction * knockback_force
		else:
			# Restore original velocity
			if entity.has_meta("pre_knockback_velocity"):
				entity.velocity = entity.get_meta("pre_knockback_velocity")
				entity.remove_meta("pre_knockback_velocity")

# Remove knockback effect
func remove_knockback() -> void:
	if not is_knocked_back:
		return
	
	is_knocked_back = false
	knockback_force = 0.0
	
	# Remove knockback effect from entity
	_modify_entity_for_knockback(false)
	
	# Stop timer
	knockback_timer.stop()

# Timer callbacks
func _on_stun_timer_timeout() -> void:
	remove_stun()

func _on_slow_timer_timeout() -> void:
	remove_slow()

func _on_knockback_timer_timeout() -> void:
	remove_knockback()

# Helper to create a timer
func _create_timer(name: String) -> Timer:
	var timer = Timer.new()
	timer.name = name
	timer.one_shot = true
	timer.autostart = false
	add_child(timer)
	return timer
