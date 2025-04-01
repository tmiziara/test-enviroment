extends Node
class_name DebuffComponent

# Signals
signal debuff_added(debuff_type, duration, data)
signal debuff_removed(debuff_type)
signal debuff_stacks_changed(debuff_type, stacks)
signal debuff_duration_updated(debuff_type, remaining_time)

# Dictionary to store active debuffs - Format: {DebuffType: {data}}
var active_debuffs = {}

# Timer dictionary to track debuff durations
var debuff_timers = {}

# Reference to the entity this component is attached to
var entity

# Reference to the BuffDisplayContainer if available
var buff_display_container

func _ready():
	# Store reference to the entity (parent)
	entity = get_parent()
	
	# Try to find a BuffDisplayContainer in the entity
	buff_display_container = entity.get_node_or_null("BuffDisplayContainer")
	if not buff_display_container:
		# If not found directly, try to search deeper
		for child in entity.get_children():
			if child is BuffDisplayContainer:
				buff_display_container = child
				break

# Add a new debuff or refresh/stack an existing one
func add_debuff(debuff_type: int, duration: float, data: Dictionary = {}, can_refresh: bool = true) -> void:
	# Skip if it's a NONE debuff type
	if debuff_type == GlobalDebuffSystem.DebuffType.NONE:
		return
	
	# Default data
	var default_data = {
		"max_stacks": 1,
		"source": null,
		"display_icon": true,
		"stack_duration": true  # If true, refreshing stacks increases duration
	}
	
	# Merge passed data with defaults
	for key in default_data:
		if not key in data:
			data[key] = default_data[key]
	
	# Check if debuff already exists
	var is_new = not has_debuff(debuff_type)
	var is_stacked = false
	
	if is_new:
		# Create new debuff entry
		active_debuffs[debuff_type] = {
			"duration": duration,
			"remaining_time": duration,
			"stacks": 1,
			"max_stacks": data.max_stacks,
			"data": data
		}
		
		# Create timer for this debuff
		var timer = Timer.new()
		timer.one_shot = true
		timer.wait_time = duration
		timer.name = "DebuffTimer_" + str(debuff_type)
		add_child(timer)
		
		# Connect timer signal
		timer.timeout.connect(_on_debuff_timer_timeout.bind(debuff_type))
		timer.start()
		debuff_timers[debuff_type] = timer
		
		# Apply effects immediately
		_apply_debuff_effects(debuff_type, data)
		
	else:
		# Update existing debuff
		var current_debuff = active_debuffs[debuff_type]
		
		# If we can stack and haven't reached max stacks
		if current_debuff.stacks < current_debuff.max_stacks:
			current_debuff.stacks += 1
			is_stacked = true
			
			# Update data with new stack info
			if "stack_data" in data:
				current_debuff.data["stack_data"] = data.stack_data
		
		# If we can refresh duration or it's mandatory
		if can_refresh or current_debuff.remaining_time < duration:
			if data.stack_duration:
				# Add duration for stacking debuffs
				current_debuff.duration += duration
				current_debuff.remaining_time += duration
			else:
				# Just reset to the new duration if higher
				if current_debuff.remaining_time < duration:
					current_debuff.duration = duration
					current_debuff.remaining_time = duration
			
			# Update timer
			if debuff_type in debuff_timers and is_instance_valid(debuff_timers[debuff_type]):
				debuff_timers[debuff_type].stop()
				debuff_timers[debuff_type].wait_time = current_debuff.remaining_time
				debuff_timers[debuff_type].start()
	
	# Display debuff
	if data.display_icon and buff_display_container and buff_display_container.has_method("add_buff_icon"):
		var icon = GlobalDebuffSystem.get_debuff_icon(debuff_type)
		var color = GlobalDebuffSystem.get_debuff_color(debuff_type)
		var name = GlobalDebuffSystem.get_debuff_name(debuff_type)
		
		if icon:
			if is_new:
				# Add new icon
				buff_display_container.add_buff_icon(
					debuff_type,
					icon,
					color,
					name,
					duration,
					data.get("effect_name", name)
				)
			else:
				# Update existing icon
				buff_display_container.update_buff_icon(
					debuff_type,
					active_debuffs[debuff_type].remaining_time,
					active_debuffs[debuff_type].stacks
				)
	
	# Emit signals
	if is_new:
		emit_signal("debuff_added", debuff_type, duration, data)
	elif is_stacked:
		emit_signal("debuff_stacks_changed", debuff_type, active_debuffs[debuff_type].stacks)
	else:
		emit_signal("debuff_duration_updated", debuff_type, active_debuffs[debuff_type].remaining_time)

# Remove a debuff
func remove_debuff(debuff_type: int) -> void:
	if has_debuff(debuff_type):
		# Stop and remove timer
		if debuff_type in debuff_timers and is_instance_valid(debuff_timers[debuff_type]):
			debuff_timers[debuff_type].stop()
			debuff_timers[debuff_type].queue_free()
			debuff_timers.erase(debuff_type)
		
		# Remove from active debuffs
		var data = active_debuffs[debuff_type].data
		active_debuffs.erase(debuff_type)
		
		# Remove debuff effects
		_remove_debuff_effects(debuff_type, data)
		
		# Remove display
		if buff_display_container and buff_display_container.has_method("remove_buff_icon"):
			buff_display_container.remove_buff_icon(debuff_type)
		
		# Emit signal
		emit_signal("debuff_removed", debuff_type)

# Check if entity has a specific debuff
func has_debuff(debuff_type: int) -> bool:
	return debuff_type in active_debuffs

# Get debuff stacks count
func get_debuff_stacks(debuff_type: int) -> int:
	if has_debuff(debuff_type):
		return active_debuffs[debuff_type].stacks
	return 0

# Get debuff data
func get_debuff_data(debuff_type: int) -> Dictionary:
	if has_debuff(debuff_type):
		return active_debuffs[debuff_type].data
	return {}

# Get debuff remaining time
func get_debuff_remaining_time(debuff_type: int) -> float:
	if has_debuff(debuff_type):
		return active_debuffs[debuff_type].remaining_time
	return 0.0

# Get all active debuffs
func get_all_debuffs() -> Dictionary:
	return active_debuffs.duplicate(true)

# Process debuff ticking - called from _process in derived classes
func process_debuffs(delta: float) -> void:
	# Update remaining times
	var debuffs_to_remove = []
	
	for debuff_type in active_debuffs.keys():
		var debuff = active_debuffs[debuff_type]
		debuff.remaining_time -= delta
		
		# Check if debuff has expired
		if debuff.remaining_time <= 0:
			debuffs_to_remove.append(debuff_type)
		else:
			# Update display
			if buff_display_container and buff_display_container.has_method("update_buff_icon"):
				buff_display_container.update_buff_icon(debuff_type, debuff.remaining_time, debuff.stacks)
	
	# Remove expired debuffs
	for debuff_type in debuffs_to_remove:
		remove_debuff(debuff_type)

# Timer callback
func _on_debuff_timer_timeout(debuff_type: int) -> void:
	remove_debuff(debuff_type)

# Apply initial effects of a debuff
func _apply_debuff_effects(debuff_type: int, data: Dictionary) -> void:
	# Apply effects based on debuff type
	match debuff_type:
		GlobalDebuffSystem.DebuffType.SLOWED:
			_apply_slow_effect(data)
		GlobalDebuffSystem.DebuffType.STUNNED:
			_apply_stun_effect(data)
		GlobalDebuffSystem.DebuffType.KNOCKED:
			_apply_knockback_effect(data)
		# Other debuff type effects can be added here

# Remove effects of a debuff
func _remove_debuff_effects(debuff_type: int, data: Dictionary) -> void:
	# Remove effects based on debuff type
	match debuff_type:
		GlobalDebuffSystem.DebuffType.SLOWED:
			_remove_slow_effect(data)
		GlobalDebuffSystem.DebuffType.STUNNED:
			_remove_stun_effect(data)
		# Other debuff type effect removal can be added here

# Slow effect implementation
func _apply_slow_effect(data: Dictionary) -> void:
	var slow_percent = data.get("slow_percent", 0.3)  # Default 30% slow
	
	# Apply slow through MovementControlComponent if available
	var movement_control = entity.get_node_or_null("MovementControlComponent")
	if movement_control and movement_control.has_method("apply_slow"):
		movement_control.apply_slow(slow_percent)
	# Fallback to direct modification
	elif "base_speed" in entity and "move_speed" in entity:
		# Store original speed for restoration
		entity.set_meta("original_speed", entity.move_speed)
		entity.move_speed = entity.move_speed * (1.0 - slow_percent)

# Remove slow effect
func _remove_slow_effect(data: Dictionary) -> void:
	# Remove through MovementControlComponent if available
	var movement_control = entity.get_node_or_null("MovementControlComponent")
	if movement_control and movement_control.has_method("remove_slow"):
		movement_control.remove_slow()
	# Fallback to direct restoration
	elif "base_speed" in entity and entity.has_meta("original_speed"):
		entity.move_speed = entity.get_meta("original_speed")
		entity.remove_meta("original_speed")

# Stun effect implementation
func _apply_stun_effect(data: Dictionary) -> void:
	# Apply stun through MovementControlComponent if available
	var movement_control = entity.get_node_or_null("MovementControlComponent")
	if movement_control and movement_control.has_method("apply_stun"):
		movement_control.apply_stun()
	# Fallback to direct modification
	else:
		# Store entity state for restoration
		entity.set_meta("was_moving", entity.get_physics_process())
		entity.set_meta("was_attacking", entity.has_method("is_attacking") and entity.is_attacking)
		
		# Disable movement and attacks
		entity.set_physics_process(false)
		if entity.has_method("set_attacking"):
			entity.set_attacking(false)

# Remove stun effect
func _remove_stun_effect(data: Dictionary) -> void:
	# Remove through MovementControlComponent if available
	var movement_control = entity.get_node_or_null("MovementControlComponent")
	if movement_control and movement_control.has_method("remove_stun"):
		movement_control.remove_stun()
	# Fallback to direct restoration
	else:
		# Restore entity state
		if entity.has_meta("was_moving"):
			entity.set_physics_process(entity.get_meta("was_moving"))
			entity.remove_meta("was_moving")
		
		if entity.has_meta("was_attacking"):
			if entity.has_method("set_attacking"):
				entity.set_attacking(entity.get_meta("was_attacking"))
			entity.remove_meta("was_attacking")

# Knockback effect implementation
func _apply_knockback_effect(data: Dictionary) -> void:
	var knockback_direction = data.get("direction", Vector2.ZERO)
	var knockback_force = data.get("force", 150.0)
	
	# Apply knockback through MovementControlComponent if available
	var movement_control = entity.get_node_or_null("MovementControlComponent")
	if movement_control and movement_control.has_method("apply_knockback"):
		movement_control.apply_knockback(knockback_direction, knockback_force)
	# Fallback to direct velocity change if CharacterBody2D
	elif entity is CharacterBody2D:
		entity.velocity = knockback_direction * knockback_force
		
		# Create a timer to clear the knockback
		var timer = Timer.new()
		timer.wait_time = 0.3  # Short duration
		timer.one_shot = true
		entity.add_child(timer)
		timer.timeout.connect(func():
			entity.velocity = Vector2.ZERO
			timer.queue_free()
		)
		timer.start()
