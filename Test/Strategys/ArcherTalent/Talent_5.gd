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
	print("Aplicando upgrade de Focused Shot - +", damage_bonus_percent * 100, "% de dano contra inimigos com mais de", health_threshold * 100, "% de vida")
	
	# Adiciona metadados ao projétil
	projectile.set_meta("focused_shot_bonus", damage_bonus_percent)
	projectile.set_meta("focused_shot_threshold", health_threshold)
	
	# Adiciona uma tag para identificação
	if "tags" in projectile:
		if not "focused_shot" in projectile.tags:
			projectile.add_tag("focused_shot")
	
	# Conecta o sinal ao invés de substituir o método
	if projectile is Arrow and not projectile.is_connected("on_hit", Callable(self, "_focused_shot_logic")):
		projectile.connect("on_hit", Callable(self, "_focused_shot_logic").bind(projectile))

# Função separada para a lógica do Focused Shot
func _focused_shot_logic(target: Node, projectile: Node) -> void:
	if target.has_node("HealthComponent"):
		var health_component = target.get_node("HealthComponent")
		
		# Verifica a porcentagem de vida
		var health_percent = 0.0
		if health_component.has_method("get_health_percent"):
			health_percent = health_component.get_health_percent()
		else:
			health_percent = float(health_component.current_health) / health_component.max_health
		
		# Se a vida estiver acima do limiar, aplica o bônus
		if health_percent >= health_threshold:
			# Aumenta o dano temporariamente para este impacto
			if "damage" in projectile:
				var original_damage = projectile.damage
				projectile.damage = int(original_damage * (1.0 + damage_bonus_percent))
				print("Focused Shot ativado! Dano aumentado de", original_damage, "para", projectile.damage, 
					  "(alvo com", health_percent * 100, "% de vida)")
			
			# Também aplica o bônus ao DmgCalculatorComponent se disponível
			if projectile.has_node("DmgCalculatorComponent"):
				var dmg_calc = projectile.get_node("DmgCalculatorComponent")
				
				if "base_damage" in dmg_calc:
					var original_base_damage = dmg_calc.base_damage
					dmg_calc.base_damage = int(original_base_damage * (1.0 + damage_bonus_percent))
