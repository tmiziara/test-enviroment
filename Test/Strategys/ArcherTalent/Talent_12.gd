extends BaseProjectileStrategy
class_name Talent_12

# Chain shot parameters
@export var chain_chance: float = 0.3        # 30% chance to ricochet
@export var chain_range: float = 150.0       # Maximum range for finding targets
@export var chain_damage_decay: float = 0.2  # 20% damage reduction for the chained hit
@export var talent_id: int = 12              # ID of this talent

# Name for debug panel
func get_strategy_name() -> String:
	return "ChainShotStrategy"

func apply_upgrade(projectile: Node) -> void:
	print("Applying Chain Shot upgrade - " + str(chain_chance * 100) + "% chance to ricochet to another enemy")
	
	# Check if projectile has necessary properties
	if not "process_on_hit" in projectile:
		print("ERROR: Projectile does not have a process_on_hit method!")
		return
		
	# Enable chain shot on the projectile
	projectile.chain_shot_enabled = true
	projectile.chain_chance = chain_chance
	projectile.chain_range = chain_range
	projectile.chain_damage_decay = chain_damage_decay
	projectile.max_chains = 1  # Limit to one ricochet
	projectile.current_chains = 0
	
	# Initialize tracking arrays if not already present
	projectile.hit_targets = []
	projectile.damaged_targets = []  # Critical for preventing duplicate damage
	
	# Add a tag for identification
	if "add_tag" in projectile:
		projectile.add_tag("chain_shot")
		
	print("Chain Shot upgrade successfully applied to projectile")
