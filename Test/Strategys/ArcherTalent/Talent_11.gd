extends BaseProjectileStrategy
class_name DoubleShot

# Configuration variables
var angle_spread: float = 15.0  # Angle between arrows in degrees
var second_arrow_damage_modifier: float = 1.0  # Full damage for second arrow

func apply_upgrade(projectile: Node) -> void:
	# Validate projectile
	if not projectile:
		return
		
	# Enable double shot in the projectile
	if "double_shot_enabled" in projectile:
		projectile.double_shot_enabled = true
	
	# Set the angle spread
	if "double_shot_angle" in projectile:
		projectile.double_shot_angle = angle_spread
	
	# Add metadata for the consolidated talent system
	projectile.set_meta("double_shot_enabled", true)
	projectile.set_meta("double_shot_angle", angle_spread)
	projectile.set_meta("second_arrow_damage_modifier", second_arrow_damage_modifier)
	
	# Add tag for talent
	if projectile.has_method("add_tag"):
		projectile.add_tag("double_shot")
	
	# Note: We don't spawn the second arrow here
	# This is handled in the ConsolidatedTalentSystem and archer's talent manager
# Provide a name for debugging
func get_strategy_name() -> String:
	return "DoubleShot"
