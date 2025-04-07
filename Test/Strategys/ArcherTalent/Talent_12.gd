extends BaseProjectileStrategy
class_name ChainShotStrategy

# Chain shot properties
@export var chain_chance: float = 0.3       # 30% chance to ricochet
@export var chain_range: float = 150.0       # Maximum range for finding targets
@export var chain_damage_decay: float = 0.2  # 20% damage reduction for chained hit
@export var max_chains: int = 1              # Maximum number of ricochets - INCREASED to 3 for testing

# Method to get strategy name for debugging
func get_strategy_name() -> String:
	return "ChainShot"

func apply_upgrade(projectile: Node) -> void:
	if not projectile:
		return
	# Add tag for system identification
	if projectile.has_method("add_tag"):
		projectile.add_tag("chain_shot")
	
	# Check if projectile is an Arrow class
	if projectile is Arrow:
		# Enable chain shot in properties
		projectile.chain_shot_enabled = true
		projectile.chain_chance = chain_chance
		projectile.chain_range = chain_range
		projectile.chain_damage_decay = chain_damage_decay
		projectile.max_chains = max_chains
		projectile.current_chains = 0
		
		# IMPORTANT: Set will_chain to null initially to indicate it hasn't been determined yet
		projectile.will_chain = false
		
		# Make sure hit_targets is initialized
		if not projectile.hit_targets:
			projectile.hit_targets = []
		
		# Add metadata to help with debugging
		projectile.set_meta("chain_shot_debug", {
			"initial_max_chains": max_chains,
			"strategy_instance_id": get_instance_id(),
			"chance_computed": false  # Track if we've made the initial chain chance calculation
		})
		
	else:
		# For generic projectiles, set metadata
		projectile.set_meta("chain_shot_enabled", true)
		projectile.set_meta("chain_chance", chain_chance)
		projectile.set_meta("chain_range", chain_range)
		projectile.set_meta("chain_damage_decay", chain_damage_decay)
		projectile.set_meta("max_chains", max_chains)
		projectile.set_meta("current_chains", 0)
		projectile.set_meta("hit_targets", [])
		projectile.set_meta("will_chain", null)  # Initially null
		
		# Add debug metadata
		projectile.set_meta("chain_shot_debug", {
			"initial_max_chains": max_chains,
			"strategy_instance_id": get_instance_id(),
			"chance_computed": false 
		})
