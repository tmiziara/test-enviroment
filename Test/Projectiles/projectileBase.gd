extends CharacterBody2D
class_name ProjectileBase

@export var damage: int = 10
@export var crit_chance: float = 0.1
@export var speed: float = 400.0
@export var piercing: bool = false

# Propriedades para efeitos visuais baseados no tipo de dano
@export var trail_color: Color = Color.WHITE
@export var hit_particle_effect: PackedScene = null

var is_crit: bool = false  # O projétil calcula isso ao ser instanciado
var direction: Vector2 = Vector2.ZERO

# Novos métodos para trabalhar com tipos de dano
func set_damage_type(damage_type: int, damage_value: int) -> void:
	if not has_node("DamageInfo"):
		var damage_info = Node.new()
		damage_info.name = "DamageInfo"
		damage_info.set_meta("damage_types", {})
		add_child(damage_info)
	
	var damage_info = get_node("DamageInfo")
	var damage_types = damage_info.get_meta("damage_types")
	damage_types[damage_type] = damage_value
	damage_info.set_meta("damage_types", damage_types)
	
	# Atualiza a cor do rastro com base no tipo de dano predominante
	update_visual_effects()

func get_damage_type(damage_type: int) -> int:
	if has_node("DamageInfo"):
		var damage_info = get_node("DamageInfo")
		var damage_types = damage_info.get_meta("damage_types")
		if damage_types.has(damage_type):
			return damage_types[damage_type]
	return 0

func add_dot_effect(duration: float, interval: float = 1.0) -> void:
	if not has_node("DamageInfo"):
		var damage_info = Node.new()
		damage_info.name = "DamageInfo"
		damage_info.set_meta("damage_types", {})
		add_child(damage_info)
	
	var damage_info = get_node("DamageInfo")
	damage_info.set_meta("dot_duration", duration)
	damage_info.set_meta("dot_interval", interval)

func get_predominant_damage_type() -> int:
	if has_node("DamageInfo"):
		var damage_info = get_node("DamageInfo")
		var damage_types = damage_info.get_meta("damage_types")
		
		var highest_type = DamageCalculator.DamageType.PHYSICAL
		var highest_value = 0
		
		for dmg_type in damage_types:
			if damage_types[dmg_type] > highest_value:
				highest_value = damage_types[dmg_type]
				highest_type = dmg_type
		
		return highest_type
	return DamageCalculator.DamageType.PHYSICAL

func update_visual_effects() -> void:
	# Define a cor do rastro com base no tipo de dano predominante
	var predominant_type = get_predominant_damage_type()
	
	match predominant_type:
		DamageCalculator.DamageType.PHYSICAL:
			trail_color = Color.WHITE
		DamageCalculator.DamageType.FIRE:
			trail_color = Color(1.0, 0.5, 0.0)  # Laranja
		DamageCalculator.DamageType.ICE:
			trail_color = Color(0.5, 0.8, 1.0)  # Azul claro
		DamageCalculator.DamageType.WIND:
			trail_color = Color(0.7, 1.0, 0.7)  # Verde claro
		DamageCalculator.DamageType.ELECTRIC:
			trail_color = Color(1.0, 1.0, 0.0)  # Amarelo
		DamageCalculator.DamageType.POISON:
			trail_color = Color(0.5, 1.0, 0.0)  # Verde venenoso
		DamageCalculator.DamageType.BLEED:
			trail_color = Color(1.0, 0.0, 0.0)  # Vermelho
		DamageCalculator.DamageType.MAGIC:
			trail_color = Color(0.5, 0.0, 1.0)  # Roxo
	
	# Aqui você poderia atualizar os efeitos visuais como rastros ou partículas
	if has_node("Trail") and get_node("Trail") is Line2D:
		get_node("Trail").default_color = trail_color

func _ready():
	print("Projétil criado com crit_chance:", crit_chance)
	is_crit = is_critical_hit(crit_chance)
	update_visual_effects()

func _physics_process(delta):
	velocity = direction * speed
	move_and_slide()

# Função que verifica se o ataque será crítico
func is_critical_hit(crit_chance: float) -> bool:
	var roll = randf()
	var result = roll < crit_chance
	return result
