extends Control

# Pontos de talento disponíveis
var total_talent_points: int = 10

# Conexões entre talentos (pré-requisitos)
var talent_connections = {
	# Basic Attack (0) é o nó inicial e permite desbloquear vários caminhos
	0: [1, 6, 11],  # Basic Attack permite desbloquear Precise Aim, Double Shot e Arrow Rain
	
	# Basic Path
	1: [2],          # Precise Aim → Enhanced Range
	2: [3, 1],          # Enhanced Range → Sharp Arrows
	3: [4, 2, 16],       # Sharp Arrows → Piercing Shot, Focused Shot
	4: [5],          # Piercing Shot → Flaming Arrows
	# Elemental Path
	6: [19, 7],          # Flaming Arrows → Frost Arrows
	7: [6, 8, 9],       # Frost Arrows → Freezing Explosion, Cutting Winds
	9: [10, 7, 21],         # Cutting Winds → Rain of Ashes
	10: [8, 9],         # Cutting Winds → Rain of Ashes
	# Archery Path
	11: [12],        # Double Shot → Chain Shot
	12: [26, 13],        # Double Shot → Chain Shot
	13: [14, 15],    # Arrow Rain → Arrow Storm, Arrow Explosion
	
	# Special Arrows
	16: [3, 17],    # Serrated Arrows → Explosive Arrows, Ghost Bow
	17: [18, 16],        # Explosive Arrows → Burning Flames
	18: [20, 19, 29, 17],        # Explosive Arrows → Burning Flames
	19: [6, 18],        # Explosive Arrows → Burning Flames
	
	# Precision Path
	21: [9, 22],        # Explosive Arrows → Burning Flames
	22: [21, 23],        # Chaos Arrows → Prey Marker
	23: [25, 24, 22],        # Prey Marker → Poisoned Shot
	25: [27, 23],        # Explosive Arrows → Burning Flames
	# Damage Path
	26: [12, 27],        # Chain Shot → Intensive Training
	27: [25, 28, 26],        # Merciless Shot → Enhanced Damage
	28: [29, 27, 30],        # Enhanced Damage → Supreme Shot
	29: [18, 28]         # Intensive Training → Wind Force
}

# Dicionário para armazenar o status dos talentos
var talent_status = {}

# Referências da UI
@onready var talent_points_label = $BackgroundPanel/MainLayout/InfoPanel/InfoLayout/TalentPointsLabel
@onready var skill_icon = $BackgroundPanel/MainLayout/InfoPanel/InfoLayout/IconContainer/SkillIcon
@onready var skill_description = $BackgroundPanel/MainLayout/InfoPanel/InfoLayout/SkillDescription
@onready var unlock_button = $BackgroundPanel/MainLayout/InfoPanel/InfoLayout/ButtonContainer/UnlockButton

# Referência para o nó atualmente selecionado
var selected_skill_node: SkillNode = null
var archer = null  # Referência ao arqueiro

signal tree_closed  # Adicione esta linha

func _ready():
	# Conecta o botão de desbloqueio se ainda não estiver conectado
	if not unlock_button.is_connected("pressed", _on_unlock_button_pressed):
		unlock_button.connect("pressed", _on_unlock_button_pressed)
	
	# Conecta os botões de debug
	$DebugTools/AddPointsButton.connect("pressed", _on_add_points_button_pressed)
	$DebugTools/ResetTreeButton.connect("pressed", _on_reset_tree_button_pressed)
	_add_close_button()
	_setup_ui()
	_initialize_talent_status()
	_activate_starter_skill()
	_update_connection_colors()
	_update_ui()

func _add_close_button():
	var close_button = Button.new()
	close_button.text = "X"
	close_button.position = Vector2(size.x - 40, 10)
	close_button.size = Vector2(30, 30)
	close_button.connect("pressed", Callable(self, "_on_close_button_pressed"))
	add_child(close_button)

func _on_close_button_pressed():
	# Emite o sinal antes de fechar
	emit_signal("tree_closed")
	queue_free()

func _setup_ui():
	$DebugTools/AddPointsButton.text = "Add Points"
	$DebugTools/ResetTreeButton.text = "Reset Tree"
	unlock_button.disabled = true

func initialize(unlocked_talents: Dictionary, points: int, archer_ref: Node):
	# Configura a referência ao arqueiro
	archer = archer_ref
	
	# Define os pontos de talento
	total_talent_points = points
	
	# Inicializa o estado dos talentos (primeiro certifique-se de que a estrutura existe)
	_initialize_talent_status()
	
	# Marca os talentos desbloqueados
	for key in unlocked_talents.keys():
		var talent_id = int(key)
		if talent_id in talent_status and unlocked_talents[key]:
			talent_status[talent_id]["unlocked"] = true
			talent_status[talent_id]["available"] = true
	
	# Ativa o talento inicial sempre
	if 0 in talent_status:
		talent_status[0]["unlocked"] = true
		talent_status[0]["available"] = true
	
	# Atualiza talentos disponíveis
	update_available_talents()
	
	# Atualização visual (adiada para garantir que a árvore esteja pronta)
	call_deferred("_update_visuals_deferred")

func _update_visuals_deferred():
	# Espera um frame para garantir que os botões estejam prontos
	await get_tree().process_frame
	
	# Atualiza visualmente cada nó de talento para refletir seu estado
	var skill_buttons = get_tree().get_nodes_in_group("skill_buttons")
	for button in skill_buttons:
		if button.talent_id in talent_status:
			var status = talent_status[button.talent_id]
			
			# Se o talento estiver desbloqueado
			if status["unlocked"]:
				button.set_level(1)  # Usa o método próprio do botão para atualizar visual
			else:
				button.set_level(0)
				button.update_prereq_status(status["available"])
	
	# Atualiza as conexões
	_update_connection_lines()
	
	# Atualiza a UI
	_update_ui()

func get_unlocked_talents() -> Dictionary:
	var result = {}
	for talent_id in talent_status.keys():
		# Usa strings para as chaves para evitar conversões inconsistentes
		result[str(talent_id)] = talent_status[talent_id]["unlocked"]
	return result

func _initialize_talent_status():
	# Verifica se o dicionário já foi inicializado
	if talent_status.size() > 0:
		return
	
	# Valores padrão iniciais para garantir que a estrutura exista
	talent_status[0] = {
		"unlocked": false,
		"available": false
	}
	
	# Talentos padrão baseados na estrutura talento_connections
	for talent_id in talent_connections.keys():
		talent_status[talent_id] = {
			"unlocked": false,
			"available": false
		}
		
		# Também adiciona os talentos conectados
		for connected_id in talent_connections[talent_id]:
			talent_status[connected_id] = {
				"unlocked": false,
				"available": false
			}
	
	# Tenta buscar os botões somente se a árvore já estiver disponível
	if is_inside_tree():
		var skill_buttons = get_tree().get_nodes_in_group("skill_buttons")
		for button in skill_buttons:
			if button.talent_id != -1:
				talent_status[button.talent_id] = {
					"unlocked": false,
					"available": false
				}

func _activate_starter_skill():
	talent_status[0]["unlocked"] = true
	talent_status[0]["available"] = true
	
	# Encontra o nó do talento inicial e chama enable_connected_talents
	var skill_buttons = get_tree().get_nodes_in_group("skill_buttons")
	for button in skill_buttons:
		if button.talent_id == 0:
			button.set_level(1)
			enable_connected_talents(button)
			break

# Atualiza a cor das conexões e nós de talento
func _update_connection_colors():
	# Primeiro atualiza o status dos nós
	var skill_buttons = get_tree().get_nodes_in_group("skill_buttons")
	for button in skill_buttons:
		if button.talent_id in talent_status:
			var status = talent_status[button.talent_id]
			
			# Verifica se o botão tem um panel válido
			var panel = button.get_node_or_null("Panel")
			
			# Se o talento estiver desbloqueado
			if status["unlocked"]:
				button.modulate = Color(1.0, 1.0, 1.0)  # Normal
				if panel:
					panel.self_modulate = Color(0.2, 0.8, 0.2, 0.7)  # Verde mais intenso
				# Usa a função set_level do botão que já tem as verificações necessárias
				button.set_level(1)
			# Se estiver disponível
			elif status["available"]:
				button.modulate = Color(1.0, 1.0, 1.0)  # Normal
				if panel:
					panel.self_modulate = Color(0.8, 0.8, 0.2, 0.5)  # Amarelo
				button.update_prereq_status(true)
			# Se não estiver disponível
			else:
				button.modulate = Color(0.7, 0.7, 0.7)  # Escurecido
				if panel:
					panel.self_modulate = Color(0.3, 0.3, 0.3, 0.5)  # Cinza escuro
				button.update_prereq_status(false)
	
	# Depois atualiza as conexões
	_update_connection_lines()
# Nova função para atualizar as linhas de conexão
func _update_connection_lines():
	var connections_layer = $"BackgroundPanel/MainLayout/SkillTreeArea/SkillTreeScrollContainer/SkillsContainer/ConnectionsLayer"
	
	for connection in connections_layer.get_children():
		if connection is Line2D:
			var connection_name = connection.name
			
			# Tenta extrair os IDs dos nós conectados
			if connection_name.begins_with("connection_"):
				var parts = connection_name.split("_")
				if parts.size() >= 3:
					var id1 = int(parts[1])
					var id2 = int(parts[2])
					
					# Verifica se os IDs existem no dicionário talent_status
					if id1 in talent_status and id2 in talent_status:
						# Verifica se há conexão em qualquer direção
						var is_1_to_2 = id2 in talent_connections.get(id1, [])
						var is_2_to_1 = id1 in talent_connections.get(id2, [])
						
						# Se ambos estiverem desbloqueados
						if talent_status[id1]["unlocked"] and talent_status[id2]["unlocked"]:
							connection.default_color = Color(0.2, 0.8, 0.2)  # Verde
						# Se um estiver desbloqueado e houver conexão para o outro
						elif (talent_status[id1]["unlocked"] and is_1_to_2) or (talent_status[id2]["unlocked"] and is_2_to_1):
							connection.default_color = Color(0.8, 0.8, 0.2)  # Amarelo
						# Caso contrário
						else:
							connection.default_color = Color(0.223529, 0.223529, 0.223529)  # Cinza escuro
					else:
						# Caso algum ID não exista, mantém a cor padrão
						connection.default_color = Color(0.223529, 0.223529, 0.223529)  # Cinza escuro

func _update_ui():
	talent_points_label.text = "Talent Points: " + str(total_talent_points)
	
	if selected_skill_node:
		var talent_id = selected_skill_node.talent_id
		unlock_button.disabled = not (can_unlock_talent(talent_id) and total_talent_points > 0)

func can_unlock_talent(talent_id: int) -> bool:
	# Se já estiver desbloqueado, não pode ser desbloqueado novamente
	if talent_status[talent_id]["unlocked"]:
		return false
	
	# Se for o talento inicial, sempre pode ser desbloqueado
	if talent_id == 0:
		return true
	
	# Verifica se algum pré-requisito está desbloqueado
	var has_prereq_unlocked = false
	
	# Verifica conexões na estrutura talent_connections
	for prereq_id in talent_connections.keys():
		# Se este talento está na lista de conexões de algum talento
		if talent_id in talent_connections[prereq_id]:
			# Verifica se o talento predecessor foi desbloqueado
			if talent_status[prereq_id]["unlocked"]:
				has_prereq_unlocked = true
				break
	
	return has_prereq_unlocked

func unlock_talent(talent_id: int):
	if not can_unlock_talent(talent_id) and talent_id != 0:
		return false
	
	if total_talent_points <= 0 and talent_id != 0:
		return false
	
	# Desbloqueia o talento
	talent_status[talent_id]["unlocked"] = true
	talent_status[talent_id]["available"] = true
	
	# Gasta um ponto de talento
	if talent_id != 0:
		total_talent_points -= 1
	
	# Procura o nó de botão correspondente
	var skill_node = null
	var skill_buttons = get_tree().get_nodes_in_group("skill_buttons")
	for button in skill_buttons:
		if button.talent_id == talent_id:
			skill_node = button
			break
	
	# Aplica efeito visual de destaque
	if skill_node:
		# Cria um efeito pulsante
		var tween = create_tween()
		tween.tween_property(skill_node, "scale", Vector2(1.2, 1.2), 0.2)
		tween.tween_property(skill_node, "scale", Vector2(1.0, 1.0), 0.2)
		tween.tween_property(skill_node, "scale", Vector2(1.1, 1.1), 0.2)
		tween.tween_property(skill_node, "scale", Vector2(1.0, 1.0), 0.2)
		
		# Atualiza o nível do botão
		skill_node.set_level(1)
	
	# Atualiza as conexões visuais
	_update_connection_colors()
	
	# Atualiza a UI
	_update_ui()
	
	# Ativa os talentos conectados
	enable_connected_talents(skill_node)
	
	return true

func show_skill_description(skill: SkillNode):
	# Verifica se skill_description está configurado
	if not skill_description:
		print("Erro: skill_description não configurado")
		return
	
	selected_skill_node = skill
	
	# Verifica se o skill tem um talent_id válido
	var talent_id = skill.talent_id
	if talent_id == -1:
		print("Erro: talent_id não configurado")
		return
	
	# Define o ícone
	if skill_icon and skill.icon:
		skill_icon.texture = skill.icon
	
	# Obtém a descrição formatada
	var formatted_description = get_formatted_description(talent_id)
	
	# Adiciona informação sobre o status de desbloqueio
	if talent_status[talent_id]["unlocked"]:
		formatted_description += "\n\n[color=#50C878]✓ Unlocked[/color]"
	elif can_unlock_talent(talent_id) and total_talent_points > 0:
		formatted_description += "\n\n[color=#FFD700]Available for unlock[/color]"
	else:
		formatted_description += "\n\n[color=#FF6347]Requires prerequisites or talent points[/color]"
	
	# Define o texto formatado
	skill_description.bbcode_enabled = true
	skill_description.bbcode_text = formatted_description
	
	# Atualiza o estado do botão de desbloqueio
	unlock_button.disabled = not (can_unlock_talent(talent_id) and total_talent_points > 0 and not talent_status[talent_id]["unlocked"])

func get_formatted_description(talent_id: int) -> String:
	# Dicionário de descrições das habilidades
	var talent_descriptions = {
		0: "Archer's basic attack. Starting point for all specializations.",
		1: "Increases basic attack damage by 15%.",
		2: "Increases Archer range by 20%.",
		3: "Attacks ignore 10% of enemy armor.",
		4: "Arrows now pierce through 1 additional enemy.",
		5: "Arrows deal 30% more damage to enemies with health above 75%.",
		6: "Basic attacks apply 20% extra damage as fire instantly, plus a burning effect that deals 5% of base damage every 0.5s for 3s",
		7: "Attacks reduce enemy speed by 30% for 2s.",
		8: "Frozen enemies explode upon death, dealing area damage.",
		9: "Arrows create an air blade that hits nearby enemies.",
		10: "Attacks on burning enemies have a 50% chance to spread fire to up to 2 nearby enemies.",
		11: "The Archer fires 2 arrows simultaneously instead of 1.",
		12: "Arrows have a 30% chance to ricochet to another enemy.",
		13: "Every 10 attacks, the Archer fires 5 arrows in an area.",
		14: "When Arrow Rain hits an enemy, the arrows split into 2 smaller arrows (dealing 25% damage each) that seek nearby foes.",
		15: "Arrows explode on impact, dealing 50% of the damage in an area.",
		16: "Critical hits apply bleeding, causing 30% of base damage over 4s.",
		17: "Critical hits mark enemies for 4s. Marked enemies take +100% bonus critical damage from all attacks.",
		18: "Consecutive hits on the same enemy increase damage by +10% (max 5 stacks). Resets when switching targets.",
		19: "Fire damage increases as the enemy's health decreases.",
		20: "Arrows now pierce through up to 3 enemies.",
		21: "Enemies with less than 15% health receive double damage.",
		22: "Every 5 attacks, the Archer fires a random elemental arrow (fire, ice, or physical).",
		23: "Arrows apply a debuff, increasing damage received by the enemy by 10% for 5s.",
		24: "Arrows apply poison, causing 30% of total damage over 4s.",
		25: "If 3 consecutive attacks hit the same enemy, the next hit deals 300% damage.",
		26: "Increases attack speed by 15%.",
		27: "Every 5 consecutive shots on the same enemy increases damage by 5%, stacking up to 5 times.",
		28: "Criticals now deal 100% extra damage.",
		29: "Arrows have a 15% chance to fire a gust of wind, pushing enemies back.",
		30: "Every 50 attacks, the Archer fires a giant arrow that deals 500% damage in a straight line."
	}
	# Dicionário com informações sobre as tags
	var talent_tag_info = {
		0: {
			"tags": ["Physical"]
		},
		1: {
			"tags": ["Physical"]
		},
		2: {
			"tags": ["Physical"]
		},
		3: {
			"adds": ["Armor_Piercing"],
			"tags": ["Physical", "Armor_Piercing"]
		},
		4: {
			"adds": ["Piercing"],
			"tags": ["Physical", "Piercing"]
		},
		5: {
			"tags": ["Physical"]
		},
		6: {
			"adds": ["Fire", "DoT"],
			"tags": ["Physical", "Fire", "DoT"]
		},
		7: {
			"adds": ["Ice", "Slow"],
			"tags": ["Physical", "Ice", "Slow"]
		},
		8: {
			"adds": ["Area"],
			"tags": ["Ice", "Area"],
			"replaces": "Physical with Ice"
		},
		9: {
			"adds": ["Wind", "Area"],
			"tags": ["Physical", "Wind", "Area"]
		},
		10: {
			"adds": ["Area"],
			"tags": ["Fire", "DoT", "Area"],
			"replaces": "Physical with Fire"
		},
		11: {
			"tags": ["Physical"]
		},
		12: {
			"adds": ["Ricochet"],
			"tags": ["Physical", "Ricochet"]
		},
		13: {
			"adds": ["Area"],
			"tags": ["Physical", "Area"]
		},
		14: {
			"adds": ["Ricochet"],
			"tags": ["Physical", "Area"]
		},
		15: {
			"adds": ["Area"],
			"tags": ["Physical", "Area"]
		},
		16: {
			"adds": ["Bleeding", "DoT"],
			"tags": ["Physical", "Bleeding", "DoT"]
		},
		17: {
			"adds": ["Explosive", "Area"],
			"tags": ["Physical", "Explosive", "Area"]
		},
		18: {
			"adds": ["Stack"],
			"tags": ["Physical", "Stack"]
		},
		19: {
			"adds": ["Execute"],
			"tags": ["Fire", "Execute"],
			"replaces": "Physical with Fire"
		},
		20: {
			"enhances": "Piercing",
			"tags": ["Physical", "Piercing"]
		},
		21: {
			"adds": ["Execute"],
			"tags": ["Physical", "Execute"]
		},
		22: {
			"adds": ["Fire", "Ice"],
			"tags": ["Physical", "Fire", "Ice"]
		},
		23: {
			"adds": ["Debuff"],
			"tags": ["Physical", "Debuff"]
		},
		24: {
			"adds": ["Poison", "DoT"],
			"tags": ["Physical", "Poison", "DoT"]
		},
		25: {
			"adds": ["True Dmg"],
			"tags": ["Physical", "True Dmg"]
		},
		26: {
			"tags": ["Physical"]
		},
		27: {
			"adds": ["Stacking"],
			"tags": ["Physical", "Stacking"]
		},
		28: {
			"enhances": "Critical",
			"tags": ["Physical", "Critical"]
		},
		29: {
			"adds": ["Wind", "Knockback"],
			"tags": ["Physical", "Wind", "Knockback"]
		},
		30: {
			"adds": ["Piercing", "Ultimate"],
			"tags": ["Physical", "Piercing", "Ultimate"]
		}
	}

	# Cores para as diferentes tags
	var tag_colors = {
		# Tipos de dano
		"Physical": "#FFFFFF",  # Branco
		"Fire": "#FF5722",      # Vermelho-laranja
		"Ice": "#00BCD4",       # Ciano
		"Wind": "#64DD17",      # Verde claro
		"Poison": "#8BC34A",    # Verde
		"Bleeding": "#F44336",  # Vermelho
		"True Dmg": "#FFD700",  # Dourado
		
		# Efeitos
		"DoT": "#FB8C00",       # Laranja
		"Area": "#9C27B0",      # Roxo
		"Piercing": "#2196F3",  # Azul
		"Ricochet": "#03A9F4",  # Azul claro
		"Slow": "#B3E5FC",      # Azul muito claro
		"Knockback": "#CDDC39", # Lima
		"Stacking": "#FF9800",  # Laranja
		"Execute": "#D50000",   # Vermelho escuro
		"Debuff": "#7B1FA2",    # Roxo escuro
		
		# Especiais
		"Armor_Piercing": "#607D8B", # Azul acinzentado
		"Spectral": "#9E9E9E",       # Cinza
		"Explosive": "#FF9100",      # Laranja forte
		"Critical": "#FFC107",       # Âmbar
		"Ultimate": "#E91E63"        # Rosa
	}

	# Encontra o botão de talento correspondente
	var skill_buttons = get_tree().get_nodes_in_group("skill_buttons")
	var current_skill = null
	for button in skill_buttons:
		if button.talent_id == talent_id:
			current_skill = button
			break

	if not current_skill:
		return "Descrição não encontrada"

	# Verifica se há descrição disponível
	var base_description = talent_descriptions.get(talent_id, "Descrição não disponível.")
	var tag_info = talent_tag_info.get(talent_id, {})

	var formatted_text = "[b]" + current_skill.skill_name + "[/b]\n\n"
	formatted_text += base_description + "\n\n"

	# Adiciona informações sobre tags adicionadas
	if "adds" in tag_info and tag_info["adds"].size() > 0:
		formatted_text += "[color=#FFD700]Adds:[/color] "
		
		var colored_adds = []
		for tag in tag_info["adds"]:
			var color = tag_colors.get(tag, "#FFFFFF")
			colored_adds.append("[color=" + color + "][" + tag + "][/color]")
		
		formatted_text += ", ".join(colored_adds) + "\n"

	# Adiciona informações sobre tags melhoradas
	if "enhances" in tag_info:
		var enhanced_tag = tag_info["enhances"]
		var color = tag_colors.get(enhanced_tag, "#FFFFFF")
		formatted_text += "[color=#00BFFF]Enhances:[/color] [color=" + color + "][" + enhanced_tag + "][/color]\n"

	# Adiciona informações sobre tags substituídas
	if "replaces" in tag_info:
		formatted_text += "[color=#FF6347]Replaces:[/color] " + tag_info["replaces"] + "\n"

	# Adiciona uma linha em branco extra antes das tags
	formatted_text += "\n"  # <-- ADICIONE ESTA LINHA

	# Adiciona todas as tags
	if "tags" in tag_info and tag_info["tags"].size() > 0:
		formatted_text += "[color=#A0A0A0]Tags:[/color] "
		
		var colored_tags = []
		for tag in tag_info["tags"]:
			var color = tag_colors.get(tag, "#FFFFFF")
			colored_tags.append("[color=" + color + "][" + tag + "][/color]")
		
		formatted_text += ", ".join(colored_tags)

	return formatted_text

func _on_unlock_button_pressed():
	if selected_skill_node:
		var talent_id = selected_skill_node.talent_id
		
		if can_unlock_talent(talent_id) and total_talent_points > 0:
			# Desbloqueia o talento
			unlock_talent(talent_id)
			
			# Atualiza a visualização do botão
			selected_skill_node.set_level(1)
			
			# Atualiza as conexões visuais
			_update_connection_colors()
			
			# Atualiza a descrição
			show_skill_description(selected_skill_node)

func _on_add_points_button_pressed():
	total_talent_points += 5
	_update_ui()

func _on_reset_tree_button_pressed():
	# Reseta todos os talentos
	for talent_id in talent_status.keys():
		talent_status[talent_id] = {
			"unlocked": false,
			"available": false
		}
	
	# Reinicia os pontos de talento
	total_talent_points = 10
	
	# Reativa o talento inicial
	_activate_starter_skill()
	
	# Atualiza a UI
	_update_ui()
	
	# Reseta a escala de todos os botões
	var skill_buttons = get_tree().get_nodes_in_group("skill_buttons")
	for button in skill_buttons:
		button.scale = Vector2(1.0, 1.0)
		# Reseta o nível para 0 exceto o talento inicial
		if button.talent_id != 0:
			button.set_level(0)
	
	# Atualiza as conexões visuais
	_update_connection_colors()

# Ativa talentos conectados como disponíveis
func enable_connected_talents(skill: SkillNode):
	if not skill:
		return
		
	# Verifica se o talento tem conexões
	if skill.talent_id in talent_connections:
		var connected_talents = talent_connections[skill.talent_id]
		
		# Marca cada talento conectado como disponível
		for connected_id in connected_talents:
			if connected_id in talent_status:
				talent_status[connected_id]["available"] = true
				
				# Busca o nó do talento
				var skill_buttons = get_tree().get_nodes_in_group("skill_buttons")
				for button in skill_buttons:
					if button.talent_id == connected_id:
						# Atualiza visualmente o nó
						button.prerequisites_met = true
						button.update_prereq_status(true)

	# Redesenha as conexões para mostrar visualmente
	_update_connection_colors()

func update_available_talents():
		# Primeiro, marque todos os talentos como não disponíveis
	for talent_id in talent_status.keys():
		if not talent_status[talent_id]["unlocked"]:
			talent_status[talent_id]["available"] = false
	
	# Depois, marque como disponíveis os talentos conectados a talentos desbloqueados
	for talent_id in talent_status.keys():
		if talent_status[talent_id]["unlocked"]:
			# Se este talento está desbloqueado, marca suas conexões como disponíveis
			if talent_id in talent_connections:
				for connected_id in talent_connections[talent_id]:
					if connected_id in talent_status:
						talent_status[connected_id]["available"] = true
