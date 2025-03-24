extends Area2D
class_name Hurtbox

@onready var owner_entity: ProjectileBase = get_owner()  

func _ready():
	connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body):
	print("Hurtbox._on_body_entered called with: ", body)
	
	if not body.is_in_group("enemies") or not body.has_node("HealthComponent"):
		print("Body is not an enemy or doesn't have HealthComponent")
		return
	
	var health_component = body.get_node("HealthComponent")
	
	# Check if this is a chain shot arrow that's already processing a ricochet
	if owner_entity is Arrow and owner_entity.has_method("process_on_hit"):
		if owner_entity.is_processing_ricochet:
			print("Arrow is currently processing ricochet - ignoring hit")
			return
		
		print("Calling Arrow.process_on_hit")
		owner_entity.process_on_hit(body)
	else:
		print("Standard projectile hit processing")
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
		
		# Check if the projectile should be destroyed after hitting a target
		if owner_entity.piercing:
			# Handle piercing projectile
			var current_count = 0
			if owner_entity.has_meta("current_pierce_count"):
				current_count = owner_entity.get_meta("current_pierce_count")
			
			current_count += 1
			owner_entity.set_meta("current_pierce_count", current_count)
			
			var max_pierce = 1
			if owner_entity.has_meta("piercing_count"):
				max_pierce = owner_entity.get_meta("piercing_count")
			
			print("Arrow pierced ", current_count, " of ", max_pierce + 1, " possible enemies")
			
			if current_count > max_pierce:
				print("Piercing limit reached, destroying arrow")
				owner_entity.queue_free()
		else:
			# If not piercing, destroy after hit
			print("Non-piercing projectile hit, destroying")
			owner_entity.queue_free()
	
	return body
