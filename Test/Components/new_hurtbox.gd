extends Area2D
class_name Hurtbox

@onready var owner_entity: NewProjectileBase = get_owner()  

func _ready():
	connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body):
	print("Hurtbox._on_body_entered called with: ", body)
	
	if not body.is_in_group("enemies") or not body.has_node("HealthComponent"):
		print("Body is not an enemy or doesn't have HealthComponent")
		return
	
	# Initialize hit_targets array if needed
	if not owner_entity.has_meta("hit_targets"):
		owner_entity.set_meta("hit_targets", [])
		
	# Get hit_targets array
	var hit_targets = owner_entity.get_meta("hit_targets")
	
	# Skip if target was already hit
	if body in hit_targets:
		print("Target already hit by this projectile, ignoring.")
		return
		
	# Add target to hit_targets array
	hit_targets.append(body)
	owner_entity.set_meta("hit_targets", hit_targets)
	
	# IMPORTANT: Different handling for NewArrow versus other projectiles
	if owner_entity is NewArrow or (owner_entity.has_method("process_on_hit") and owner_entity.get_script().get_path().find("arrow") >= 0):
		# For NewArrow, we delegate ALL damage handling to the arrow itself
		# to avoid double-damage application
		print("Delegating hit processing to Arrow.process_on_hit")
		owner_entity.process_on_hit(body)
	else:
		# Standard handling for non-Arrow projectiles
		print("Standard projectile hit processing")
		var health_component = body.get_node("HealthComponent")
		
		# Get calculated damage package
		var damage_package = owner_entity.get_damage_package()
		
		# Apply damage to enemy (including DoTs)
		if health_component.has_method("take_complex_damage"):
			print("Applying complex damage")
			health_component.take_complex_damage(damage_package)
		else:
			# Fallback to old method
			print("Applying simple damage")
			var physical_damage = damage_package.get("physical_damage", owner_entity.damage)
			var is_crit = damage_package.get("is_critical", owner_entity.is_crit)
			health_component.take_damage(physical_damage, is_crit)
		
		# Handle non-Arrow projectile piercing and destruction
		if owner_entity.piercing:
			var current_pierce_count = 0
			
			# Use explicitly tracked pierce count if available, otherwise calculate from hit targets
			if owner_entity.has_meta("current_pierce_count"):
				current_pierce_count = owner_entity.get_meta("current_pierce_count")
				# Increment the counter since we just hit another target
				current_pierce_count += 1
				owner_entity.set_meta("current_pierce_count", current_pierce_count)
			else:
				current_pierce_count = hit_targets.size() - 1
				owner_entity.set_meta("current_pierce_count", current_pierce_count)
			
			var max_pierce = 1
			if owner_entity.has_meta("piercing_count"):
				max_pierce = owner_entity.get_meta("piercing_count")
			elif "piercing_count" in owner_entity:
				max_pierce = owner_entity.piercing_count
			
			print("Pierced ", current_pierce_count, " of ", max_pierce, " possible enemies")
			
			if current_pierce_count >= max_pierce:
				print("Piercing limit reached, destroying projectile")
				if owner_entity.has_method("return_to_pool") and owner_entity.has_meta("pooled"):
					owner_entity.return_to_pool()
				else:
					owner_entity.queue_free()
		else:
			# Non-piercing projectile
			print("Non-piercing projectile hit, destroying")
			if owner_entity.has_method("return_to_pool") and owner_entity.has_meta("pooled"):
				owner_entity.return_to_pool()
			else:
				owner_entity.queue_free()
	
	return body
