extends Node
class_name DamageDealerComponent

# Sinais
signal critical_hit(target, damage)
signal status_applied(target, status_type, duration)

# Atributos de dano
@export var base_damage: int = 10
@export var crit_chance: float = 0.1
@export var crit_multiplier: float = 2.0

# Dano por tipo (percentuais do dano base)
@export_group("Damage Types")
@export_range(0.0, 2.0) var physical_mod: float = 1.0
@export_range(0.0, 2.0) var fire_mod: float = 0.0
@export_range(0.0, 2.0) var ice_mod: float = 0.0
@export_range(0.0, 2.0) var wind_mod: float = 0.0
@export_range(0.0, 2.0) var electric_mod: float = 0.0
@export_range(0.0, 2.0) var poison_mod: float = 0.0
@export_range(0.0, 2.0) var bleed_mod: float = 0.0
@export_range(0.0, 2.0) var magic_mod: float = 0.0

# Configurações de efeitos de status (DoT)
@export_group("Status Effects")
@export var dot_duration: float = 0.0
@export var dot_interval: float = 1.0
@export var dot_damage_percent: float = 0.2  # Percentual do dano base

# Valores de penetração de resistência
@export_group("Penetration")
@export_range(0.0, 1.0) var physical_pen: float = 0.0
@export_range(0.0, 1.0) var fire_pen: float = 0.0
@export_range(0.0, 1.0) var ice_pen: float = 0.0
@export_range(0.0, 1.0) var wind_pen: float = 0.0
@export_range(0.0, 1.0) var electric_pen: float = 0.0
@export_range(0.0, 1.0) var poison_pen: float = 0.0
@export_range(0.0, 1.0) var bleed_pen: float = 0.0
@export_range(0.0, 1.0) var magic_pen: float = 0.0

# Estratégias de dano carregadas
var damage_strategies: Array[DamageModifierStrategy] = []

# Referência ao dono deste componente
var owner_entity: Node

func _ready():
	owner_entity = get_parent()
	
	# Configura metadados para compatibilidade com sistema existente
	_setup_metadata()

# Configura os metadados no dono para usar com sistema existente
func _setup_metadata():
	if owner_entity:
		owner_entity.set_meta("base_damage", base_damage)
		owner_entity.set_meta("crit_chance", crit_chance)
		owner_entity.set_meta("crit_damage", crit_multiplier)
		
		# Configurar bônus elementais
		var elemental_bonuses = {}
		if fire_mod > 0: elemental_bonuses[DamageCalculator.DamageType.FIRE] = fire_mod * 100.0
		if ice_mod > 0: elemental_bonuses[DamageCalculator.DamageType.ICE] = ice_mod * 100.0
		if wind_mod > 0: elemental_bonuses[DamageCalculator.DamageType.WIND] = wind_mod * 100.0
		if electric_mod > 0: elemental_bonuses[DamageCalculator.DamageType.ELECTRIC] = electric_mod * 100.0
		if poison_mod > 0: elemental_bonuses[DamageCalculator.DamageType.POISON] = poison_mod * 100.0
		if bleed_mod > 0: elemental_bonuses[DamageCalculator.DamageType.BLEED] = bleed_mod * 100.0
		if magic_mod > 0: elemental_bonuses[DamageCalculator.DamageType.MAGIC] = magic_mod * 100.0
		
		owner_entity.set_meta("elemental_bonuses", elemental_bonuses)
		
		# Configurar penetrações
		var penetration = {}
		if physical_pen > 0: penetration[DamageCalculator.DamageType.PHYSICAL] = physical_pen
		if fire_pen > 0: penetration[DamageCalculator.DamageType.FIRE] = fire_pen
		if ice_pen > 0: penetration[DamageCalculator.DamageType.ICE] = ice_pen
		if wind_pen > 0: penetration[DamageCalculator.DamageType.WIND] = wind_pen
		if electric_pen > 0: penetration[DamageCalculator.DamageType.ELECTRIC] = electric_pen
		if poison_pen > 0: penetration[DamageCalculator.DamageType.POISON] = poison_pen
		if bleed_pen > 0: penetration[DamageCalculator.DamageType.BLEED] = bleed_pen
		if magic_pen > 0: penetration[DamageCalculator.DamageType.MAGIC] = magic_pen
		
		owner_entity.set_meta("penetration", penetration)

# Cria um pacote de dano com os atributos atuais
func create_damage_packet(is_critical: bool = false) -> DamageCalculator.DamagePacket:
	var packet = DamageCalculator.DamagePacket.new()
	packet.is_critical = is_critical
	packet.crit_multiplier = crit_multiplier
	
	# Adiciona dano de cada tipo
	if physical_mod > 0:
		packet.add_damage(DamageCalculator.DamageType.PHYSICAL, int(base_damage * physical_mod))
	if fire_mod > 0:
		packet.add_damage(DamageCalculator.DamageType.FIRE, int(base_damage * fire_mod))
	if ice_mod > 0:
		packet.add_damage(DamageCalculator.DamageType.ICE, int(base_damage * ice_mod))
	if wind_mod > 0:
		packet.add_damage(DamageCalculator.DamageType.WIND, int(base_damage * wind_mod))
	if electric_mod > 0:
		packet.add_damage(DamageCalculator.DamageType.ELECTRIC, int(base_damage * electric_mod))
	if poison_mod > 0:
		packet.add_damage(DamageCalculator.DamageType.POISON, int(base_damage * poison_mod))
	if bleed_mod > 0:
		packet.add_damage(DamageCalculator.DamageType.BLEED, int(base_damage * bleed_mod))
	if magic_mod > 0:
		packet.add_damage(DamageCalculator.DamageType.MAGIC, int(base_damage * magic_mod))
	
	# Aplica crítico se necessário
	if is_critical:
		packet.apply_critical_multiplier()
	
	return packet

# Aplica dano a um alvo
func deal_damage_to(target: Node) -> DamageCalculator.DamagePacket:
	# Verifica se o alvo tem o componente necessário
	if not target.has_node("DamageReceiverComponent"):
		push_warning("Alvo não possui um DamageReceiverComponent. Dano não aplicado.")
		return null
	
	var receiver = target.get_node("DamageReceiverComponent")
	
	# Determina se é um golpe crítico
	var is_critical = randf() < crit_chance
	
	# Cria o pacote de dano
	var damage_packet = create_damage_packet(is_critical)
	
	# Aplica o dano
	var final_damage = receiver.receive_damage(damage_packet)
	
	# Aplica efeitos de status (DoT) se configurado
	if dot_duration > 0:
		var strongest_type = get_strongest_elemental_type()
		if strongest_type != DamageCalculator.DamageType.PHYSICAL:
			var dot_damage = int(base_damage * dot_damage_percent)
			receiver.apply_status_effect(strongest_type, dot_damage, dot_duration, dot_interval)
			emit_signal("status_applied", target, strongest_type, dot_duration)
	
	# Emite sinal de crítico se aplicável
	if is_critical:
		emit_signal("critical_hit", target, final_damage.get_total_damage())
	
	return final_damage

# Adiciona uma estratégia de dano
func add_strategy(strategy: DamageModifierStrategy) -> void:
	damage_strategies.append(strategy)
	
	# Atualiza os modificadores baseado na estratégia
	physical_mod = strategy.physical_mod if strategy.physical_mod > 0 else physical_mod
	fire_mod = strategy.fire_mod if strategy.fire_mod > 0 else fire_mod
	ice_mod = strategy.ice_mod if strategy.ice_mod > 0 else ice_mod
	wind_mod = strategy.wind_mod if strategy.wind_mod > 0 else wind_mod
	electric_mod = strategy.electric_mod if strategy.electric_mod > 0 else electric_mod
	poison_mod = strategy.poison_mod if strategy.poison_mod > 0 else poison_mod
	bleed_mod = strategy.bleed_mod if strategy.bleed_mod > 0 else bleed_mod
	magic_mod = strategy.magic_mod if strategy.magic_mod > 0 else magic_mod
	
	# Atualiza DoT se configurado
	if strategy.dot_duration > 0:
		dot_duration = strategy.dot_duration
		dot_interval = strategy.dot_interval
	
	# Atualiza os metadados
	_setup_metadata()

# Remove todas as estratégias e reinicia para os valores padrão
func clear_strategies() -> void:
	damage_strategies.clear()
	
	# Volta para os valores padrão (podem ser configurados em _ready)
	physical_mod = 1.0
	fire_mod = 0.0
	ice_mod = 0.0
	wind_mod = 0.0
	electric_mod = 0.0
	poison_mod = 0.0
	bleed_mod = 0.0
	magic_mod = 0.0
	
	dot_duration = 0.0
	dot_interval = 1.0
	
	# Atualiza os metadados
	_setup_metadata()

# Obtém o tipo elemental com maior modificador
func get_strongest_elemental_type() -> int:
	var strongest_type = DamageCalculator.DamageType.PHYSICAL
	var strongest_mod = physical_mod
	
	if fire_mod > strongest_mod:
		strongest_mod = fire_mod
		strongest_type = DamageCalculator.DamageType.FIRE
	if ice_mod > strongest_mod:
		strongest_mod = ice_mod
		strongest_type = DamageCalculator.DamageType.ICE
	if wind_mod > strongest_mod:
		strongest_mod = wind_mod
		strongest_type = DamageCalculator.DamageType.WIND
	if electric_mod > strongest_mod:
		strongest_mod = electric_mod
		strongest_type = DamageCalculator.DamageType.ELECTRIC
	if poison_mod > strongest_mod:
		strongest_mod = poison_mod
		strongest_type = DamageCalculator.DamageType.POISON
	if bleed_mod > strongest_mod:
		strongest_mod = bleed_mod
		strongest_type = DamageCalculator.DamageType.BLEED
	if magic_mod > strongest_mod:
		strongest_mod = magic_mod
		strongest_type = DamageCalculator.DamageType.MAGIC
	
	return strongest_type
