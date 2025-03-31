extends BaseProjectileStrategy
class_name PressureWaveStrategy

# Pressure Wave properties for Arrow Rain
@export var knockback_force: float = 150.0       # Force of the knockback
@export var slow_percent: float = 0.3            # 30% movement slow
@export var slow_duration: float = 2.0           # Slow effect duration
@export var area_multiplier: float = 1.5         # Increases Arrow Rain area
@export var wave_visual_enabled: bool = true     # Enable visual effect
@export var ground_duration: float = 3.0         # How long the effect persists on the ground (seconds)

# Method to get strategy name for debugging
func get_strategy_name() -> String:
	return "PressureWave"

func apply_upgrade(projectile: Node) -> void:
	if not projectile:
		return
	
	# Check if this arrow is part of Arrow Rain system
	# This talent ONLY affects Arrow Rain
	if projectile.has_meta("arrow_rain_enabled") or projectile.has_meta("is_rain_arrow"):
		# Add tag for system identification
		if projectile.has_method("add_tag"):
			projectile.add_tag("pressure_wave")
		
		# Add metadata for ConsolidatedTalentSystem to process
		projectile.set_meta("pressure_wave_enabled", true)
		projectile.set_meta("knockback_force", knockback_force)
		projectile.set_meta("slow_percent", slow_percent)
		projectile.set_meta("slow_duration", slow_duration)
		projectile.set_meta("area_multiplier", area_multiplier)
		projectile.set_meta("wave_visual_enabled", wave_visual_enabled)
		projectile.set_meta("ground_duration", ground_duration)  # Add the ground duration
		
		# Enhanced Arrow Rain area
		if projectile.has_meta("arrow_rain_radius"):
			var current_radius = projectile.get_meta("arrow_rain_radius")
			projectile.set_meta("arrow_rain_radius", current_radius * area_multiplier)
		
		print("PressureWave: Strategy applied to Arrow Rain projectile")
	else:
		# This is not an Arrow Rain projectile, so don't apply the effect
		print("PressureWave: Skipped - not an Arrow Rain projectile")
