extends BaseProjectileStrategy
class_name Talent_12

# Chain shot parameters
@export var chain_chance: float = 0.3        # 30% chance to ricochet
@export var chain_range: float = 150.0       # Maximum range for finding targets
@export var chain_damage_decay: float = 0.2  # 20% damage reduction for the chained hit
@export var max_chains: int = 1              # Maximum number of ricochets (1 = one ricochet)
@export var talent_id: int = 12              # ID of this talent

# Name for debug panel
func get_strategy_name() -> String:
	return "ChainShotStrategy"

func apply_upgrade(projectile: Node) -> void:
	print("Applying Chain Shot upgrade - " + str(chain_chance * 100) + "% chance to ricochet to another enemy")
	
	# Check if we need to upgrade to Arrow class first
	if not projectile is Arrow and "process_on_hit" in projectile:
		print("Converting projectile to use Chain Shot capability")
		# Since we can't change the class at runtime, we'll just add the needed properties
		projectile.set("chain_shot_enabled", true)
		projectile.set("chain_chance", chain_chance)
		projectile.set("chain_range", chain_range)
		projectile.set("chain_damage_decay", chain_damage_decay)
		projectile.set("max_chains", max_chains)
		projectile.set("current_chains", 0)
		projectile.set("hit_targets", [])
		
		# Add chain shot functionality using a lambda function
		projectile.set_meta("find_chain_target", func(original_target):
			print("Finding chain target for non-Arrow projectile...")
			
			# Wait a frame
			await projectile.get_tree().process_frame
			
			# Find potential targets
			var potential_targets = []
			var space_state = projectile.get_world_2d().direct_space_state
			
			# Circle query
			var query = PhysicsShapeQueryParameters2D.new()
			var circle_shape = CircleShape2D.new()
			circle_shape.radius = projectile.get("chain_range")
			query.shape = circle_shape
			query.transform = Transform2D(0, projectile.global_position)
			query.collision_mask = 2
			
			var results = space_state.intersect_shape(query)
			
			# Filter targets
			for result in results:
				var body = result.collider
				if body == original_target or body in projectile.get("hit_targets"):
					continue
					
				if (body.is_in_group("enemies") or body.get_collision_layer_value(2)) and body.has_node("HealthComponent"):
					potential_targets.append(body)
			
			if potential_targets.size() > 0:
				var next_target = potential_targets[randi() % potential_targets.size()]
				print("Chain Shot target found! Ricocheting to new target.")
				
				# Update damage
				if projectile.has_node("DmgCalculatorComponent"):
					var dmg_calc = projectile.get_node("DmgCalculatorComponent")
					if "base_damage" in dmg_calc:
						dmg_calc.base_damage = int(dmg_calc.base_damage * (1.0 - projectile.get("chain_damage_decay")))
					
					if "elemental_damage" in dmg_calc:
						for element_type in dmg_calc.elemental_damage.keys():
							dmg_calc.elemental_damage[element_type] = int(dmg_calc.elemental_damage[element_type] * (1.0 - projectile.get("chain_damage_decay")))
				
				projectile.damage = int(projectile.damage * (1.0 - projectile.get("chain_damage_decay")))
				
				# Update direction
				var new_direction = (next_target.global_position - projectile.global_position).normalized()
				projectile.direction = new_direction
				projectile.rotation = new_direction.angle()
				
				# Fix collision
				if projectile.has_node("Hurtbox"):
					var hurtbox = projectile.get_node("Hurtbox")
					hurtbox.monitoring = true
					hurtbox.monitorable = true
				
				projectile.collision_layer = 4
				projectile.collision_mask = 2
				
				# Position away from hit point
				projectile.global_position += new_direction * 5
				
				# Update chain count and velocity
				projectile.set("current_chains", projectile.get("current_chains") + 1)
				projectile.velocity = new_direction * projectile.speed
			else:
				print("No valid chain targets found within range.")
				projectile.queue_free()
		)
		
		# Add the process_on_hit method to the projectile if needed
		if not projectile.has_method("process_on_hit"):
			projectile.set_meta("process_on_hit", func(target):
				# Add target to hit_targets
				var hit_targets = projectile.get("hit_targets")
				if not target in hit_targets:
					hit_targets.append(target)
					projectile.set("hit_targets", hit_targets)
				
				# Check if should chain
				if projectile.get("chain_shot_enabled") and projectile.get("current_chains") < projectile.get("max_chains"):
					var roll = randf()
					if roll <= projectile.get("chain_chance"):
						var find_chain_func = projectile.get_meta("find_chain_target")
						find_chain_func.call(target)
			)
		
		print("Chain Shot functionality added to non-Arrow projectile")
	elif projectile is Arrow:
		# Standard setup for Arrow class
		projectile.chain_shot_enabled = true
		projectile.chain_chance = chain_chance
		projectile.chain_range = chain_range
		projectile.chain_damage_decay = chain_damage_decay
		projectile.max_chains = max_chains
		projectile.current_chains = 0
		
		# Initialize tracking arrays if not already present
		projectile.hit_targets = []
		
		print("Chain Shot properties configured successfully on arrow")
	else:
		print("WARNING: Projectile is not compatible with Chain Shot")
	
	# Add a tag for identification (generic functionality)
	if "tags" in projectile and projectile.has_method("add_tag"):
		if not "chain_shot" in projectile.tags:
			projectile.add_tag("chain_shot")
	
	print("Chain Shot upgrade successfully applied to projectile")
