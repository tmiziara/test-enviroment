extends BaseProjectileStrategy
class_name Talent_5

# Configurações
@export var damage_bonus_percent: float = 0.3  # 30% de dano adicional contra inimigos com vida alta
@export var health_threshold: float = 0.75     # Limiar de 75% da vida máxima
@export var talent_id: int = 5                 # ID do talento correspondente

# Nome amigável para o painel de debug
func get_strategy_name() -> String:
	return "FocusedShotStrategy"

func apply_upgrade(projectile: Node) -> void:
	print("Aplicando upgrade de Focused Shot - +", 
		  damage_bonus_percent * 100, "% de dano contra inimigos com mais de ", 
		  health_threshold * 100, "% de vida")
	
	# Verifica se o projétil tem o método configure_focused_shot
	if projectile.has_method("configure_focused_shot"):
		# Usa o novo método para configurar o Focused Shot
		projectile.configure_focused_shot(
			true,                   # Habilitar Focused Shot
			damage_bonus_percent,   # Bônus de dano (30%)
			health_threshold        # Limiar de vida (75%)
		)
	else:
		# Fallback para o método antigo de configuração via meta
		projectile.set_meta("focused_shot_enabled", true)
		projectile.set_meta("focused_shot_bonus", damage_bonus_percent)
		projectile.set_meta("focused_shot_threshold", health_threshold)
	
	# Adiciona uma tag para identificação
	if "tags" in projectile:
		if projectile.has_method("add_tag"):
			projectile.add_tag("focused_shot")
		elif not "focused_shot" in projectile.tags:
			projectile.tags.append("focused_shot")
	
	print("Focused Shot configurado com sucesso no projétil")

# Método auxiliar para ser chamado durante o cálculo de dano
static func apply_focused_shot_bonus(damage_package: Dictionary, shooter, target) -> Dictionary:
	# Verifica se o projétil tem o Focused Shot habilitado
	var is_enabled = false
	var damage_bonus_percent = 0.3
	var health_threshold = 0.75
	
	# Tenta obter as configurações de diferentes formas
	if shooter.has_method("get_meta"):
		is_enabled = shooter.get_meta("focused_shot_enabled", false)
		damage_bonus_percent = shooter.get_meta("focused_shot_bonus", 0.3)
		health_threshold = shooter.get_meta("focused_shot_threshold", 0.75)
	
	# Verifica se tem propriedades diretas (para o novo método)
	if "focused_shot_enabled" in shooter:
		is_enabled = shooter.focused_shot_enabled
		damage_bonus_percent = shooter.focused_shot_bonus
		health_threshold = shooter.focused_shot_threshold
	
	# Verifica se o projétil tem o Focused Shot habilitado
	if not is_enabled or not shooter or not target:
		return damage_package
	
	# Verifica se o alvo tem um componente de saúde
	if target.has_node("HealthComponent"):
		var health_component = target.get_node("HealthComponent")
		
		# Calcula a porcentagem de vida
		var health_percent = float(health_component.current_health) / health_component.max_health
		
		# Se a vida estiver acima do limiar, aplica o bônus de dano
		if health_percent >= health_threshold:
			print("Focused Shot ativado! Vida do alvo: ", health_percent * 100, "%")
			
			# Aumenta o dano físico
			if "physical_damage" in damage_package:
				var bonus_damage = int(damage_package["physical_damage"] * damage_bonus_percent)
				damage_package["physical_damage"] += bonus_damage
				print("Dano físico aumentado de ", 
					  damage_package["physical_damage"] - bonus_damage, 
					  " para ", damage_package["physical_damage"])
			
			# Aumenta o dano elemental
			if "elemental_damage" in damage_package:
				for element in damage_package["elemental_damage"]:
					var bonus_elem_damage = int(damage_package["elemental_damage"][element] * damage_bonus_percent)
					damage_package["elemental_damage"][element] += bonus_elem_damage
					print("Dano elemental ", element, " aumentado para ", 
						  damage_package["elemental_damage"][element])
	
	return damage_package
