extends Area2D
class_name HurtboxComponent

# Signal emitted when a hit is received
signal hit_received(hitbox, hit_data)
# Signal emitted after damage has been processed
signal damage_processed(final_damage, hit_data)

# The entity that owns this hurtbox
var owner_entity: Node
# Whether this hurtbox is currently active
var is_active: bool = true
# Optional hit immunity timer
var immunity_time: float = 0.0
var is_immune: bool = false

func _ready():
	# Connect the area entered signal
	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)
	
	# The owner entity is typically the parent node
	owner_entity = get_parent()
	
	# Optional hook for initialization
	_init_hurtbox()

# Virtual method for child classes to override for custom initialization
func _init_hurtbox() -> void:
	pass

# Process when an area is entered
func _on_area_entered(area: Area2D) -> void:
	# Verifique se está realmente processando hits
	if area is HitboxComponent and is_active and not is_immune:
		print("Hurtbox: Area entered - ", area)
		# Se não chamar receive_hit aqui, o hit pode não ser processado
		pass

# Public method to receive a hit from a hitbox
func receive_hit(hitbox: HitboxComponent, hit_data: Dictionary) -> void:
	# Skip if inactive or immune
	if not is_active or is_immune:
		return
	
	# Emit hit received signal for external systems
	emit_signal("hit_received", hitbox, hit_data)
	
	# Process the hit with appropriate components
	_process_hit(hitbox, hit_data)
	
	# Apply immunity if needed
	if immunity_time > 0:
		start_immunity(immunity_time)

# Process a hit with the entity's components
func _process_hit(hitbox: HitboxComponent, hit_data: Dictionary) -> void:
	# Skip if no owner entity
	if not owner_entity:
		return
	
	# Get the damage source
	var damage_source = hit_data.get("damage_source", hitbox.damage_source)
	
	# Process with HealthComponent if available
	if owner_entity.has_node("HealthComponent"):
		var health_component = owner_entity.get_node("HealthComponent")
		
		# Determine which method to use based on what's available
		if "dmg_calculator" in hit_data:
			# Use calculator from hit data
			var dmg_calc = hit_data.dmg_calculator
			var damage_package = dmg_calc.calculate_damage()
			
			# If critical, make sure it's in the package
			if hit_data.get("is_critical", false):
				damage_package["is_critical"] = true
			
			# Apply complex damage
			if health_component.has_method("take_complex_damage"):
				health_component.take_complex_damage(damage_package)
				emit_signal("damage_processed", damage_package.get("physical_damage", 0), hit_data)
			else:
				# Fallback to simple damage
				var damage = damage_package.get("physical_damage", 0)
				health_component.take_damage(damage, hit_data.get("is_critical", false))
				emit_signal("damage_processed", damage, hit_data)
				
		elif damage_source and damage_source.has_node("DmgCalculatorComponent"):
			# Use calculator from source
			var dmg_calc = damage_source.get_node("DmgCalculatorComponent")
			var damage_package = dmg_calc.calculate_damage()
			
			# If critical, make sure it's in the package
			if hit_data.get("is_critical", false):
				damage_package["is_critical"] = true
			
			# Apply complex damage
			if health_component.has_method("take_complex_damage"):
				health_component.take_complex_damage(damage_package)
				emit_signal("damage_processed", damage_package.get("physical_damage", 0), hit_data)
			else:
				# Fallback to simple damage
				var damage = damage_package.get("physical_damage", 0)
				health_component.take_damage(damage, hit_data.get("is_critical", false))
				emit_signal("damage_processed", damage, hit_data)
		else:
			# Fallback to basic damage processing
			var damage = hit_data.get("damage", 10)
			var is_critical = hit_data.get("is_critical", false)
			var damage_type = hit_data.get("damage_type", "")
			
			health_component.take_damage(damage, is_critical, damage_type)
			emit_signal("damage_processed", damage, hit_data)
	
	# Process any special hit effects (can be extended in child classes)
	_process_special_effects(hitbox, hit_data)

# Process any special hit effects (DoT, knockback, etc.)
func _process_special_effects(hitbox: HitboxComponent, hit_data: Dictionary) -> void:
	# Implement in child classes if needed
	pass

# Start immunity period
func start_immunity(duration: float) -> void:
	is_immune = true
	
	# Create a timer for immunity
	var timer = get_tree().create_timer(duration)
	timer.timeout.connect(func(): 
		is_immune = false
	)

# Activate/deactivate the hurtbox
func set_active(active: bool) -> void:
	is_active = active
	set_deferred("monitoring", active)
	set_deferred("monitorable", active)

# Get the owner of this hurtbox
func get_hurtbox_owner() -> Node:
	return owner_entity

# Set immunity time
func set_immunity_time(time: float) -> void:
	immunity_time = time

# Reset the hurtbox for reuse (useful for object pooling)
func reset() -> void:
	is_immune = false
	is_active = true
	set_deferred("monitoring", true)
	set_deferred("monitorable", true)
