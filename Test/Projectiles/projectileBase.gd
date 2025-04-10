extends CharacterBody2D
class_name ProjectileBase

# ======== STATS EXPORTADOS ========
@export var damage: int = 10
@export var speed: float = 400.0
@export var lifetime: float = 5.0
@export var max_distance: float = 600.0
@export var piercing: bool = false

# ======== PROPRIEDADES BÁSICAS ========
var direction: Vector2 = Vector2.RIGHT
var shooter = null  # Referência ao atirador
var is_crit: bool = false
var crit_chance: float = 0.1
var initial_position: Vector2

# ======== PROPRIEDADES DE ESTADO ========
var tags: Array = []  # Array para armazenar tags como "fire", "ice", etc.
var lifetime_timer: Timer

# ======== COMPONENTES ========
@onready var hitbox: HitboxComponent = $HitboxComponent
@onready var dmg_calculator: DmgCalculatorComponent = $DmgCalculatorComponent

# ======== SINAIS ========
signal on_hit(target, projectile)  # Sinal emitido ao atingir um alvo

func _ready():
	# Armazena a posição inicial para cálculo de distância
	initial_position = global_position
	
	# Configura o timer de vida útil
	lifetime_timer = Timer.new()
	lifetime_timer.wait_time = lifetime
	lifetime_timer.one_shot = true
	lifetime_timer.timeout.connect(_on_lifetime_expired)
	add_child(lifetime_timer)
	lifetime_timer.start()
	
	# Configura o hitbox
	if hitbox:
		hitbox.set_damage_source(shooter)
		hitbox.set_owner_entity(self)
		hitbox.set_one_hit_only(!piercing)
		hitbox.hit_occurred.connect(_on_hit_occurred)
	
	# Determina acerto crítico
	is_crit = _calculate_critical_hit()
	
	# Inicializa calculador de dano
	if dmg_calculator:
		if is_crit:
			dmg_calculator.base_damage = apply_critical_multiplier(damage)
		else:
			dmg_calculator.base_damage = damage
		

func _physics_process(delta):
	# Movimento básico
	velocity = direction * speed
	var collision = move_and_slide()
	
	# Verifica colisão com paredes
	if collision:
		_on_collision()
	
	# Verifica distância máxima
	if global_position.distance_to(initial_position) > max_distance:
		_on_max_distance_reached()

# ======== MÉTODOS DE ACERTO CRÍTICO ========
func _calculate_critical_hit() -> bool:
	if shooter and "crit_chance" in shooter:
		return randf() < shooter.crit_chance
	return randf() < crit_chance

func apply_critical_multiplier(base_damage: int) -> int:
	if not is_crit:
		return base_damage
		
	# Obtém multiplicador base
	var crit_multi = 2.0  # Padrão
	if shooter and "crit_multi" in shooter:
		crit_multi = shooter.crit_multi
	
	# Aplica bônus de talentos
	if has_meta("crit_damage_bonus"):
		crit_multi += get_meta("crit_damage_bonus")
	
	# Calcula dano final
	return int(base_damage * crit_multi)

# ======== MÉTODOS DE HIT E COLISÃO ========
func _on_hit_occurred(target, hit_data):
	# Emite sinal para sistemas externos
	emit_signal("on_hit", target, self)
	
	# Processa efeitos específicos do projétil
	process_on_hit(target)
	
	# Se não for perfurante, prepara para destruição
	if not piercing:
		_prepare_for_destruction()

func process_on_hit(target: Node) -> void:
	# Implementação base para processamento de hit
	# Pode ser sobrescrito em classes filhas
	pass

func _on_collision():
	# Comportamento básico em colisão com parede
	if not piercing:
		_prepare_for_destruction()

func _on_lifetime_expired():
	_prepare_for_destruction()

func _on_max_distance_reached():
	_prepare_for_destruction()

func _prepare_for_destruction():
	# Desativa física e colisões
	set_physics_process(false)
	
	if hitbox:
		hitbox.set_deferred("monitoring", false)
		hitbox.set_deferred("monitorable", false)
	
	# Destroi o projétil
	queue_free()

# ======== MÉTODOS DE TAGS ========
func add_tag(tag_name: String) -> void:
	if not tag_name in tags:
		tags.append(tag_name)

func has_tag(tag_name: String) -> bool:
	return tag_name in tags
