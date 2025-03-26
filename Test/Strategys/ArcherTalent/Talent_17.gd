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
	print("Applying Marked for Death effect to target")
	
	# Check if target is valid
	if not is_instance_valid(target):
		print("Invalid target for Marked for Death")
		return
		
	# Check if target has a health component
	if not target.has_node("HealthComponent"):
		print("Target doesn't have HealthComponent")
		return
	
	# Get mark parameters
	var duration = projectile.get_meta("mark_duration", mark_duration)
	var crit_bonus = projectile.get_meta("crit_damage_bonus", crit_damage_bonus)
	
	# Apply the mark to the target
	print("Applying Marked for Death: +", crit_bonus * 100, "% critical damage for ", duration, " seconds")
	target.set_meta("marked_for_death", true)
	target.set_meta("mark_crit_bonus", crit_bonus)
	
	# Create mark effect visuals
	create_mark_visual_effect(target, duration)
	
	# Set up a timer to remove the mark after duration
	var timer = Timer.new()
	timer.name = "MarkTimer"
	timer.wait_time = duration
	timer.one_shot = true
	target.add_child(timer)
	
	# Create weak reference to target to prevent errors
	var target_ref = weakref(target)
	
	timer.timeout.connect(func():
		var target_obj = target_ref.get_ref()
		if target_obj and is_instance_valid(target_obj):
			# Remove mark
			if target_obj.has_meta("marked_for_death"):
				target_obj.remove_meta("marked_for_death")
			if target_obj.has_meta("mark_crit_bonus"):
				target_obj.remove_meta("mark_crit_bonus")
			print("Marked for Death effect expired")
			
			# Remove any mark visual effects
			for child in target_obj.get_children():
				if child.name == "MarkVisualEffect":
					child.queue_free()
					break
		# Self cleanup
		timer.queue_free()
	)
	timer.start()

# Create visual effect for the mark
func create_mark_visual_effect(target: Node, duration: float) -> void:
	# Create a Node2D for the effect
	var effect = Node2D.new()
	effect.name = "MarkVisualEffect"
	effect.position = Vector2(0, -20)  # Position above the enemy
	target.add_child(effect)
	
	# Create the mark sprite
	var mark_sprite = Sprite2D.new()
	
	# Create a simple arrow icon for the mark
	var img = Image.create(16, 16, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))  # Initially transparent
	
	# Draw a red skull-like shape
	for x in range(16):
		for y in range(16):
			# Skull shape pattern
			var dx = x - 8
			var dy = y - 8
			var dist = sqrt(dx*dx + dy*dy)
			
			# Create skull shape
			if (dist < 7 and dist > 5) or (abs(dx) < 3 and y > 8 and y < 12) or (abs(dy) < 2 and abs(dx) < 5 and y < 7):
				img.set_pixel(x, y, Color(0.8, 0.1, 0.1, 0.9))  # Bright red
	
	# Create texture
	var texture = ImageTexture.create_from_image(img)
	mark_sprite.texture = texture
	effect.add_child(mark_sprite)
	
	# Add a pulsing effect animation
	var script = GDScript.new()
	script.source_code = """
	extends Node2D
	
	var time = 0
	var pulse_speed = 3.0
	var pulse_min = 0.8
	var pulse_max = 1.2
	
	func _process(delta):
		time += delta * pulse_speed
		var pulse = pulse_min + (pulse_max - pulse_min) * (0.5 + 0.5 * sin(time))
		scale = Vector2(pulse, pulse)
		
		# Add a spinning effect
		rotation += delta * 0.5
		
		# Ensure the effect stays above the enemy
		if get_parent() and is_instance_valid(get_parent()):
			position = Vector2(0, -20)
	"""
	effect.set_script(script)
