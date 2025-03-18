extends BaseProjectileStrategy
class_name DamageModifierStrategy

# Modificadores por tipo de dano (multiplicadores)
@export var physical_mod: float = 1.0
@export var fire_mod: float = 0.0
@export var ice_mod: float = 0.0
@export var wind_mod: float = 0.0
@export var electric_mod: float = 0.0
@export var poison_mod: float = 0.0
@export var bleed_mod: float = 0.0
@export var magic_mod: float = 0.0

# Duração dos efeitos DoT (0 = sem efeito)
@export var dot_duration: float = 0.0
@export var dot_interval: float = 1.0

func apply_upgrade(projectile: Node) -> void:
	print("DamageModifierStrategy.apply_upgrade chamado")
	print("  Valores: physical_mod:", physical_mod, "fire_mod:", fire_mod)
	# Verifica se o projétil já tem um componente de DamageInfo
	if not projectile.has_node("DamageInfo"):
		var damage_info = Node.new()
		damage_info.name = "DamageInfo"
		damage_info.set_meta("damage_types", {})
		projectile.add_child(damage_info)
	
	var damage_info = projectile.get_node("DamageInfo")
	var damage_types = damage_info.get_meta("damage_types")
	
	# Calcula o dano base do projétil
	var base_damage = projectile.damage
	
	# Aplica modificadores para cada tipo de dano
	if physical_mod > 0:
		damage_types[DamageCalculator.DamageType.PHYSICAL] = int(base_damage * physical_mod)
	
	if fire_mod > 0:
		damage_types[DamageCalculator.DamageType.FIRE] = int(base_damage * fire_mod)
	
	if ice_mod > 0:
		damage_types[DamageCalculator.DamageType.ICE] = int(base_damage * ice_mod)
	
	if wind_mod > 0:
		damage_types[DamageCalculator.DamageType.WIND] = int(base_damage * wind_mod)
	
	if electric_mod > 0:
		damage_types[DamageCalculator.DamageType.ELECTRIC] = int(base_damage * electric_mod)
	
	if poison_mod > 0:
		damage_types[DamageCalculator.DamageType.POISON] = int(base_damage * poison_mod)
	
	if bleed_mod > 0:
		damage_types[DamageCalculator.DamageType.BLEED] = int(base_damage * bleed_mod)
	
	if magic_mod > 0:
		damage_types[DamageCalculator.DamageType.MAGIC] = int(base_damage * magic_mod)
	
	# Atualiza os metadados
	damage_info.set_meta("damage_types", damage_types)
	
	# Define propriedades DoT se aplicável
	if dot_duration > 0:
		damage_info.set_meta("dot_duration", dot_duration)
		damage_info.set_meta("dot_interval", dot_interval)
	
	# Recalcula o dano total somando todos os tipos
	var total_damage = 0
	for type_damage in damage_types.values():
		total_damage += type_damage
	
	# Atualiza o dano total do projétil (mantém compatibilidade)
	projectile.damage = total_damage
	
	print("Upgraded projectile with damage modifiers. Total damage: ", total_damage)
