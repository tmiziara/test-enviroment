extends Node

# Singleton for managing global debuff interactions and types
# Place this script at res://Singletons/GlobalDebuffSystem.gd and add to AutoLoad

# Predefined debuff types
enum DebuffType {
	BURNING,
	FREEZING,
	STUNNED,
	KNOCKED,
	SLOWED,
	BLEEDING,
	POISONED,
	MARKED_FOR_DEATH,
	NONE
}

# Debuff data structure
class DebuffData:
	var type: DebuffType
	var duration: float
	var dot_interval: float = 0.0
	var stack_count: int = 1
	var max_stacks: int = 1
	var data: Dictionary = {}
	var source = null

# Constants for display
const DEBUFF_ICONS = {
	DebuffType.BURNING: preload("res://Test/Assets/Icons/Debuffs/fire_debuff.png"),
	DebuffType.FREEZING: preload("res://Test/Assets/Icons/Debuffs/ice_debuff.png"),
	DebuffType.STUNNED: preload("res://Test/Assets/Icons/Debuffs/stun_debuff.png"),
	DebuffType.KNOCKED: preload("res://Test/Assets/Icons/Debuffs/knockback_debuff.png"),
	DebuffType.SLOWED: preload("res://Test/Assets/Icons/Debuffs/slow_debuff.png"),
	DebuffType.BLEEDING: preload("res://Test/Assets/Icons/Debuffs/bleeding_debuff.png"),
	DebuffType.POISONED: preload("res://Test/Assets/Icons/Debuffs/poison_debuff.png"),
	DebuffType.MARKED_FOR_DEATH: preload("res://Test/Assets/Icons/Debuffs/marked_debuff.png")
}

const DEBUFF_NAMES = {
	DebuffType.BURNING: "Burning",
	DebuffType.FREEZING: "Frozen",
	DebuffType.STUNNED: "Stunned",
	DebuffType.KNOCKED: "Knocked Back",
	DebuffType.SLOWED: "Slowed",
	DebuffType.BLEEDING: "Bleeding",
	DebuffType.POISONED: "Poisoned",
	DebuffType.MARKED_FOR_DEATH: "Marked for Death"
}

const DEBUFF_COLORS = {
	DebuffType.BURNING: Color(1.0, 0.4, 0.0, 1.0),      # Orange-red
	DebuffType.FREEZING: Color(0.5, 0.8, 1.0, 1.0),     # Light blue
	DebuffType.STUNNED: Color(1.0, 1.0, 0.0, 1.0),      # Yellow
	DebuffType.KNOCKED: Color(0.8, 0.4, 0.0, 1.0),      # Brown
	DebuffType.SLOWED: Color(0.7, 0.7, 1.0, 1.0),       # Pale blue
	DebuffType.BLEEDING: Color(0.8, 0.0, 0.0, 1.0),     # Red
	DebuffType.POISONED: Color(0.2, 0.8, 0.2, 1.0),     # Green
	DebuffType.MARKED_FOR_DEATH: Color(0.6, 0.0, 0.6, 1.0) # Purple
}

# Global interaction functions
static func process_debuff_interactions(entity, damage_type: String, damage_amount: int) -> int:
	var modified_damage = damage_amount
	
	# Check for entity's debuff manager
	if entity.has_method("get_debuff_component"):
		var debuff_component = entity.get_debuff_component()
		
		# Burning interaction
		if debuff_component.has_debuff(DebuffType.BURNING):
			modified_damage += _create_burning_explosion(entity)
		
		# Marked for Death interaction
		if debuff_component.has_debuff(DebuffType.MARKED_FOR_DEATH) and damage_type == "critical":
			var mark_data = debuff_component.get_debuff_data(DebuffType.MARKED_FOR_DEATH)
			var bonus = mark_data.get("crit_bonus", 1.0)
			modified_damage = int(modified_damage * (1.0 + bonus))
	
	return modified_damage

# Burning explosion logic
static func _create_burning_explosion(entity) -> int:
	var explosion_damage = 10  # Base explosion damage
	
	# Area explosion logic
	var space_state = entity.get_world_2d().direct_space_state
	var query = PhysicsShapeQueryParameters2D.new()
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = 50.0
	query.shape = circle_shape
	query.transform = Transform2D(0, entity.global_position)
	query.collision_mask = 2
	
	var results = space_state.intersect_shape(query)
	
	for result in results:
		var target = result.collider
		if target.has_method("take_damage"):
			target.take_damage(explosion_damage)
	
	return explosion_damage

# Function to map DoT to DebuffType
static func map_dot_to_debuff_type(dot_type: String) -> int:
	match dot_type:
		"fire":
			return DebuffType.BURNING
		"ice":
			return DebuffType.FREEZING
		"bleeding":
			return DebuffType.BLEEDING
		"poison":
			return DebuffType.POISONED
		_:  # Default case
			return DebuffType.NONE
			
# Function to map DebuffType to DoT
static func map_debuff_to_dot_type(debuff_type: int) -> String:
	match debuff_type:
		DebuffType.BURNING:
			return "fire"
		DebuffType.FREEZING:
			return "ice"
		DebuffType.BLEEDING:
			return "bleeding"
		DebuffType.POISONED:
			return "poison"
		_:
			return "generic"

# Method to help process movement control interactions
static func process_movement_control_interactions(entity, damage_type: String, damage_amount: int) -> int:
	var modified_damage = damage_amount
	
	# Check for entity's MovementControlComponent
	var movement_control = entity.get_node_or_null("MovementControlComponent")
	if not movement_control:
		return modified_damage
		
	# Fire damage has 20% chance to stun for 1 second
	if damage_type == "fire" and randf() <= 0.2:
		movement_control.apply_stun(1.0)
	
	# Ice damage has 50% chance to knockback
	if damage_type == "ice" and randf() <= 0.5:
		# Calculate knockback direction (away from damage source)
		var direction = Vector2.RIGHT  # Replace with appropriate direction
		movement_control.apply_knockback(direction, min(damage_amount * 10, 200))
		
	return modified_damage

# Get icon for a specific debuff type
static func get_debuff_icon(debuff_type: int):
	if debuff_type in DEBUFF_ICONS:
		return DEBUFF_ICONS[debuff_type]
	return null

# Get name for a specific debuff type
static func get_debuff_name(debuff_type: int) -> String:
	if debuff_type in DEBUFF_NAMES:
		return DEBUFF_NAMES[debuff_type]
	return "Unknown"

# Get color for a specific debuff type
static func get_debuff_color(debuff_type: int) -> Color:
	if debuff_type in DEBUFF_COLORS:
		return DEBUFF_COLORS[debuff_type]
	return Color(0.5, 0.5, 0.5, 1.0)  # Default gray
