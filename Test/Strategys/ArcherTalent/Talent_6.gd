extends BaseProjectileStrategy
class_name Talent_6

# Fire damage configuration
@export var fire_damage_percent: float = 0.20  # 20% of base damage as fire
@export var dot_percent_per_tick: float = 0.05 # 5% of base damage per DoT tick
@export var dot_duration: float = 3.0          # Duration of fire effect in seconds
@export var dot_interval: float = 0.5          # Time between DoT ticks
@export var dot_chance: float = 0.30           # 30% chance to apply DoT
@export var talent_id: int = 6                 # ID for talent tree

# Friendly name for debug panel
func get_strategy_name() -> String:
	return "Flaming Arrows"

func apply_upgrade(projectile: Node) -> void:
	print("Applying Flaming Arrows upgrade!")
	
	# Add fire tag for identification
	if "tags" in projectile:
		if projectile.has_method("add_tag"):
			projectile.add_tag("fire")
		elif not "fire" in projectile.tags:
			projectile.tags.append("fire")
	
	# Set up metadata for fire damage
	projectile.set_meta("has_fire_effect", true)
	
	# Add DoT data as metadata for DoT system to use
	projectile.set_meta("fire_dot_data", {
		"chance": dot_chance,
		"damage_per_tick": dot_percent_per_tick,
		"duration": dot_duration,
		"interval": dot_interval,
		"type": "fire"
	})
	
	print("Flaming Arrows applied to projectile")
