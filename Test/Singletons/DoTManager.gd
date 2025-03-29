extends Node
class_name DoTManager

# Singleton instance for global access
static var instance: DoTManager

# Dictionary to track all active DoTs in the game
# Format: { entity_instance_id: { dot_id: DotEffect } }
var active_dots: Dictionary = {}

# Signal for when DoT is applied or removed
signal dot_applied(entity, dot_type, dot_id)
signal dot_removed(entity, dot_type, dot_id)
signal dot_tick(entity, dot_type, damage, dot_id)

# DoT effect data class
class DotEffect:
	var entity: Node          # Entity receiving the DoT
	var type: String          # Type of DoT (fire, poison, bleeding, etc.)
	var damage: int           # Damage per tick
	var duration: float       # Total duration in seconds
	var interval: float       # Time between ticks
	var remaining_time: float # Time left on effect
	var tick_timer: Timer     # Timer for damage ticks
	var duration_timer: Timer # Timer for total duration
	var dot_id: String        # Unique ID for this specific DoT
	var source: Node          # Original source of the DoT (projectile, trap, etc.)
	var source_multipliers: Dictionary = {} # Damage multipliers from source

	func _init(p_entity: Node, p_type: String, p_damage: int, p_duration: float, 
			   p_interval: float, p_source: Node = null):
		entity = p_entity
		type = p_type
		damage = p_damage
		duration = p_duration
		interval = p_interval
		remaining_time = p_duration
		source = p_source
		# Generate unique ID
		dot_id = str(type) + "_" + str(Time.get_ticks_msec()) + "_" + str(randi() % 1000)

func _init():
	# Set singleton instance
	instance = self
	
func _ready():
	# Create a timer to periodically clean up inactive DoTs
	var cleanup_timer = Timer.new()
	cleanup_timer.wait_time = 5.0  # Check every 5 seconds
	cleanup_timer.one_shot = false
	cleanup_timer.autostart = true
	add_child(cleanup_timer)
	cleanup_timer.timeout.connect(_cleanup_expired_dots)

# Apply a DoT effect to an entity
func apply_dot(entity: Node, damage: int, duration: float, interval: float, 
			   dot_type: String = "generic", source: Node = null, 
			   should_stack: bool = false, max_stacks: int = 1) -> String:
	# Ensure entity has a HealthComponent and DefenseComponent
	var health_component = entity.get_node_or_null("HealthComponent")
	var defense_component = entity.get_node_or_null("DefenseComponent")
	
	if not health_component:
		print("DoTManager: Entity has no HealthComponent, can't apply DoT")
		return ""
	
	# Process resistance via DefenseComponent
	var final_damage = damage
	if defense_component and defense_component.has_method("reduce_dot_damage"):
		final_damage = defense_component.reduce_dot_damage(damage, dot_type)
		print("DoTManager: Damage reduced by defense from ", damage, " to ", final_damage)
	
	# If damage is reduced to zero or less, don't apply the DoT
	if final_damage <= 0:
		print("DoTManager: DoT damage reduced to zero, not applying")
		return ""
	
	# Get entity ID for tracking
	var entity_id = entity.get_instance_id()
	
	# Initialize entity's DoT tracking if needed
	if not active_dots.has(entity_id):
		active_dots[entity_id] = {}
	
	# Check for existing DoT of same type
	var existing_dot_id = _find_matching_dot(entity_id, dot_type)
	
	# If found and we're not stacking, update the existing DoT
	if existing_dot_id and not should_stack:
		var dot = active_dots[entity_id][existing_dot_id]
		
		# Update if new damage is higher
		if final_damage > dot.damage:
			dot.damage = final_damage
		
		# Reset duration
		dot.remaining_time = duration
		dot.duration = duration
		
		# Reset duration timer
		if is_instance_valid(dot.duration_timer):
			dot.duration_timer.stop()
			dot.duration_timer.wait_time = duration
			dot.duration_timer.start()
		
		print("DoTManager: Updated existing ", dot_type, " DoT on entity ", entity_id)
		return existing_dot_id
	
	# Check stacking limit
	if should_stack:
		var current_stacks = _count_dot_stacks(entity_id, dot_type)
		if current_stacks >= max_stacks:
			print("DoTManager: Max stacks reached for ", dot_type, " on entity ", entity_id)
			return ""
	
	# Create new DoT effect
	var dot_effect = DotEffect.new(entity, dot_type, final_damage, duration, interval, source)
	
	# Create tick timer
	var tick_timer = Timer.new()
	tick_timer.name = "TickTimer_" + dot_effect.dot_id
	tick_timer.wait_time = interval
	tick_timer.one_shot = false
	add_child(tick_timer)
	
	# Create duration timer
	var duration_timer = Timer.new()
	duration_timer.name = "DurationTimer_" + dot_effect.dot_id
	duration_timer.wait_time = duration
	duration_timer.one_shot = true
	add_child(duration_timer)
	
	# Store timers in effect
	dot_effect.tick_timer = tick_timer
	dot_effect.duration_timer = duration_timer
	
	# Connect timer signals
	tick_timer.timeout.connect(func(): _process_dot_tick(entity_id, dot_effect.dot_id))
	duration_timer.timeout.connect(func(): _remove_dot(entity_id, dot_effect.dot_id))
	
	# Start timers
	tick_timer.start()
	duration_timer.start()
	
	# Store the DoT
	active_dots[entity_id][dot_effect.dot_id] = dot_effect
	
	# Hook up to entity's DebuffComponent if it exists
	var debuff_component = entity.get_node_or_null("DebuffComponent")
	if debuff_component:
		var debuff_type = GlobalDebuffSystem.map_dot_to_debuff_type(dot_type)
		if debuff_type != GlobalDebuffSystem.DebuffType.NONE:
			debuff_component.add_debuff(
				debuff_type,
				duration,
				{
					"max_stacks": max_stacks,
					"source_damage": damage,
					"dot_id": dot_effect.dot_id
				}
			)
	
	# Emit signal
	emit_signal("dot_applied", entity, dot_type, dot_effect.dot_id)
	
	print("DoTManager: Applied new ", dot_type, " DoT (", dot_effect.dot_id, ") to entity ", entity_id)
	return dot_effect.dot_id

# Find a matching DoT on the entity
func _find_matching_dot(entity_id: int, dot_type: String) -> String:
	if not active_dots.has(entity_id):
		return ""
		
	for dot_id in active_dots[entity_id]:
		if active_dots[entity_id][dot_id].type == dot_type:
			return dot_id
			
	return ""

# Count the number of DoTs of the same type on an entity
func _count_dot_stacks(entity_id: int, dot_type: String) -> int:
	if not active_dots.has(entity_id):
		return 0
		
	var count = 0
	for dot_id in active_dots[entity_id]:
		if active_dots[entity_id][dot_id].type == dot_type:
			count += 1
			
	return count

# Process a DoT tick
func _process_dot_tick(entity_id: int, dot_id: String) -> void:
	# Verify entity and DoT still exist
	if not active_dots.has(entity_id) or not active_dots[entity_id].has(dot_id):
		print("DoTManager: Entity or DoT no longer exists for tick")
		return
		
	var dot = active_dots[entity_id][dot_id]
	
	# Verify entity still exists
	if not is_instance_valid(dot.entity):
		print("DoTManager: Entity no longer valid for DoT tick")
		_remove_dot(entity_id, dot_id)
		return
	
	# Get health component
	var health_component = dot.entity.get_node_or_null("HealthComponent")
	if not health_component:
		print("DoTManager: Entity no longer has HealthComponent")
		_remove_dot(entity_id, dot_id)
		return
	
	# Apply damage
	print("DoTManager: Applying ", dot.damage, " ", dot.type, " DoT damage to entity ", entity_id)
	health_component.take_damage(dot.damage, false, dot.type)
	
	# Emit tick signal
	emit_signal("dot_tick", dot.entity, dot.type, dot.damage, dot_id)
	
	# Reduce remaining time
	dot.remaining_time -= dot.interval
	
	# If remaining time is zero or negative, remove the DoT
	if dot.remaining_time <= 0:
		_remove_dot(entity_id, dot_id)

# Remove a DoT effect
func _remove_dot(entity_id: int, dot_id: String) -> void:
	# Verify entity and DoT still exist
	if not active_dots.has(entity_id) or not active_dots[entity_id].has(dot_id):
		return
	
	var dot = active_dots[entity_id][dot_id]
	var dot_type = dot.type
	var entity = dot.entity
	
	# Stop and clean up timers
	if is_instance_valid(dot.tick_timer):
		dot.tick_timer.stop()
		dot.tick_timer.queue_free()
		
	if is_instance_valid(dot.duration_timer):
		dot.duration_timer.stop()
		dot.duration_timer.queue_free()
	
	# Remove from active dots
	active_dots[entity_id].erase(dot_id)
	
	# Clean up empty entity entries
	if active_dots[entity_id].is_empty():
		active_dots.erase(entity_id)
	
	# Emit signal
	if is_instance_valid(entity):
		emit_signal("dot_removed", entity, dot_type, dot_id)
		
		# Notify DebuffComponent if it exists
		var debuff_component = entity.get_node_or_null("DebuffComponent")
		if debuff_component:
			var debuff_type = GlobalDebuffSystem.map_dot_to_debuff_type(dot_type)
			if debuff_type != GlobalDebuffSystem.DebuffType.NONE:
				# Only remove if all DoTs of this type are gone
				if _count_dot_stacks(entity_id, dot_type) == 0:
					debuff_component.remove_debuff(debuff_type)
	
	print("DoTManager: Removed ", dot_type, " DoT (", dot_id, ") from entity ", entity_id)

# Clean up expired DoTs and invalid entities
func _cleanup_expired_dots() -> void:
	var entities_to_check = active_dots.keys()
	
	for entity_id in entities_to_check:
		var dots_to_check = active_dots.get(entity_id, {}).keys()
		
		for dot_id in dots_to_check:
			if active_dots.has(entity_id) and active_dots[entity_id].has(dot_id):
				var dot = active_dots[entity_id][dot_id]
				
				# Check if entity is still valid
				if not is_instance_valid(dot.entity):
					_remove_dot(entity_id, dot_id)
					continue
				
				# Check if timers are still valid
				if not is_instance_valid(dot.tick_timer) or not is_instance_valid(dot.duration_timer):
					_remove_dot(entity_id, dot_id)
					continue

# -- Utility Methods --

# Check if an entity has any active DoTs
func has_dots(entity: Node) -> bool:
	var entity_id = entity.get_instance_id()
	return active_dots.has(entity_id) and not active_dots[entity_id].is_empty()

# Check if an entity has a specific type of DoT
func has_dot_type(entity: Node, dot_type: String) -> bool:
	var entity_id = entity.get_instance_id()
	
	if not active_dots.has(entity_id):
		return false
		
	for dot_id in active_dots[entity_id]:
		if active_dots[entity_id][dot_id].type == dot_type:
			return true
			
	return false

# Get all active DoTs on an entity
func get_entity_dots(entity: Node) -> Array:
	var entity_id = entity.get_instance_id()
	
	if not active_dots.has(entity_id):
		return []
		
	var dots = []
	for dot_id in active_dots[entity_id]:
		dots.append(active_dots[entity_id][dot_id])
		
	return dots

# Remove all DoTs from an entity
func remove_all_dots(entity: Node) -> void:
	var entity_id = entity.get_instance_id()
	
	if not active_dots.has(entity_id):
		return
		
	var dots_to_remove = active_dots[entity_id].keys()
	for dot_id in dots_to_remove:
		_remove_dot(entity_id, dot_id)

# Remove all DoTs of a specific type from an entity
func remove_dots_of_type(entity: Node, dot_type: String) -> void:
	var entity_id = entity.get_instance_id()
	
	if not active_dots.has(entity_id):
		return
		
	var dots_to_remove = []
	for dot_id in active_dots[entity_id]:
		if active_dots[entity_id][dot_id].type == dot_type:
			dots_to_remove.append(dot_id)
			
	for dot_id in dots_to_remove:
		_remove_dot(entity_id, dot_id)
