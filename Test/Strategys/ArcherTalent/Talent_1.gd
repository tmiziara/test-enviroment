extends BaseProjectileStrategy
class_name PreciseAimStrategy

# Configuration variables
@export var damage_increase_percent: float = 15.0  # Percentage increase to damage
@export var enable_debug: bool = true  # Toggle debug mode

func get_strategy_name() -> String:
	return "PreciseAim"

func apply_upgrade(projectile: Node) -> void:
	# Store original values for debug comparison
	var original_damage = 0
	var new_damage = 0
	var dmg_calc_original = 0
	var dmg_calc_new = 0
	
	# Capture original values if debug is enabled
	if enable_debug:
		if "damage" in projectile:
			original_damage = projectile.damage
		
		if projectile.has_node("DmgCalculatorComponent"):
			var dmg_calc = projectile.get_node("DmgCalculatorComponent")
			if "base_damage" in dmg_calc:
				dmg_calc_original = dmg_calc.base_damage
	
	# Add tag for identification
	if projectile.has_method("add_tag"):
		projectile.add_tag("precise_aim")
	
	# Add metadata for the ConsolidatedTalentSystem to process
	projectile.set_meta("precise_aim_enabled", true)
	projectile.set_meta("damage_increase_percent", damage_increase_percent)
	
	# Direct property modification for projectiles that support it
	if "damage" in projectile:
		var increase_multiplier = 1.0 + (damage_increase_percent / 100.0)
		projectile.damage = int(projectile.damage * increase_multiplier)
		if enable_debug:
			new_damage = projectile.damage
		
	# Apply to DmgCalculatorComponent if available
	if projectile.has_node("DmgCalculatorComponent"):
		var dmg_calc = projectile.get_node("DmgCalculatorComponent")
		
		# Increase base damage
		if "base_damage" in dmg_calc:
			var increase_multiplier = 1.0 + (damage_increase_percent / 100.0)
			dmg_calc.base_damage = int(dmg_calc.base_damage * increase_multiplier)
			if enable_debug:
				dmg_calc_new = dmg_calc.base_damage
		
		# Increase damage multiplier
		if "damage_multiplier" in dmg_calc:
			dmg_calc.damage_multiplier *= (1.0 + (damage_increase_percent / 100.0))
	
	# Check if being applied to an archer instead of a projectile
	if projectile is SoldierBase:
		_apply_to_archer(projectile)
	
	# Output debug information
	if enable_debug:
		_log_debug_info(projectile, original_damage, new_damage, dmg_calc_original, dmg_calc_new)

# Method to apply effects directly to the archer
func _apply_to_archer(archer: SoldierBase) -> void:
	var original_multiplier = archer.damage_multiplier
	
	# Increase archer's damage multiplier
	if "damage_multiplier" in archer:
		archer.damage_multiplier *= (1.0 + (damage_increase_percent / 100.0))
	
	# Store original damage multiplier for potential resets
	if not archer.has_meta("original_damage_multiplier"):
		archer.set_meta("original_damage_multiplier", original_multiplier)
	
	# For debugging
	if enable_debug:
		print("[PreciseAim Debug] Applied to archer: damage_multiplier changed from ", 
			original_multiplier, " to ", archer.damage_multiplier, 
			" (", damage_increase_percent, "% increase)")
		
		# Add a visual debug indicator to the archer
		_add_archer_debug_indicator(archer)

# Helper method to log debug information
func _log_debug_info(projectile: Node, original_damage: int, new_damage: int, dmg_calc_original: int, dmg_calc_new: int) -> void:
	print("\n==== PRECISE AIM DEBUG INFO ====")
	print("Target: ", projectile.name, " (", projectile.get_class(), ")")
	
	if original_damage > 0 or new_damage > 0:
		var percent_change = ((new_damage - original_damage) / float(max(1, original_damage))) * 100
	if dmg_calc_original > 0 or dmg_calc_new > 0:
		var percent_change = ((dmg_calc_new - dmg_calc_original) / float(max(1, dmg_calc_original))) * 100
	
	# Check if the damage calculator has a damage_multiplier
	if projectile.has_node("DmgCalculatorComponent"):
		var dmg_calc = projectile.get_node("DmgCalculatorComponent")
		if "damage_multiplier" in dmg_calc:
			print("DmgCalculator multiplier: ", dmg_calc.damage_multiplier)
	
	# Add visual marker to projectile in the game world if possible
	_add_visual_debug_marker(projectile)
	
	print("Expected increase: ", damage_increase_percent, "%")
	print("================================\n")

# Add a visual indicator in the game world (if possible)
func _add_visual_debug_marker(projectile: Node) -> void:
	# Only add visual markers to projectiles
	if projectile is ProjectileBase or projectile is CharacterBody2D:
		# Create a label to show damage above the projectile
		var label = Label.new()
		label.name = "DamageDebugLabel"
		label.text = "PreciseAim: +" + str(damage_increase_percent) + "%"
		label.modulate = Color(1, 0.5, 0, 1)  # Orange color
		label.position = Vector2(-40, -30)  # Position above projectile
		
		# Add outline for better visibility
		label.add_theme_color_override("font_outline_color", Color.BLACK)
		label.add_theme_constant_override("outline_size", 2)
		
		# Add the label to the projectile
		projectile.add_child(label)
		
		# Create a timer to remove the label after a few seconds
		var timer = Timer.new()
		timer.wait_time = 3.0
		timer.one_shot = true
		timer.autostart = true
		projectile.add_child(timer)
		
		# Connect timer to remove the label
		timer.timeout.connect(func(): 
			if is_instance_valid(label) and is_instance_valid(timer):
				label.queue_free()
				timer.queue_free()
		)

# Add a debug indicator to the archer
func _add_archer_debug_indicator(archer: Node) -> void:
	# Remove any existing debug indicators
	var existing = archer.get_node_or_null("PreciseAimDebugLabel")
	if existing:
		existing.queue_free()
	
	# Create a new label
	var label = Label.new()
	label.name = "PreciseAimDebugLabel"
	label.text = "Damage +15%"
	label.modulate = Color(1, 0.7, 0, 1)  # Gold color
	label.position = Vector2(0, -50)  # Position above archer
	
	# Add outline for better visibility
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 2)
	
	# Add the label to the archer
	archer.add_child(label)

# Debug method to manually trigger damage calculation and print values
func test_damage_calculation(projectile: Node) -> void:
	print("\n==== PRECISE AIM TEST CALCULATION ====")
	
	if projectile.has_node("DmgCalculatorComponent"):
		var dmg_calc = projectile.get_node("DmgCalculatorComponent")
		var package_before = dmg_calc.calculate_damage().duplicate()
		
		# Apply the upgrade
		var increase_multiplier = 1.0 + (damage_increase_percent / 100.0)
		if "base_damage" in dmg_calc:
			dmg_calc.base_damage = int(dmg_calc.base_damage * increase_multiplier)
		
		var package_after = dmg_calc.calculate_damage()
		
		# Print results
		print("Before upgrade: ", package_before)
		print("After upgrade: ", package_after)
		print("Physical damage change: ", 
			package_before.get("physical_damage", 0), " → ", 
			package_after.get("physical_damage", 0))
	else:
		print("No DmgCalculatorComponent found")
	
	print("================================\n")
