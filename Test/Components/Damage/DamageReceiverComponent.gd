extends Node
class_name DamageReceiverComponent

# Sinais
signal damage_received(damage_packet)
signal status_effect_applied(type, duration)
signal fatal_hit_received(from_who)

# Referência para integração com sistema existente
@export var health_component_path: NodePath = "../HealthComponent"

# Resistências
@export_group("Resistances")
@export_range(0.0, 1.0) var physical_resistance: float = 0.0
@export_range(0.0, 1.0) var fire_resistance: float = 0.0
@export_range(0.0, 1.0) var ice_resistance: float = 0.0
@export_range(0.0, 1.0) var wind_resistance: float = 0.0
@export_range(0.0, 1.0) var electric_resistance: float = 0.0
@export_range(0.0, 1.0) var poison_resistance: float = 0.0
@export_range(0.0, 1.0) var bleed_resistance: float = 0.0
@export_range(0.0, 1.0) var magic_resistance: float = 0.0

# Vulnerabilidades (dano extra)
@export_group("Vulnerabilities")
@export_range(0.0, 1.0) var physical_vulnerability: float = 0.0
@export_range(0.0, 1.0) var fire_vulnerability: float = 0.0
@export_range(0.0, 1.0) var ice_vulnerability: float = 0.0
@export_range(0.0, 1.0) var wind_vulnerability: float = 0.0
@export_range(0.0, 1.0) var electric_vulnerability: float = 0.0
@export_range(0.0, 1.0) var poison_vulnerability: float = 0.0
@export_range(0.0, 1.0) var bleed_vulnerability: float = 0.0
@export_range(0.0, 1.0) var magic_vulnerability: float = 0.0

# Configurações adicionais
@export_group("Defense Settings")
@export var armor: float = 0.0  # Redução de dano físico
@export var magic_resist: float = 0.0  # Redução de dano mágico
@export var damage_reduction: float = 0.0  # Redução percentual geral de dano

# Status effects ativos
var active_status_effects = {}

# Referência ao componente de saúde
var health_component: Node
var owner_entity: Node

func _ready():
	owner_entity = get_parent()
	
	# Tenta obter o componente de saúde
	if has_node(health_component_path):
		health_component = get_node(health_component_path)
	
	# Configura o perfil de defesa nos metadados
	_setup_defense_profile()

# Configura o perfil de defesa nos metadados
func _setup_defense_profile():
	var defense_profile = DamageCalculator.DefenseProfile.new()
	
	# Configura resistências
	defense_profile.set_resistance(DamageCalculator.DamageType.PHYSICAL, physical_resistance)
	defense_profile.set_resistance(DamageCalculator.DamageType.FIRE, fire_resistance)
	defense_profile.set_resistance(DamageCalculator.DamageType.ICE, ice_resistance)
	defense_profile.set_resistance(DamageCalculator.DamageType.WIND, wind_resistance)
	defense_profile.set_resistance(DamageCalculator.DamageType.ELECTRIC, electric_resistance)
	defense_profile.set_resistance(DamageCalculator.DamageType.POISON, poison_resistance)
	defense_profile.set_resistance(DamageCalculator.DamageType.BLEED, bleed_resistance)
	defense_profile.set_resistance(DamageCalculator.DamageType.MAGIC, magic_resistance)
	
	# Configura vulnerabilidades
	defense_profile.set_vulnerability(DamageCalculator.DamageType.PHYSICAL, physical_vulnerability)
	defense_profile.set_vulnerability(DamageCalculator.DamageType.FIRE, fire_vulnerability)
	defense_profile.set_vulnerability(DamageCalculator.DamageType.ICE, ice_vulnerability)
	defense_profile.set_vulnerability(DamageCalculator.DamageType.WIND, wind_vulnerability)
	defense_profile.set_vulnerability(DamageCalculator.DamageType.ELECTRIC, electric_vulnerability)
	defense_profile.set_vulnerability(DamageCalculator.DamageType.POISON, poison_vulnerability)
	defense_profile.set_vulnerability(DamageCalculator.DamageType.BLEED, bleed_vulnerability)
	defense_profile.set_vulnerability(DamageCalculator.DamageType.MAGIC, magic_vulnerability)
	
	# Salva nos metadados
	owner_entity.set_meta("defense_profile", defense_profile)
	owner_entity.set_meta("armor", armor)
	owner_entity.set_meta("magic_resist", magic_resist)
	owner_entity.set_meta("damage_reduction", damage_reduction)

# Recebe dano e aplica resistências e vulnerabilidades
func receive_damage(damage_packet: DamageCalculator.DamagePacket) -> DamageCalculator.DamagePacket:
	# Obtém o perfil de defesa
	var defense_profile = owner_entity.get_meta("defense_profile")
	
	# Aplica o cálculo de dano com as resistências
	var final_damage = DamageCalculator.calculate_damage(damage_packet, defense_profile)
	
	# Exibe os números de dano se tiver o sistema habilitado
	EnhancedDamageNumbers.display_damage(final_damage, owner_entity.global_position - Vector2(0, 20))
	
	# Aplica o dano no componente de saúde existente
	if health_component and health_component.has_method("take_damage"):
		var total_damage = final_damage.get_total_damage()
		
		# Detecta qual é o maior tipo de dano para efeitos visuais
		var strongest_type = _get_strongest_damage_type(final_damage)
		
		# Aplica o dano usando o sistema existente
		health_component.take_damage(total_damage, damage_packet.is_critical, false)
		
		# Se a entidade morrer, emite sinal
		if health_component.current_health <= 0:
			emit_signal("fatal_hit_received", null)  # Poderíamos passar o atacante aqui se tivéssemos a referência
	
	# Emite sinal de dano recebido
	emit_signal("damage_received", final_damage)
	
	return final_damage

# Aplica um efeito de status
func apply_status_effect(status_type: int, damage_per_tick: int, duration: float, interval: float = 1.0) -> void:
	# Verifica se já tem este efeito ativo
	if active_status_effects.has(status_type):
		# Pega o timer existente
		var timer = active_status_effects[status_type]["timer"]
		# Reseta a duração
		timer.wait_time = duration
		timer.start()
	else:
		# Cria um novo efeito
		var effect_timer = Timer.new()
		effect_timer.wait_time = duration
		effect_timer.one_shot = true
		add_child(effect_timer)
		
		# Configura a remoção do efeito quando o tempo acabar
		effect_timer.timeout.connect(func(): _remove_status_effect(status_type))
		
		# Cria um timer para os tiques de dano
		var tick_timer = Timer.new()
		tick_timer.wait_time = interval
		tick_timer.one_shot = false
		add_child(tick_timer)
		
		# Conecta o tick de dano
		tick_timer.timeout.connect(func(): _apply_dot_damage(status_type, damage_per_tick))
		
		# Armazena as informações do efeito
		active_status_effects[status_type] = {
			"timer": effect_timer,
			"tick_timer": tick_timer,
			"damage": damage_per_tick,
			"duration": duration,
			"interval": interval
		}
		
		# Inicia os timers
		effect_timer.start()
		tick_timer.start()
		
		# Mostra texto de status
		EnhancedDamageNumbers.display_status_effect(status_type, owner_entity.global_position - Vector2(0, 30))
		
		# Emite sinal
		emit_signal("status_effect_applied", status_type, duration)

# Remove um efeito de status
func _remove_status_effect(status_type: int) -> void:
	if active_status_effects.has(status_type):
		# Para o timer de ticks
		active_status_effects[status_type]["tick_timer"].stop()
		active_status_effects[status_type]["tick_timer"].queue_free()
		
		# Remove o timer principal
		active_status_effects[status_type]["timer"].queue_free()
		
		# Remove do dicionário
		active_status_effects.erase(status_type)

# Aplica o dano de um tique de DoT
func _apply_dot_damage(status_type: int, damage: int) -> void:
	if health_component and health_component.has_method("take_damage") and active_status_effects.has(status_type):
		# Aplica o dano
		health_component.take_damage(damage, false, true)  # dot_damage=true
		
		# Mostra o número de dano
		EnhancedDamageNumbers.display_dot_damage(damage, status_type, owner_entity.global_position - Vector2(0, 15))

# Obtém o tipo de dano com maior valor em um pacote de dano
func _get_strongest_damage_type(damage_packet: DamageCalculator.DamagePacket) -> int:
	var strongest_type = DamageCalculator.DamageType.PHYSICAL
	var strongest_value = 0
	
	for damage_type in damage_packet.damage_values:
		var damage = damage_packet.damage_values[damage_type]
		if damage > strongest_value:
			strongest_value = damage
			strongest_type = damage_type
	
	return strongest_type

# Carrega um perfil de defesa predefinido
func load_defense_profile(profile_name: String) -> void:
	# Carrega um perfil predefinido baseado no nome
	match profile_name:
		"slime":
			physical_resistance = 0.3
			bleed_resistance = 0.8
			ice_vulnerability = 0.5
		"fire_elemental":
			fire_resistance = 1.0
			bleed_resistance = 1.0
			ice_vulnerability = 1.0
		"ice_elemental":
			ice_resistance = 1.0
			bleed_resistance = 1.0
			fire_vulnerability = 1.0
		"undead":
			poison_resistance = 1.0
			bleed_resistance = 1.0
			magic_vulnerability = 0.5
		"golem":
			physical_resistance = 0.7
			poison_resistance = 1.0
			bleed_resistance = 1.0
			electric_vulnerability = 0.8
		"plant":
			electric_resistance = 0.5
			ice_resistance = 0.3
			fire_vulnerability = 0.7
			poison_vulnerability = 0.4
		"ghost":
			physical_resistance = 0.8
			bleed_resistance = 1.0
			poison_resistance = 1.0
			magic_vulnerability = 0.7
		"dragon":
			physical_resistance = 0.4
			fire_resistance = 0.8
			poison_resistance = 0.5
			ice_vulnerability = 0.3
	
	# Atualiza o perfil nos metadados
	_setup_defense_profile()
