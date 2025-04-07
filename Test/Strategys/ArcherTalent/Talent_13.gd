extends BaseProjectileStrategy
class_name ArrowRainStrategy

# Arrow Rain properties
@export var arrow_count: int = 5          # Number of arrows to fire in the area
@export var damage_per_arrow: float = 0.5  # Damage per rain arrow (50% of original arrow)
@export var radius: float = 80.0          # Radius of the rain area
@export var attacks_threshold: int = 10    # Every X attacks triggers the arrow rain

# Method to get strategy name for debugging
func get_strategy_name() -> String:
	return "ArrowRain"

func apply_upgrade(projectile: Node) -> void:
	if not projectile:
		return
	# Add tag for system identification
	if projectile.has_method("add_tag"):
		projectile.add_tag("arrow_rain")
	
	# Add metadata for ConsolidatedTalentSystem to process
	projectile.set_meta("arrow_rain_enabled", true)
	projectile.set_meta("arrow_rain_count", arrow_count)
	projectile.set_meta("arrow_rain_damage", damage_per_arrow)
	projectile.set_meta("arrow_rain_radius", radius)
	projectile.set_meta("arrow_rain_threshold", attacks_threshold)
	
	# For NewArrow class, directly set properties if available
	if projectile is Arrow and "arrow_rain_enabled" in projectile:
		projectile.arrow_rain_enabled = true
