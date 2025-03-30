extends BaseProjectileStrategy
class_name ChainShotStrategy

# Chain shot properties
var chain_chance: float = 0.3        # 30% chance to ricochet
var chain_range: float = 150.0       # Maximum range for finding targets
var chain_damage_decay: float = 0.2  # 20% damage reduction for chained hit
var max_chains: int = 1              # Maximum number of ricochets

func apply_upgrade(projectile: Node) -> void:
	if not projectile:
		return
	
	# Add tag for system identification
	if projectile.has_method("add_tag"):
		projectile.add_tag("chain_shot")
	
	# Check if projectile is an Arrow
	if projectile is NewArrow:
		# Enable chain shot in properties
		projectile.chain_shot_enabled = true
		projectile.chain_chance = chain_chance
		projectile.chain_range = chain_range
		projectile.chain_damage_decay = chain_damage_decay
		projectile.max_chains = max_chains
		projectile.current_chains = 0
		
		# Make sure hit_targets is initialized
		if not projectile.hit_targets:
			projectile.hit_targets = []
		
		print("ChainShot: Applied to Arrow - chain chance:", chain_chance)
	else:
		# For generic projectiles, set metadata
		projectile.set_meta("chain_shot_enabled", true)
		projectile.set_meta("chain_chance", chain_chance)
		projectile.set_meta("chain_range", chain_range)
		projectile.set_meta("chain_damage_decay", chain_damage_decay)
		projectile.set_meta("max_chains", max_chains)
		projectile.set_meta("current_chains", 0)
		projectile.set_meta("hit_targets", [])
		
		print("ChainShot: Applied to generic projectile via metadata")

# Helper method for debugging
func get_strategy_name() -> String:
	return "ChainShot"
