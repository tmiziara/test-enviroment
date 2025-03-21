extends Control
class_name ArcherDebugPanel

# Referência ao arqueiro que será monitorado
var archer: Soldier_Base = null

var attack_target_color = Color(1.0, 0.2, 0.2, 0.7)  # Vermelho

# Elementos da UI
@onready var stats_container = $VBoxContainer/StatsContainer/StatsText
@onready var strategies_container = $VBoxContainer/StrategiesContainer/StrategiesList
@onready var damage_container = $VBoxContainer/DamageContainer/DamagesList

# Configuração de cores para diferentes tipos de dano
var damage_colors = {
	"physical": Color(1.0, 1.0, 1.0),    # Branco
	"fire": Color(1.0, 0.5, 0.0),        # Laranja
	"ice": Color(0.5, 0.8, 1.0),         # Azul claro
	"poison": Color(0.5, 0.8, 0.0),      # Verde
	"bleeding": Color(1.0, 0.2, 0.2),    # Vermelho
	"wind": Color(0.7, 1.0, 0.7),        # Verde claro
	"piercing": Color(0.2, 0.6, 1.0),    # Azul
	"critical": Color(1.0, 0.8, 0.0)     # Dourado
}

func _ready():
	# Configura a atualização a cada 0.5 segundos
	var timer = Timer.new()
	timer.wait_time = 0.5
	timer.one_shot = false
	timer.autostart = true
	timer.timeout.connect(_update_debug_info)
	add_child(timer)
	
	# Inicia com valores vazios
	stats_container.text = "Nenhum arqueiro encontrado"
	strategies_container.text = "Nenhuma estratégia encontrada"
	damage_container.text = "Nenhum dado de dano disponível"
	
	# Habilita o desenho personalizado para visualizar o range
	set_process(true)

func _process(_delta):
	# Força redesenhar para atualizar o círculo de range
	if is_instance_valid(archer):
		queue_redraw()

func set_archer(archer_ref):
	archer = archer_ref
	_update_debug_info()

func _update_debug_info():
	if not is_instance_valid(archer):
		stats_container.text = "Arqueiro não encontrado ou inválido"
		return
		
	_update_stats()
	_update_strategies()
	_update_damage_info()
	
	# Força redesenhar a visualização do range
	queue_redraw()

func _update_stats():
	var stats_text = "[center][color=#00AAFF][b]ESTATÍSTICAS BÁSICAS[/b][/color][/center]\n"
	stats_text += "[color=#AAFFAA]Main Stat:[/color] " + str(archer.main_stat) + " (" + archer.main_stat_type + ")\n"
	stats_text += "[color=#AAFFAA]Attack Range:[/color] " + str(archer.attack_range) + "\n"
	stats_text += "[color=#AAFFAA]Attack Cooldown:[/color] " + str(archer.attack_cooldown) + "s\n"
	stats_text += "[color=#AAFFAA]Move Speed:[/color] " + str(archer.move_speed) + "\n"
	stats_text += "[color=#AAFFAA]HP:[/color] " + str(archer.hp) + "\n"
	
	# Talentos
	stats_text += "\n[center][color=#00AAFF][b]TALENTOS[/b][/color][/center]\n"
	stats_text += "[color=#AAFFAA]Pontos de Talento:[/color] " + str(archer.talent_points) + "\n"
	stats_text += "[color=#AAFFAA]Talentos Desbloqueados:[/color] "
	
	var unlocked_count = 0
	for talent_id in archer.unlocked_talents.keys():
		if archer.unlocked_talents[talent_id]:
			stats_text += "[color=#FFD700]" + str(talent_id) + "[/color], "
			unlocked_count += 1
	
	if unlocked_count == 0:
		stats_text += "Nenhum"
	
	stats_container.text = stats_text

func _update_strategies():
	var strategies_text = "[center][color=#00AAFF][b]ESTRATÉGIAS APLICADAS[/b][/color][/center]\n"
	
	if archer.attack_upgrades.size() == 0:
		strategies_text += "Nenhuma estratégia ativa no momento"
	else:
		for i in range(archer.attack_upgrades.size()):
			var strategy = archer.attack_upgrades[i]
			strategies_text += "[color=#FFD700]" + str(i+1) + ".[/color] "
			
			if strategy:
				# Tenta obter o nome da classe da estratégia de forma segura
				var strategy_class_name = "Strategy"
				
				# Verifica primeiro se existe o método personalizado get_strategy_name
				if strategy.has_method("get_strategy_name"):
					strategy_class_name = strategy.get_strategy_name()
				# Depois tenta obter do script
				elif strategy.get_script() != null:
					if strategy.get_script().get_path():
						var path = strategy.get_script().get_path()
						strategy_class_name = path.get_file().get_basename()
				
				strategies_text += "[color=#AAFFAA]" + strategy_class_name + "[/color]"
				
				# Tenta extrair propriedades importantes da estratégia
				strategies_text += _get_strategy_details(strategy)
			else:
				strategies_text += "Estratégia inválida"
				
			strategies_text += "\n"
	
	strategies_container.text = strategies_text

func _get_strategy_details(strategy) -> String:
	var details = ""
	
	# Tenta acessar propriedades comuns de estratégias
	if strategy is Object:
		# Lista para armazenar as propriedades encontradas
		var properties = []
		
		# Verifica se as propriedades existem com verificação de segurança
		var property_checks = [
			["damage_multiplier", "dmg: x"],
			["arrow_count", "arrows: "],
			["fire_damage", "fire: +"],
			["dot_damage_per_tick", "DoT: ", "/tick"],
			["dot_duration", "duration: ", "s"],
			["fire_damage_multiplier", "fire mult: x"],
			["dmg_bonus", "dmg: +"]
		]
		
		# Verifica crit_bonus com cuidado especial (precisa de multiplicação)
		if strategy.get("crit_bonus") != null:
			var crit_value = strategy.crit_bonus
			if typeof(crit_value) == TYPE_FLOAT or typeof(crit_value) == TYPE_INT:
				properties.append("crit: +" + str(crit_value * 100) + "%")
		
		# Verifica as outras propriedades
		for check in property_checks:
			var prop_name = check[0]
			var prefix = check[1]
			var suffix = ""
			if check.size() > 2:
				suffix = check[2]
			
			if strategy.get(prop_name) != null:
				properties.append(prefix + str(strategy.get(prop_name)) + suffix)
		
		# Adiciona as propriedades encontradas se houver alguma
		if properties.size() > 0:
			details += " [" + ", ".join(properties) + "]"
	
	return details

func _update_damage_info():
	var damage_text = "[center][color=#00AAFF][b]DANO E MODIFICADORES[/b][/color][/center]\n"
	
	# Dano base
	var weapon_damage = 1
	var main_stat_value = 0
	var main_stat_mult = 0.5 # Multiplicador padrão
	
	if archer.has_method("get_weapon_damage"):
		weapon_damage = archer.get_weapon_damage()
	
	if "main_stat" in archer:
		main_stat_value = archer.main_stat
	
	var base_damage = weapon_damage + main_stat_value * main_stat_mult
	damage_text += "[color=#FFFFFF]Dano Base:[/color] " + str(base_damage) + " ("
	damage_text += str(weapon_damage) + " arma + "
	damage_text += str(main_stat_value) + " x " + str(main_stat_mult) + " atributo)\n"
	
	# Chance de crítico
	var crit_chance = 0.1  # Valor padrão
	if "crit_chance" in archer:
		crit_chance = archer.crit_chance
	damage_text += "[color=#FFD700]Chance Crítico:[/color] " + str(crit_chance * 100) + "%\n"
	
	# Multiplicador de crítico
	var crit_multiplier = 2.0  # Valor padrão
	if "crit_multiplier" in archer:
		crit_multiplier = archer.crit_multiplier
	damage_text += "[color=#FFD700]Multiplicador Crítico:[/color] x" + str(crit_multiplier) + "\n"
	
	# DPS estimado
	var attack_speed = 1.0 / archer.attack_cooldown
	var crit_dps_contribution = base_damage * crit_chance * (crit_multiplier - 1)
	var estimated_dps = (base_damage + crit_dps_contribution) * attack_speed
	damage_text += "[color=#FF8800]DPS Estimado:[/color] " + str(snapped(estimated_dps, 0.1)) + " (sem contar DoT)\n"
	
	# Dano por flecha
	damage_text += "\n[center][color=#00AAFF][b]DANO ESTIMADO POR FLECHA[/b][/color][/center]\n"
	
	# Tenta carregar a cena da flecha de forma segura
	var arrow_scene = null
	var arrow_path = "res://Test/Projectiles/Archer/Arrow.tscn"
	
	if ResourceLoader.exists(arrow_path):
		arrow_scene = load(arrow_path)
	
	if arrow_scene:
		var temp_arrow = arrow_scene.instantiate()
		
		# Configuração básica com verificações de segurança
		temp_arrow.damage = weapon_damage
		
		# Verifica se a flecha tem calculador de dano
		if temp_arrow.has_node("DmgCalculatorComponent"):
			var dmg_calc = temp_arrow.get_node("DmgCalculatorComponent")
			dmg_calc.main_stat = main_stat_value
			dmg_calc.base_damage = weapon_damage
		
		# Lista para armazenar efeitos das estratégias
		var strategy_effects = []
		
		# Tenta aplicar cada estratégia
		for strategy in archer.attack_upgrades:
			if not strategy:
				continue
				
			var effect_text = ""
			var original_damage = temp_arrow.damage
			
			# Tenta extrair nome da estratégia com segurança
			var strat_name = "Strategy"
			if strategy.has_method("get_strategy_name"):
				strat_name = strategy.get_strategy_name()
			elif strategy.get_script():
				if strategy.get_script().resource_path:
					var file_name = strategy.get_script().resource_path.get_file()
					strat_name = file_name.get_basename()
			
			# Casos especiais para certas estratégias
			if strategy.get("arrow_count") != null and strategy.get("damage_per_arrow") != null:
				# Parece ser uma estratégia de chuva de flechas
				effect_text = "[color=#FF9900]Chuva de Flechas:[/color] "
				effect_text += str(strategy.arrow_count) + " flechas de " + str(strategy.damage_per_arrow) + " dano"
			else:
				# Para outras estratégias, tentamos aplicar em uma flecha de teste
				var test_arrow = arrow_scene.instantiate()
				test_arrow.damage = weapon_damage
				
				if test_arrow.has_node("DmgCalculatorComponent"):
					var dmg_calc = test_arrow.get_node("DmgCalculatorComponent")
					dmg_calc.main_stat = main_stat_value
					dmg_calc.base_damage = weapon_damage
				
				# Tenta aplicar a estratégia com tratamento de erro
				if strategy.has_method("apply_upgrade"):
					# Aplicação direta em vez de deferred para evitar await
					strategy.apply_upgrade(test_arrow)
					
					# Formata o texto de efeito
					effect_text = "[color=#AAFFAA]" + strat_name + ":[/color] "
					
					# Compara dano antes e depois
					if test_arrow.damage != original_damage:
						effect_text += "Dano " + str(original_damage) + " → " + str(test_arrow.damage)
					
					# Verifica tags adicionadas
					if test_arrow.get("tags") != null:
						if test_arrow.tags.size() > 0:
							effect_text += ", Tags: " + ", ".join(test_arrow.tags)
					
					# Verifica dano elemental
					if test_arrow.has_node("DmgCalculatorComponent"):
						var calc = test_arrow.get_node("DmgCalculatorComponent")
						
						# Verifica dano elemental
						if calc.get("elemental_damage") != null:
							if not calc.elemental_damage.is_empty():
								effect_text += ", [color=#FF5500]Elemental:[/color] "
								var elem_text = []
								for elem_type in calc.elemental_damage:
									# Aplica cor baseada no tipo de dano
									var color_code = "#FFFFFF"  # Branco (padrão)
									if elem_type in damage_colors:
										color_code = damage_colors[elem_type].to_html()
									else:
										# Cores para elementos não mapeados
										match elem_type:
											"fire": color_code = "#FF5500"
											"ice": color_code = "#00AAFF"
											"poison": color_code = "#77FF00"
											_: color_code = "#FFFFFF"
									
									elem_text.append("[color=" + color_code + "]" + elem_type + " " + str(calc.elemental_damage[elem_type]) + "[/color]")
								effect_text += ", ".join(elem_text)
						
						# Verifica efeitos DoT
						if calc.get("dot_effects") != null:
							if calc.dot_effects.size() > 0:
								effect_text += ", [color=#FFA500]DoT:[/color] "
								var dot_text = []
								for dot in calc.dot_effects:
									var dot_type = dot.get("type", "generic")
									var dot_damage = dot.get("damage", 0)
									var dot_duration = dot.get("duration", 0)
									var dot_interval = dot.get("interval", 1.0)
									
									# Aplica cor baseada no tipo de DoT
									var color_code = "#FFFFFF"  # Branco (padrão)
									if dot_type in damage_colors:
										color_code = damage_colors[dot_type].to_html()
									else:
										# Cores para tipos não mapeados
										match dot_type:
											"fire": color_code = "#FF5500"
											"ice": color_code = "#00AAFF"
											"poison": color_code = "#77FF00"
											_: color_code = "#FFFFFF"
									
									# Calcula dano total estimado
									var ticks = dot_duration / dot_interval
									var total_dot_damage = dot_damage * ticks
									
									dot_text.append("[color=" + color_code + "]" + 
										dot_type + " " + str(dot_damage) + "/tick" +
										" (" + str(total_dot_damage) + " total)" +
										"[/color]")
								effect_text += ", ".join(dot_text)
				
				# Limpa a flecha de teste
				if is_instance_valid(test_arrow):
					test_arrow.queue_free()
			
			# Adiciona o efeito à lista se tiver algum
			if effect_text != "":
				strategy_effects.append(effect_text)
		
				# Adiciona os efeitos das estratégias ao texto
		if strategy_effects.size() > 0:
			damage_text += "\n".join(strategy_effects)
		else:
			damage_text += "[color=#AAAAAA]Sem modificações de estratégias[/color]"
		
		# Limpa a flecha temporária
		if is_instance_valid(temp_arrow):
			temp_arrow.queue_free()
	else:
		damage_text += "Não foi possível carregar a cena da flecha para análise"
	
	# Atualiza o texto no container
	damage_container.text = damage_text
