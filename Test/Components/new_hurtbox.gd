extends Area2D
class_name NewHurtbox

@onready var owner_entity: NewProjectileBase = get_owner()  

func _ready():
	connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body):
	print("Hurtbox._on_body_entered called with: ", body)
	
	if not body.is_in_group("enemies") or not body.has_node("HealthComponent"):
		print("Body is not an enemy or doesn't have HealthComponent")
		return
	
	# Check if this target has already been hit (for piercing support)
	if owner_entity.has_meta("hit_targets"):
		var hit_targets = owner_entity.get_meta("hit_targets")
		if body in hit_targets:
			print("This target has already been hit by this projectile, ignoring.")
			return
			
		# Add target to hit targets list
		hit_targets.append(body)
		owner_entity.set_meta("hit_targets", hit_targets)
	
	# Process hit for Arrow
	if owner_entity is NewArrow and owner_entity.has_method("process_on_hit"):
		if owner_entity.is_processing_ricochet:
			print("Arrow is currently processing ricochet - ignoring hit")
			return
		
		print("Calling Arrow.process_on_hit")
		owner_entity.process_on_hit(body)
	else:
		# Standard projectile hit processing
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
		
		# Destroy non-Arrow projectile if not piercing
		if not owner_entity.piercing:
			print("Non-piercing projectile hit, destroying")
			owner_entity.queue_free()
	
	return body
