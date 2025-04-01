extends BaseProjectileStrategy
class_name PressureWaveStrategy

# Pressure Wave properties
@export var knockback_force: float = 150.0       # Force applied to enemies on hit
@export var slow_percent: float = 0.3            # Amount of slow effect (0.3 = 30% slower)
@export var slow_duration: float = 1.5           # Duration of slow effect in seconds
@export var area_multiplier: float = 1.5         # Multiplier for Arrow Rain area
@export var wave_visual_enabled: bool = true     # Enable visual wave effect
@export var ground_duration: float = 3.0         # Duration of ground effect in seconds

# Method to get strategy name for debugging
func get_strategy_name() -> String:
	return "PressureWave"

func apply_upgrade(projectile: Node) -> void:
	if not projectile:
		return
	# Add tag for system identification
	if projectile.has_method("add_tag"):
		projectile.add_tag("pressure_wave")
	
	# Add metadata for processing
	projectile.set_meta("pressure_wave_enabled", true)
	projectile.set_meta("knockback_force", knockback_force)
	projectile.set_meta("slow_percent", slow_percent)
	projectile.set_meta("slow_duration", slow_duration)
	projectile.set_meta("wave_visual_enabled", wave_visual_enabled)
	projectile.set_meta("ground_duration", ground_duration)
	
	# Increase Arrow Rain area if this is an Arrow Rain arrow
	if projectile.has_meta("arrow_rain_radius"):
		var current_radius = projectile.get_meta("arrow_rain_radius")
		projectile.set_meta("arrow_rain_radius", current_radius * area_multiplier)
