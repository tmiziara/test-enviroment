extends Node
class_name MovementControlComponent

# Sinais
signal stun_started(duration)
signal stun_ended()
signal knockback_started(direction, strength)
signal knockback_ended()

# Configurações
@export var knockback_resistance: float = 0.0  # 0.0 = sem resistência, 1.0 = imune
@export var stun_resistance: float = 0.0       # 0.0 = sem resistência, 1.0 = imune
@export var mass: float = 1.0                  # Massa para cálculos de física

# Estado
var is_stunned: bool = false
var is_being_knocked: bool = false
var active_forces: Dictionary = {}  # Forças ativas: {id: {força, duração_restante}}
var frozen_velocity: Vector2 = Vector2.ZERO  # Armazena velocidade durante stun

# Cache de referências
var entity: CharacterBody2D  # Entidade que possui este componente
var debuff_component: DebuffComponent  # Componente de debuff da entidade

func _ready():
	# Obtém referência para a entidade pai
	entity = get_parent() as CharacterBody2D
	if not entity:
		return
		
	# Encontra o componente de debuff, se existir
	debuff_component = entity.get_node_or_null("DebuffComponent")
	
	# Conecta ao processo físico da entidade
	set_physics_process(true)

func _physics_process(delta):
	# Não processa se a entidade não existe
	if not entity or not is_instance_valid(entity):
		return
		
	# Processa forças ativas
	process_active_forces(delta)
	
	# Se estiver stunado, trava a entidade no lugar
	if is_stunned:
		entity.velocity = Vector2.ZERO

# Aplica um stun na entidade
func apply_stun(duration: float, source = null) -> bool:
	# Verifica resistência a stun
	var effective_duration = duration * (1.0 - stun_resistance)
	if effective_duration <= 0:
		return false
		
	# Já está stunado? Atualiza a duração se for maior
	if is_stunned:
		var current_timer = get_node_or_null("StunTimer")
		if current_timer and current_timer.time_left < effective_duration:
			current_timer.wait_time = effective_duration
			current_timer.start()
		return true
	
	# Salva a velocidade atual para restaurar depois
	frozen_velocity = entity.velocity
	
	# Aplica o stun
	is_stunned = true
	entity.velocity = Vector2.ZERO
	
	# Adiciona o debuff visual, se disponível
	if debuff_component:
		debuff_component.add_debuff(GlobalDebuffSystem.DebuffType.STUNNED, effective_duration)
	
	# Configura timer para remover o stun
	var timer = Timer.new()
	timer.name = "StunTimer"
	timer.one_shot = true
	timer.wait_time = effective_duration
	add_child(timer)
	
	timer.timeout.connect(func():
		end_stun()
		timer.queue_free()
	)
	timer.start()
	
	# Emite sinal
	emit_signal("stun_started", effective_duration)
	
	# Tenta adicionar efeito visual de stun
	add_stun_visual_effect(effective_duration)
	
	return true

# Finaliza o stun
func end_stun():
	if not is_stunned:
		return
		
	is_stunned = false
	
	# Restaura a velocidade congelada
	if entity and is_instance_valid(entity):
		entity.velocity = frozen_velocity
	
	# Remove o debuff visual, se disponível
	if debuff_component:
		debuff_component.remove_debuff(GlobalDebuffSystem.DebuffType.STUNNED)
	
	# Emite sinal
	emit_signal("stun_ended")
	
	# Remove efeito visual de stun
	remove_stun_visual_effect()

# Aplica knockback na entidade
func apply_knockback(direction: Vector2, strength: float, duration: float = 0.5, source = null) -> bool:
	# Verifica resistência a knockback
	var effective_strength = strength * (1.0 - knockback_resistance)
	if effective_strength <= 0:
		return false
	
	# Normaliza a direção
	direction = direction.normalized()
	
	# Calcula força com base na massa
	var force = direction * effective_strength / mass
	
	# Adiciona à lista de forças ativas
	var force_id = "knockback_" + str(Time.get_ticks_msec())
	active_forces[force_id] = {
		"force": force,
		"duration": duration,
		"type": "knockback"
	}
	
	# Flag para controle
	is_being_knocked = true
	
	# Emite sinal
	emit_signal("knockback_started", direction, effective_strength)
	
	return true

# Aplica pull na entidade (similar ao knockback, mas na direção oposta)
func apply_pull(source_position: Vector2, strength: float, duration: float = 0.5, source = null) -> bool:
	# Calcula direção para o ponto de origem
	var direction = source_position - entity.global_position
	direction = direction.normalized()
	
	# Usa o mesmo sistema de knockback, mas com direção modificada
	return apply_knockback(direction, strength, duration, source)

# Aplica empurrão em uma direção específica
func apply_push(direction: Vector2, strength: float, duration: float = 0.5, source = null) -> bool:
	# Igual ao knockback, apenas mudando o nome para clareza
	return apply_knockback(direction, strength, duration, source)

# Processa todas as forças ativas
func process_active_forces(delta):
	var total_force = Vector2.ZERO
	var forces_to_remove = []
	
	# Processa cada força ativa
	for force_id in active_forces:
		var force_data = active_forces[force_id]
		
		# Atualiza duração
		force_data.duration -= delta
		
		# Força expirou?
		if force_data.duration <= 0:
			forces_to_remove.append(force_id)
			continue
		
		# Adiciona à força total
		total_force += force_data.force
	
	# Remove forças expiradas
	for force_id in forces_to_remove:
		if active_forces[force_id].type == "knockback" and is_being_knocked:
			is_being_knocked = false
			emit_signal("knockback_ended")
		active_forces.erase(force_id)
	
	# Aplica força total, se não estiver stunado
	if not is_stunned and total_force != Vector2.ZERO:
		entity.velocity += total_force
		# Opcional: limitar velocidade máxima
		# entity.velocity = entity.velocity.limit_length(max_speed)

# Adiciona efeito visual de stun
func add_stun_visual_effect(duration: float):
	# Remove efeito existente, se houver
	remove_stun_visual_effect()
	
	# Cria o nó visual
	var stun_effect = Node2D.new()
	stun_effect.name = "StunVisualEffect"
	entity.add_child(stun_effect)
	
	# Desenha stars ou símbolos de stun
	for i in range(3):
		var star = Sprite2D.new()
		star.position = Vector2(0, -20)  # Acima da entidade
		
		# Tenta carregar textura de stun ou cria sprite customizado
		var texture_path = "res://Test/Assets/Icons/debuffs/stun.png"
		if ResourceLoader.exists(texture_path):
			star.texture = load(texture_path)
		else:
			# Cria label com símbolo de estrela como fallback
			var label = Label.new()
			label.text = "✦"  # Símbolo de estrela
			label.add_theme_font_size_override("font_size", 24)
			label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.0))
			star.add_child(label)
		
		# Posição circular ao redor da cabeça
		var angle = i * TAU / 3  # distribui em círculo
		var radius = 15
		star.position += Vector2(cos(angle) * radius, sin(angle) * radius)
		
		# Animação
		var tween = stun_effect.create_tween().set_loops()
		tween.tween_property(star, "rotation", TAU, 2.0)
		
		stun_effect.add_child(star)
	
	# Timer para remover após a duração
	var timer = Timer.new()
	timer.wait_time = duration
	timer.one_shot = true
	stun_effect.add_child(timer)
	
	timer.timeout.connect(func():
		stun_effect.queue_free()
	)
	timer.start()

# Remove efeito visual de stun
func remove_stun_visual_effect():
	var existing_effect = entity.get_node_or_null("StunVisualEffect")
	if existing_effect:
		existing_effect.queue_free()
