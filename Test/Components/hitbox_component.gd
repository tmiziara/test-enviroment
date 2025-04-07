extends Area2D
class_name HitboxComponent

# Signal emitted when a hit occurs
signal hit_occurred(target, hit_data)

# The entity that owns this hitbox (typically a projectile or weapon)
var owner_entity: Node
# The source of the damage (typically the character that fired the projectile)
var damage_source: Node
# Whether this hitbox should process multiple hits or destroy after the first hit
var one_hit_only: bool = true
# Dictionary to store hit-related data for processing
var hit_data: Dictionary = {}
# Tracks entities this hitbox has already hit (for piercing/chaining)
var hit_entities: Array = []

func _ready():
	# Connect the area entered signal
	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)
	
	# The owner entity is typically the parent node
	owner_entity = get_parent()
	
	# Optional hook for initialization
	_init_hitbox()

# Virtual method for child classes to override for custom initialization
func _init_hitbox() -> void:
	pass

# Process when an area is entered
func _on_area_entered(area: Area2D) -> void:
	# Check if the area is a hurtbox
	if area is HurtboxComponent:
		# Get the entity that owns the hurtbox
		var target = area.get_hurtbox_owner()
		
		# Skip if we've already hit this entity and aren't allowing multiple hits
		if target in hit_entities and one_hit_only:
			return
		
		# Skip if the entity is on the same "team" (simple team check)
		if damage_source and target and _are_on_same_team(damage_source, target):
			return
		
		# Mark this entity as hit
		if target and not target in hit_entities:
			hit_entities.append(target)
		
		# Prepare hit data
		var processed_hit_data = _prepare_hit_data(target)
		
		# Process the hit with the hurtbox
		area.receive_hit(self, processed_hit_data)
		
		# Emit signal for external systems
		emit_signal("hit_occurred", target, processed_hit_data)
		
		# Handle post-hit processing
		_after_hit_processed(target, processed_hit_data)

# Prepare the hit data with relevant information
func _prepare_hit_data(target: Node) -> Dictionary:
	var data = hit_data.duplicate()
	
	# Add damage source if not already present
	if damage_source and not "damage_source" in data:
		data["damage_source"] = damage_source
	
	# If owner entity has a DmgCalculatorComponent, use it
	if owner_entity and owner_entity.has_node("DmgCalculatorComponent"):
		data["dmg_calculator"] = owner_entity.get_node("DmgCalculatorComponent")
	
	# Add additional information from the owner entity
	if owner_entity:
		# Get damage amount
		if "damage" in owner_entity and not "damage" in data:
			data["damage"] = owner_entity.damage
		
		# Get critical hit status
		if "is_crit" in owner_entity and not "is_critical" in data:
			data["is_critical"] = owner_entity.is_crit
		
		# Get damage type/tags
		if "tags" in owner_entity and not "tags" in data:
			data["tags"] = owner_entity.tags
	
	return data

# After a hit has been processed, handle any additional effects
func _after_hit_processed(target: Node, hit_data: Dictionary) -> void:
	# Handle one-hit behavior
	if one_hit_only and hit_entities.size() >= 1:
		# Disable collision
		set_deferred("monitoring", false)
		set_deferred("monitorable", false)
		
		# Signal the owner to destroy/recycle if it has the appropriate method
		if owner_entity and owner_entity.has_method("_on_hit_confirmed"):
			owner_entity._on_hit_confirmed(target, hit_data)

# Simple team check to prevent friendly fire
func _are_on_same_team(entity1: Node, entity2: Node) -> bool:
	# Default implementation just checks if they have the same team property
	if "team" in entity1 and "team" in entity2:
		return entity1.team == entity2.team
	
	# No team property, default to false (allow the hit)
	return false

# Public method to set damage source
func set_damage_source(source: Node) -> void:
	damage_source = source

# Public method to set owner entity
func set_owner_entity(entity: Node) -> void:
	owner_entity = entity

# Public method to set hit data
func set_hit_data(data: Dictionary) -> void:
	hit_data = data.duplicate()

# Public method to merge additional hit data
func add_hit_data(data: Dictionary) -> void:
	for key in data:
		hit_data[key] = data[key]

# Public method to enable/disable one hit behavior
func set_one_hit_only(value: bool) -> void:
	one_hit_only = value

# Reset the hitbox for reuse (useful for object pooling)
func reset() -> void:
	hit_entities.clear()
	hit_data.clear()
	set_deferred("monitoring", true)
	set_deferred("monitorable", true)
