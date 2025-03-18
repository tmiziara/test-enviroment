class_name Soldier_Base
extends CharacterBody2D

# Atributos gerais
@export var icon_texture: Texture2D
@export var attack_range: float = 300.0
@export var sp: float = 0.0
@export var main_stat: int = 10  # Atributo principal (DEX para arqueiros, STR para guerreiros, INT para magos)
@export var main_stat_type: String = "dexterity"  # "dexterity", "strength" ou "intelligence"
@export var meele: float = 0.0
@export var magic: float = 0.0
@export var type: String = ""
@export var classType: String = ""
@export var attack_cooldown: float = 1.0
@export var move_speed: float = 100.0
@export var hp: float = 100.0
@export var idle_time: float = 5.0
@export var soldier_name: String = ""
@export var soldier_preview: PackedScene
@export var equipment_slots: Dictionary = {
	"Weapons": null,  # Arma
	"Armor": null,   # Armadura
	"Ring": null,    # Anel
	"Amulet": null   # Amuleto
}

# Identificador único (UUID)
var unique_id: String = ""

# Estados gerais
var is_idle: bool = false
var is_attacking: bool = false
var current_target: CharacterBody2D = null
var mobs_in_range: Array = []

# Atributos relacionados à movimentação
@export var movement_radius: float = 50.0
var target_position: Vector2

# Referências de animação
@onready var animation_tree: AnimationTree = $AnimationTree
@onready var idle_timer: Timer = Timer.new()
@onready var attack_timer: Timer = Timer.new()


func _ready():
	reset_animation_state()
	target_position = get_random_point_within_radius()
	
	set_timer(idle_timer, idle_time, true, self._on_idle_timeout)
	set_timer(attack_timer, attack_cooldown, false, self._on_attack_timeout)
	
	animation_tree.active = true

# Método para obter o atributo principal
func get_main_stat() -> int:
	return main_stat

func reset_attack_cooldown() -> void:
	# Verifica se existe um cooldown original armazenado
	if has_meta("original_cooldown"):
		var original_cooldown = get_meta("original_cooldown")
		attack_cooldown = original_cooldown
		remove_meta("original_cooldown")
		
		# Atualiza o timer e a animação
		attack_timer.wait_time = attack_cooldown
		update_animation_speed()

func get_weapon_damage() -> int:
	# Verifica se tem arma equipada
	if "Weapons" in equipment_slots and equipment_slots["Weapons"] != null:
		return equipment_slots["Weapons"].damage
	return 1  # Dano padrão se não tiver arma

func reset_attack():
	is_attacking = false
	animation_tree.set("parameters/TimeScale/scale", 1)
	
	# Após finalizar uma sequência de ataque, restaura o cooldown original
	reset_attack_cooldown()  # Chama o método que adicionamos ao Soldier_Base

func _physics_process(delta):
	if is_idle:
		return
	if current_target and is_instance_valid(current_target):
		update_animation_blend_position_to_target(current_target.global_position)
		return
	# Tolerância para verificar se alcançou o destino
	if global_position.distance_to(target_position) <= 10:  # Aumente a tolerância
		enter_idle_state()
	else:
		move_to_target(delta)

func set_timer(timer: Timer, time: float, one_shot: bool, callback: Callable):
	timer.wait_time = time
	timer.one_shot = one_shot
	timer.timeout.connect(callback)
	add_child(timer)

func update_animation_blend_position(direction: Vector2):
	# Verifica se a direção mudou significativamente antes de atualizar
	if direction.length() > 0.1:  # Tolerância maior para evitar oscilações
		var blend_position: Vector2
		if abs(direction.x) > abs(direction.y):
			blend_position = Vector2(sign(direction.x), 0)
		else:
			blend_position = Vector2(0, sign(direction.y))
		animation_tree.set("parameters/StateMachine/move/blend_position", blend_position)
		animation_tree.set("parameters/StateMachine/idle/blend_position", blend_position)

func move_to_target(_delta):
	if is_idle:
		return  # Não move enquanto está em idle
	# Calcula a direção para o destino
	var direction = (target_position - global_position).normalized()
	velocity = direction * move_speed
	# Move o soldado e verifica colisões
	var collision_info = move_and_slide()
	if collision_info or global_position.distance_to(target_position) <= 10:  # Colisão ou destino alcançado
		enter_idle_state()
	else:
		# Atualiza animações apenas se realmente estiver se movendo
		animation_tree.set("parameters/StateMachine/conditions/is_moving", true)
		animation_tree.set("parameters/StateMachine/conditions/idle", false)
		update_animation_blend_position(direction)

func enter_idle_state():
	if is_idle:  # Apenas entra em idle se não estiver já
		return
	velocity = Vector2.ZERO
	is_idle = true
	idle_timer.start()  # Inicia o timer para sair do estado idle
	reset_animation_state()
	
func _on_idle_timeout():
	if is_idle:
		is_idle = false
		target_position = get_random_point_within_radius()

func reset_animation_state():
	is_attacking = false
	animation_tree.set("parameters/StateMachine/conditions/is_moving", false)
	animation_tree.set("parameters/StateMachine/conditions/idle", true)
	animation_tree.set("parameters/StateMachine/conditions/shooting", false)
	animation_tree.set("parameters/TimeScale/scale", 1)  # Reseta a escala da animação

func _on_body_entered(body):
	print(body)
	if body.is_in_group("enemies"):
		mobs_in_range.append(body)
		if current_target == null:
			select_closest_target()

func _on_body_exited(body):
	if body in mobs_in_range:
		mobs_in_range.erase(body)
		if current_target == body:
			select_closest_target()

func select_closest_target():
	mobs_in_range = mobs_in_range.filter(is_instance_valid)
	if mobs_in_range.is_empty():
		current_target = null
		attack_timer.stop()
		reset_animation_state()
		reset_attack()
		target_position = get_random_point_within_radius()
		return
	var closest_target = null
	var closest_distance = INF
	for mob in mobs_in_range:
		if not is_instance_valid(mob):
			continue
		var distance = global_position.distance_to(mob.global_position)
		print(mob.global_position)
		if distance < closest_distance and is_target_in_range(mob):
			closest_distance = distance
			closest_target = mob
	current_target = closest_target
	if current_target and not is_attacking:
		attack_timer.start()

func is_target_in_range(target: CharacterBody2D) -> bool:
	if not is_instance_valid(target):
		return false
	return global_position.distance_to(target.global_position) <= attack_range

func update_animation_blend_position_to_target(target_position: Vector2):
	var direction = (target_position - global_position).normalized()
	var blend_position: Vector2
	if abs(direction.x) > abs(direction.y):
		blend_position = Vector2(sign(direction.x), 0)
	else:
		blend_position = Vector2(0, sign(direction.y))
	animation_tree.set("parameters/StateMachine/shoot/blend_position", blend_position)

func get_random_point_within_radius() -> Vector2:
	var angle = randf() * PI * 2
	var distance = randf() * movement_radius
	return to_global(Vector2.ZERO) + Vector2(cos(angle), sin(angle)) * distance

# Ajusta a velocidade da animação de ataque com base no cooldown
func update_animation_speed():
	if is_attacking:
		var attack_speed_multiplier = 1.0 / attack_cooldown
		animation_tree.set("parameters/TimeScale/scale", attack_speed_multiplier)
		return attack_speed_multiplier

func get_animation_duration(animation_name: String) -> float:
	var animation_player = $AnimationPlayer
	var attack_speed_multiplier = update_animation_speed()
	# Ajuste para o caminho correto do nó
	if animation_player and animation_player.has_animation(animation_name):
	# Tempo base da animação
		var base_duration = animation_player.get_animation(animation_name).length
		if base_duration == 0:
			return attack_cooldown  # Fallback para o cooldown
	# Multiplicador de velocidade (quanto mais rápido, menor a duração real)
		if attack_speed_multiplier > 0:
			var adjusted_duration = base_duration / attack_speed_multiplier
			return adjusted_duration
	return 0.0

func get_active_blend_animation() -> String:
	var blend_position = animation_tree.get("parameters/StateMachine/shoot/blend_position")
	var animations = {
		Vector2(0, -1): "shoot_up",
		Vector2(0, 1): "shoot_down",
		Vector2(-1, 0): "shoot_left",
		Vector2(1, 0): "shoot_right"
	}
	for pos in animations.keys():
		if blend_position == pos:
			return animations[pos]
	return ""

# Aplica ou remove modificadores de status
func apply_item_modifiers(item: Resource, apply: bool):
	var modifier = 1 if apply else -1
	for stat in item.stat_modifiers.keys():
		if stat in self:
			self[stat] += item.stat_modifiers[stat] * modifier
			
func get_current_target() -> Node2D:
	if current_target and is_instance_valid(current_target):
		return current_target
	return null
