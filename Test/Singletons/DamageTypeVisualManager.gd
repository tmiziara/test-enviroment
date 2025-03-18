extends Node
class_name DamageVisualManager

# Singleton para gerenciar efeitos visuais relacionados a tipos de dano
# Adicione esta classe como autoload em seu projeto

# Constantes de cores para cada tipo de dano
const DAMAGE_TYPE_COLORS = {
	DamageCalculator.DamageType.PHYSICAL: Color(0.9, 0.9, 0.9),    # Branco/cinza
	DamageCalculator.DamageType.FIRE: Color(1.0, 0.5, 0.0),        # Laranja
	DamageCalculator.DamageType.ICE: Color(0.5, 0.8, 1.0),         # Azul claro
	DamageCalculator.DamageType.WIND: Color(0.7, 1.0, 0.7),        # Verde claro
	DamageCalculator.DamageType.ELECTRIC: Color(1.0, 1.0, 0.0),    # Amarelo
	DamageCalculator.DamageType.POISON: Color(0.5, 1.0, 0.0),      # Verde venenoso
	DamageCalculator.DamageType.BLEED: Color(1.0, 0.0, 0.0),       # Vermelho
	DamageCalculator.DamageType.MAGIC: Color(0.5, 0.0, 1.0),       # Roxo
}

# Nomes para tipos de dano (para UI e legendas)
const DAMAGE_TYPE_NAMES = {
	DamageCalculator.DamageType.PHYSICAL: "Físico",
	DamageCalculator.DamageType.FIRE: "Fogo",
	DamageCalculator.DamageType.ICE: "Gelo",
	DamageCalculator.DamageType.WIND: "Vento",
	DamageCalculator.DamageType.ELECTRIC: "Elétrico",
	DamageCalculator.DamageType.POISON: "Veneno",
	DamageCalculator.DamageType.BLEED: "Sangramento",
	DamageCalculator.DamageType.MAGIC: "Mágico",
}

# Ícones para cada tipo de dano (para UI)
@export var physical_icon: Texture
@export var fire_icon: Texture
@export var ice_icon: Texture
@export var wind_icon: Texture
@export var electric_icon: Texture
@export var poison_icon: Texture
@export var bleed_icon: Texture
@export var magic_icon: Texture

# Cenas de partículas para efeitos de impacto
@export var physical_impact_effect: PackedScene
@export var fire_impact_effect: PackedScene
@export var ice_impact_effect: PackedScene
@export var wind_impact_effect: PackedScene
@export var electric_impact_effect: PackedScene
@export var poison_impact_effect: PackedScene
@export var bleed_impact_effect: PackedScene
@export var magic_impact_effect: PackedScene

# Trilhas para projéteis
@export var fire_trail_material: Material
@export var ice_trail_material: Material
@export var poison_trail_material: Material
@export var electric_trail_material: Material
@export var magic_trail_material: Material

# Retorna a cor para um tipo de dano
func get_color_for_damage_type(damage_type: int) -> Color:
	if DAMAGE_TYPE_COLORS.has(damage_type):
		return DAMAGE_TYPE_COLORS[damage_type]
	return Color.WHITE

# Retorna o nome para um tipo de dano
func get_name_for_damage_type(damage_type: int) -> String:
	if DAMAGE_TYPE_NAMES.has(damage_type):
		return DAMAGE_TYPE_NAMES[damage_type]
	return "Desconhecido"

# Retorna o ícone para um tipo de dano
func get_icon_for_damage_type(damage_type: int) -> Texture:
	match damage_type:
		DamageCalculator.DamageType.PHYSICAL:
			return physical_icon
		DamageCalculator.DamageType.FIRE:
			return fire_icon
		DamageCalculator.DamageType.ICE:
			return ice_icon
		DamageCalculator.DamageType.WIND:
			return wind_icon
		DamageCalculator.DamageType.ELECTRIC:
			return electric_icon
		DamageCalculator.DamageType.POISON:
			return poison_icon
		DamageCalculator.DamageType.BLEED:
			return bleed_icon
		DamageCalculator.DamageType.MAGIC:
			return magic_icon
	return null

# Cria um efeito de impacto para um tipo de dano em uma posição específica
func create_impact_effect(damage_type: int, position: Vector2) -> void:
	var effect_scene = null
	
	match damage_type:
		DamageCalculator.DamageType.PHYSICAL:
			effect_scene = physical_impact_effect
		DamageCalculator.DamageType.FIRE:
			effect_scene = fire_impact_effect
		DamageCalculator.DamageType.ICE:
			effect_scene = ice_impact_effect
		DamageCalculator.DamageType.WIND:
			effect_scene = wind_impact_effect
		DamageCalculator.DamageType.ELECTRIC:
			effect_scene = electric_impact_effect
		DamageCalculator.DamageType.POISON:
			effect_scene = poison_impact_effect
		DamageCalculator.DamageType.BLEED:
			effect_scene = bleed_impact_effect
		DamageCalculator.DamageType.MAGIC:
			effect_scene = magic_impact_effect
	
	if effect_scene:
		var effect = effect_scene.instantiate()
		effect.global_position = position
		
		# Adiciona à árvore da cena e configura para auto-destruir
		get_tree().root.add_child(effect)
		
		# Se tiver um sistema de partículas, configura para auto-destruir
		if effect is CPUParticles2D or effect is GPUParticles2D:
			effect.emitting = true
			effect.one_shot = true
			
			# Cria um timer para auto-destruir após a duração
			var timer = Timer.new()
			timer.wait_time = effect.lifetime + 0.5  # Adiciona margem
			timer.one_shot = true
			effect.add_child(timer)
			timer.timeout.connect(func(): effect.queue_free())
			timer.start()
	else:
		# Cria um efeito genérico quando não há um específico
		create_generic_impact_effect(damage_type, position)

# Cria um efeito de impacto genérico para um tipo de dano
func create_generic_impact_effect(damage_type: int, position: Vector2) -> void:
	var particles = CPUParticles2D.new()
	
	# Configura as partículas
	particles.amount = 20
	particles.one_shot = true
	particles.explosiveness = 0.8
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = 5.0
	particles.direction = Vector2.UP
	particles.spread = 180
	particles.gravity = Vector2(0, 98)
	particles.initial_velocity_min = 30
	particles.initial_velocity_max = 60
	particles.scale_amount_min = 2.0
	particles.scale_amount_max = 2.0
	particles.lifetime = 0.8
	
	# Define a cor baseada no tipo de dano
	particles.color = get_color_for_damage_type(damage_type)
	
	# Adiciona à árvore da cena
	get_tree().root.add_child(particles)
	particles.global_position = position
	particles.emitting = true
	
	# Cria um timer para auto-destruir
	var timer = Timer.new()
	timer.wait_time = particles.lifetime + 0.5
	timer.one_shot = true
	particles.add_child(timer)
	timer.timeout.connect(func(): particles.queue_free())
	timer.start()

# Configura um projétil com efeitos visuais baseados no tipo de dano
func apply_projectile_visuals(projectile: Node, damage_type: int) -> void:
	# Verifica se tem uma sprite
	if projectile.has_node("Sprite2D"):
		var sprite = projectile.get_node("Sprite2D")
		
		# Aplica tint leve baseado no tipo
		sprite.modulate = get_color_for_damage_type(damage_type).lightened(0.7)
	
	# Adiciona um rastro se não tiver
	if !projectile.has_node("Trail") and projectile is Node2D:
		var trail = Line2D.new()
		trail.name = "Trail"
		trail.width = 4.0
		trail.default_color = get_color_for_damage_type(damage_type)
		
		# Configura o material baseado no tipo
		match damage_type:
			DamageCalculator.DamageType.FIRE:
				if fire_trail_material:
					trail.material = fire_trail_material
			DamageCalculator.DamageType.ICE:
				if ice_trail_material:
					trail.material = ice_trail_material
			DamageCalculator.DamageType.POISON:
				if poison_trail_material:
					trail.material = poison_trail_material
			DamageCalculator.DamageType.ELECTRIC:
				if electric_trail_material:
					trail.material = electric_trail_material
			DamageCalculator.DamageType.MAGIC:
				if magic_trail_material:
					trail.material = magic_trail_material
		
		projectile.add_child(trail)
		
		# Adiciona um script para o rastro
		add_trail_script(trail, projectile)
	
	# Adiciona um sistema de partículas se não tiver
	if !projectile.has_node("Particles") and projectile is Node2D:
		var particles = CPUParticles2D.new()
		particles.name = "Particles"
		particles.amount = 10
		particles.lifetime = 0.5
		particles.local_coords = false
		particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_POINT
		particles.gravity = Vector2.ZERO
		particles.color = get_color_for_damage_type(damage_type)
		
		projectile.add_child(particles)
		particles.emitting = true

# Adiciona um script para o rastro do projétil
func add_trail_script(trail: Line2D, projectile: Node2D) -> void:
	# Cria um script
	var script = GDScript.new()
	script.source_code = """
	extends Line2D

	# Configurações
	var max_points = 30
	var target_path: NodePath

	# Referência para o projétil
	var target: Node2D

	func _ready():
		# Obtém o nó alvo (projétil)
		target = get_parent()
		
		# Configura o trail
		top_level = true
		global_position = Vector2.ZERO
		clear_points()
		
		# Adiciona pontos iniciais
		add_point(target.global_position)
		add_point(target.global_position)

	func _process(delta):
		if not is_instance_valid(target):
			queue_free()
			return
			
		# Adiciona a posição atual do projétil
		add_point(target.global_position)
		
		# Limita a quantidade de pontos
		if points.size() > max_points:
			remove_point(0)
	"""
	
	# Aplica o script
	script.reload()
	trail.set_script(script)
