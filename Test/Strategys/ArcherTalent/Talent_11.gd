extends BaseProjectileStrategy
class_name DoubleShot

# Configuration variables
@export var angle_spread: float = 15.0  # Angle between arrows in degrees
@export var second_arrow_damage_modifier: float = 1.0  # Full damage for second arrow

func get_strategy_name() -> String:
	return "DoubleShot"

func apply_upgrade(projectile: Node) -> void:
	# For the original system, still add metadata to projectile
	# This ensures compatibility with both systems
	if "double_shot_enabled" in projectile:
		projectile.double_shot_enabled = true
		
	if "double_shot_angle" in projectile:
		projectile.double_shot_angle = angle_spread
		
	# Add metadata for systems that check it
	projectile.set_meta("double_shot_enabled", true)
	projectile.set_meta("double_shot_angle", angle_spread)
	projectile.set_meta("second_arrow_damage_modifier", second_arrow_damage_modifier)
	
	# Add tag for identification
	if projectile.has_method("add_tag"):
		projectile.add_tag("double_shot")
		
	# Check if this is being applied to an archer
	if projectile is Soldier_Base:
		initialize_with_archer(projectile)

# Method to initialize the talent on the archer
func initialize_with_archer(archer_ref: Soldier_Base) -> void:
	# Add metadata to the archer to enable double shot
	if archer_ref:
		archer_ref.set_meta("has_double_shot", true)
		archer_ref.set_meta("double_shot_active", true)
		archer_ref.set_meta("double_shot_angle", angle_spread)
		archer_ref.set_meta("double_shot_damage_modifier", second_arrow_damage_modifier)
		
		print("Double Shot enabled for archer: ", archer_ref.name)
