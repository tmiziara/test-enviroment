extends BaseProjectileStrategy
class_name Talent_17

# Marked for Death parameters
@export var mark_duration: float = 4.0        # Duration of the mark effect in seconds
@export var crit_damage_bonus: float = 1.0    # +100% bonus critical damage (multiplier)
@export var talent_id: int = 17               # ID for this talent in the talent tree

# Name for debug panel
func get_strategy_name() -> String:
	return "Marked for Death"

# Main upgrade application
func apply_upgrade(projectile: Node) -> void:
	print("Applying Marked for Death upgrade - Critical hits mark enemies for amplified damage")
	
	# Skip if this is from a mark effect to prevent recursion
	if projectile.has_meta("is_from_mark"):
		print("Skipping Marked for Death for mark-triggered arrow")
		return
	
	# Add tag for identification
	if "tags" in projectile and projectile.has_method("add_tag"):
		projectile.add_tag("marked_for_death")
	elif "tags" in projectile:
		if not "marked_for_death" in projectile.tags:
			projectile.tags.append("marked_for_death")
	
	# Mark arrow as having the mark effect
	projectile.set_meta("has_mark_effect", true)
	
	# Store mark parameters in arrow for later use
	projectile.set_meta("mark_duration", mark_duration)
	projectile.set_meta("crit_damage_bonus", crit_damage_bonus)
	
	# Store reference to this strategy
	projectile.set_meta("mark_strategy", weakref(self))
	
	# If it's an Arrow, enhance its hit processing
	if projectile is Arrow:
		enhance_arrow_hit_processing(projectile)
	
	print("Marked for Death successfully applied to projectile")

# Enhance Arrow hit processing for Marked for Death effect
func enhance_arrow_hit_processing(arrow: Arrow) -> void:
	print("Enhancing arrow hit processing for Marked for Death")
	
	# Store reference to this strategy for later
	var self_ref = weakref(self)
	
	# Connect to the on_hit signal if it exists
	if arrow.has_signal("on_hit"):
		# Check if we're already connected
		var connections = arrow.get_signal_connection_list("on_hit")
		var already_connected = false
		
		for connection in connections:
			if connection.callable.get_object() == self:
				already_connected = true
				break
		
		if not already_connected:
			arrow.connect("on_hit", func(target, proj):
				if proj == arrow and is_instance_valid(target):
					# Check if this was a critical hit
					if arrow.is_crit:
						# Get the reference to this strategy
						var strategy = self_ref.get_ref()
						if strategy:
							# Apply mark to the enemy
							strategy.apply_mark_to_enemy(arrow, target)
			)
			print("Connected to on_hit signal for Marked for Death effect")
	else:
		print("Arrow doesn't have on_hit signal, using metadata")
		# Set metadata so the Arrow knows to apply mark on critical hits
		arrow.set_meta("apply_mark_on_crit", true)
		arrow.set_meta("mark_strategy", self_ref)

# Apply mark to an enemy on critical hit
func apply_mark_to_enemy(projectile: Node, target: Node) -> void:
	print("Verificando se pode aplicar Marked for Death")
	
	# Check if target is valid
	if not is_instance_valid(target):
		print("Invalid target for Marked for Death")
		return
		
	# Check if target has needed components
	if not target.has_node("DebuffComponent"):
		print("Target doesn't have DebuffComponent")
		return
	
	# Get the debuff component
	var debuff_component = target.get_node("DebuffComponent")
	var marked_debuff_type = GlobalDebuffSystem.DebuffType.MARKED_FOR_DEATH
	
	# Only apply if not already marked
	if debuff_component.has_debuff(marked_debuff_type):
		print("Alvo já está marcado, não renovando o efeito")
		return
	
	# Get mark parameters
	var duration = projectile.get_meta("mark_duration", mark_duration)
	var crit_bonus = projectile.get_meta("crit_damage_bonus", crit_damage_bonus)
	
	print("Applying Marked for Death: +", crit_bonus * 100, "% critical damage for ", duration, " seconds")
	
	# Apply the debuff using the debuff component
	var mark_data = {
		"crit_bonus": crit_bonus,
		"max_stacks": 1
	}
	
	# Add the debuff - set can_renew to false to prevent multiple applications
	debuff_component.add_debuff(marked_debuff_type, duration, mark_data, false)
	
	# Set meta data for backward compatibility
	target.set_meta("marked_for_death", true)
	target.set_meta("mark_crit_bonus", crit_bonus)
	
	# Create a timer to remove the meta data when the debuff expires
	# Add timer to the target instead of self (the strategy)
	var timer = Timer.new()
	timer.name = "MarkTimer"
	timer.wait_time = duration
	timer.one_shot = true
	target.add_child(timer)
	
	# Connect to timer timeout
	timer.timeout.connect(func():
		if is_instance_valid(target):
			# Remove mark meta data
			if target.has_meta("marked_for_death"):
				target.remove_meta("marked_for_death")
			if target.has_meta("mark_crit_bonus"):
				target.remove_meta("mark_crit_bonus")
			print("Marked for Death effect expired")
		
		# Self cleanup
		timer.queue_free()
	)
	timer.start()
  
