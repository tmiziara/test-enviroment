extends BaseProjectileStrategy
class_name ArrowStormPressureWaveStrategy

# Pressure Wave Properties
@export var knockback_force: float = 150.0            # Force of knockback in units per second
@export var slow_percent: float = 0.3                 # Slow amount (30% reduction)
@export var slow_duration: float = 1.5                # Duration of slow effect in seconds
@export var area_multiplier: float = 1.5              # Multiplies the Arrow Rain area by this value
@export var wave_visual_enabled: bool = true          # Whether to show the visual wave effect
@export var ground_duration: float = 3.0              # Duration of the ground effect in seconds

# Method to get strategy name for debugging
func get_strategy_name() -> String:
	return "ArrowStormPressureWave"

func apply_upgrade(projectile: Node) -> void:
	if not projectile:
		return
	
	print("PressureWave: Applying strategy to projectile")
	
	# Add tag for system identification
	if projectile.has_method("add_tag"):
		projectile.add_tag("pressure_wave")
	
	# Add metadata for ConsolidatedTalentSystem to process
	projectile.set_meta("pressure_wave_enabled", true)
	projectile.set_meta("knockback_force", knockback_force)
	projectile.set_meta("slow_percent", slow_percent)
	projectile.set_meta("slow_duration", slow_duration)
	projectile.set_meta("arrow_rain_area_multiplier", area_multiplier)
	projectile.set_meta("wave_visual_enabled", wave_visual_enabled)
	projectile.set_meta("ground_duration", ground_duration)
	
	# For special arrow types, directly set properties if available
	if "arrow_rain_radius" in projectile:
		projectile.arrow_rain_radius *= area_multiplier
		
	print("PressureWave: Configuration added with knockback:", knockback_force, 
		", slow:", slow_percent, ", duration:", slow_duration)
