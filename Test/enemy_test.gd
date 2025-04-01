extends CharacterBody2D
class_name Enemy

@export var base_speed: float = 50.0            # Velocidade base de movimento
@export var acceleration: float = 500.0         # Aceleração para movimento suave
@export var tags: Array[String] = ["enemy"]     # Tags para interações com ataques

# Parâmetros para Context Steering
@export var debug_draw: bool = true             # Mostrar visualizações de debug
@export var avoidance_ray_count: int = 16  # Aumentado de 16 para 24
@export var avoidance_distance: float = 150.0  # Aumentado de 150.0 para 200.0
@export var target: Node2D

@onready var healthbar: ProgressBar = $Healthbar
@onready var damage_number_origin: Node2D = $DamageNumberOrigin
@onready var health_component: HealthComponent = $HealthComponent

var active_debuffs = {}                         # Dicionário para armazenar debuffs ativos
var context_map: ContextMap
var target_position: Vector2                    # Posição do alvo (mouse)
var move_speed: float
func _ready():
	healthbar.init_health(health_component.max_health)
	context_map = ContextMap.new()              # Cria o mapa de contexto
	# Configuração refinada do ContextMap
	context_map.interest_falloff_angle = 45.0
	context_map.danger_falloff_angle = 30.0  # Aumentado de 30.0 para 60.0
	context_map.danger_threshold = 0.8  # Reduzido de 0.8 para 0.6
	move_speed = base_speed

func _physics_process(delta):
	if target:
		target_position = target.global_position
	else:
		target_position = Vector2.ZERO
	# Atualiza a posição do alvo
	# Atualiza o Context Steering
	apply_context_steering(delta)
	# Força a chamada de _draw() para debug
	queue_redraw()

func apply_context_steering(delta):
	# Reseta o mapa de contexto
	context_map = ContextMap.new()
	context_map.interest_falloff_angle = 45.0
	context_map.danger_falloff_angle = 30.0  # Aumentado
	context_map.danger_threshold = 0.8  # Reduzido
	
	# Acessa o space_state para raycasts
	var space_state = get_world_2d().direct_space_state
	
	# Aplica comportamentos de steering
	SteeringBehavior.seek(context_map, global_position, target_position)
	SteeringBehavior.avoid(context_map, self, space_state, avoidance_ray_count, avoidance_distance)
	
	# Adicione esta linha para utilizar o comportamento de seguir paredes
	SteeringBehavior.wall_following(context_map, self, space_state)
	
	# Verifica se o inimigo está sob efeito de medo
	if "flee" in active_debuffs:
		SteeringBehavior.flee(context_map, global_position, target_position)
	
	# Processa os mapas de contexto
	context_map.normalize()
	context_map.apply_danger_mask()
	
	# Obtém a melhor direção
	var best_direction = context_map.get_best_direction()
	
	if target:# Aplica movimento com aceleração suave
		if best_direction != Vector2.ZERO:
			var target_velocity = best_direction * move_speed
			velocity = velocity.lerp(target_velocity, min(delta * acceleration / move_speed, 1.0))
		else:
			# Desacelera suavemente se não houver direção clara
			velocity = velocity.lerp(Vector2.ZERO, min(delta * acceleration / move_speed, 1.0))
	else:
		velocity = Vector2.ZERO
	move_and_slide()

func _on_health_component_died() -> void:
	# Desativa a física e colisão para evitar novos ataques
	set_physics_process(false)  # Para movimentação e física
	set_process(false)  # Impede outras lógicas (como IA)
	if has_node("BuffDisplayContainer"):
		$BuffDisplayContainer.clear_all_buffs()
	# Se houver um CollisionShape2D, desativa-o para evitar novas colisões
	if has_node("CollisionShape2D"):
		$CollisionShape2D.set_deferred("disabled", true)
	$AnimatedSprite2D.play("Death")  # Toca animação de morte
	# Aguarda a animação terminar antes de remover o inimigo
	await $AnimatedSprite2D.animation_finished
	queue_free()  # Remove o inimigo da cena após a animação

func _on_health_component_health_changed(new_health: Variant, amount: int, is_crit: bool, damage_type: String = "") -> void:
	if not is_instance_valid(self) or not is_inside_tree():
		return
		
	# Não atualiza mais a health bar aqui, isso é feito diretamente no HealthComponent
	
	# Apenas mostra os números de dano
	if new_health > 0 and is_instance_valid(damage_number_origin):
		DamageNumbers.display_number(amount, damage_number_origin.global_position, is_crit, damage_type)
