extends ProjectileBase
class_name Arrow

# Sinais
signal on_hit(target, projectile)

# Propriedades específicas da flecha
var focused_shot_enabled: bool = false
var focused_shot_bonus: float = 0.0
var focused_shot_threshold: float = 0.0

func _ready():
	super._ready()

# Método chamado pelo Hurtbox quando a flecha atinge um alvo
func process_on_hit(target: Node) -> void:
	# Verifica se o Focused Shot está habilitado nesta flecha
	if focused_shot_enabled:
		apply_focused_shot(target)
	
	# Emite sinal que pode ser usado por outros sistemas
	emit_signal("on_hit", target, self)

# Função que implementa a lógica do Focused Shot
func apply_focused_shot(target: Node) -> void:
	# Armazena os valores originais de dano para restaurar depois
	var original_damage = damage
	var original_base_damage = 0
	var original_elemental_damage = {}
	
	if has_node("DmgCalculatorComponent"):
		var dmg_calc = get_node("DmgCalculatorComponent")
		if "base_damage" in dmg_calc:
			original_base_damage = dmg_calc.base_damage
		if "elemental_damage" in dmg_calc:
			original_elemental_damage = dmg_calc.elemental_damage.duplicate()
	
	# Verifica se o alvo tem um componente de saúde
	if target.has_node("HealthComponent"):
		var health_component = target.get_node("HealthComponent")
		
		# Verifica a porcentagem de vida
		var health_percent = 0.0
		if "current_health" in health_component and "max_health" in health_component:
			health_percent = float(health_component.current_health) / health_component.max_health
		else:
			print("ERRO: HealthComponent não tem current_health ou max_health")
			return
		
		# Se a vida estiver acima do limiar, aplica o bônus
		if health_percent >= focused_shot_threshold:
			# Aplica bônus temporário ao dano do projétil
			damage = int(original_damage * (1.0 + focused_shot_bonus))
			print("Focused Shot ativado! Dano aumentado de", original_damage, "para", damage, 
				  "(alvo com", health_percent * 100, "% de vida)")
			
			# Aplica bônus ao DmgCalculator se disponível
			if has_node("DmgCalculatorComponent"):
				var dmg_calc = get_node("DmgCalculatorComponent")
				
				# Aplica o bônus ao dano base
				if "base_damage" in dmg_calc:
					dmg_calc.base_damage = int(original_base_damage * (1.0 + focused_shot_bonus))
					print("Dano base do calculador aumentado de", original_base_damage, "para", dmg_calc.base_damage)
				
				# Também aplica o bônus a todos danos elementais
				if "elemental_damage" in dmg_calc:
					for element_type in original_elemental_damage.keys():
						if element_type in dmg_calc.elemental_damage:
							var orig_elem_dmg = original_elemental_damage[element_type]
							dmg_calc.elemental_damage[element_type] = int(orig_elem_dmg * (1.0 + focused_shot_bonus))
		
	# Agenda a restauração dos valores originais após o processamento do hit
	call_deferred("reset_focused_shot_bonuses", original_damage, original_base_damage, original_elemental_damage)

# Método para restaurar os valores originais após aplicar o bônus de Focused Shot
func reset_focused_shot_bonuses(orig_damage: int, orig_base_damage: int, orig_elemental_damage: Dictionary) -> void:
	# Restaura o dano original do projétil
	damage = orig_damage
	
	# Restaura os valores originais no DmgCalculator
	if has_node("DmgCalculatorComponent"):
		var dmg_calc = get_node("DmgCalculatorComponent")
		
		if "base_damage" in dmg_calc:
			dmg_calc.base_damage = orig_base_damage
		
		if "elemental_damage" in dmg_calc:
			for element_type in orig_elemental_damage.keys():
				if element_type in dmg_calc.elemental_damage:
					dmg_calc.elemental_damage[element_type] = orig_elemental_damage[element_type]
	
	print("Valores de dano restaurados após aplicação do Focused Shot")
