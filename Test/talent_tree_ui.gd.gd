# Dicionário de descrições das habilidades
var talent_descriptions = {
	0: "Archer's basic attack. Starting point for all specializations.",
	1: "Increases basic attack damage by 15%.",
	2: "Increases tower range by 20%.",
	3: "Attacks ignore 10% of enemy armor.",
	4: "Arrows now pierce through 1 additional enemy.",
	5: "Arrows deal 30% more damage to enemies with health above 75%.",
	6: "Basic attacks apply 20% extra damage as fire, burning for 3s.",
	7: "Attacks reduce enemy speed by 30% for 2s.",
	8: "Frozen enemies explode upon death, dealing area damage.",
	9: "Arrows create an air blade that hits nearby enemies.",
	10: "Attacks on burning enemies have a 50% chance to spread fire to up to 2 nearby enemies.",
	11: "The tower fires 2 arrows simultaneously instead of 1.",
	12: "Arrows have a 30% chance to ricochet to another enemy.",
	13: "Every 10 attacks, the tower fires 5 arrows in an area.",
	14: "Attacks have a 10% chance to fire 3 arrows in a cone.",
	15: "Arrows explode on impact, dealing 50% of the damage in an area.",
	16: "Critical hits apply bleeding, causing 30% of base damage over 4s.",
	17: "Criticals create small explosions, dealing 100% damage in an area.",
	18: "Attacks have a 5% chance to fire a spectral arrow that passes through enemies.",
	19: "Fire damage increases as the enemy's health decreases.",
	20: "Arrows now pierce through up to 3 enemies.",
	21: "Enemies with less than 15% health receive double damage.",
	22: "Every 5 attacks, the tower fires a random elemental arrow (fire, ice, or physical).",
	23: "Arrows apply a debuff, increasing damage received by the enemy by 10% for 5s.",
	24: "Arrows apply poison, causing 30% of total damage over 4s.",
	25: "If 3 consecutive attacks hit the same enemy, the next hit deals 300% damage.",
	26: "Increases attack speed by 15%.",
	27: "Every 5 consecutive shots on the same enemy increases damage by 5%, stacking up to 5 times.",
	28: "Criticals now deal 100% extra damage.",
	29: "Arrows have a 15% chance to fire a gust of wind, pushing enemies back.",
	30: "Every 50 attacks, the tower fires a giant arrow that deals 500% damage in a straight line."
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
		"adds": ["Area"],
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
		"adds": ["Spectral", "Piercing"],
		"tags": ["Physical", "Spectral", "Piercing"]
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

# Função para obter a descrição formatada com tags coloridas
func get_formatted_description(talent_id: int) -> String:
	if not talent_id in talent_descriptions or not talent_id in talent_tag_info:
		return "Description not available."
		
	var base_description = talent_descriptions[talent_id]
	var tag_info = talent_tag_info[talent_id]
	
	var formatted_text = "[b]" + talent_names[talent_id] + "[/b]\n\n"
	formatted_text += base_description + "\n\n"
	
	# Adiciona informações sobre tags adicionadas
	if "adds" in tag_info and tag_info["adds"].size() > 0:
		formatted_text += "[color=#FFD700]Adds:[/color] "
		
		var colored_adds = []
		for tag in tag_info["adds"]:
			var color = tag_colors.get(tag, "#FFFFFF")
			colored_adds.append("[color=" + color + "][" + tag + "][/color]")
		
		formatted_text += colored_adds.join(", ") + "\n"
	
	# Adiciona informações sobre tags melhoradas
	if "enhances" in tag_info:
		var enhanced_tag = tag_info["enhances"]
		var color = tag_colors.get(enhanced_tag, "#FFFFFF")
		formatted_text += "[color=#00BFFF]Enhances:[/color] [color=" + color + "][" + enhanced_tag + "][/color]\n"
	
	# Adiciona informações sobre tags substituídas
	if "replaces" in tag_info:
		formatted_text += "[color=#FF6347]Replaces:[/color] " + tag_info["replaces"] + "\n"
	
	# Adiciona todas as tags
	if "tags" in tag_info and tag_info["tags"].size() > 0:
		formatted_text += "[color=#A0A0A0]Tags:[/color] "
		
		var colored_tags = []
		for tag in tag_info["tags"]:
			var color = tag_colors.get(tag, "#FFFFFF")
			colored_tags.append("[color=" + color + "][" + tag + "][/color]")
		
		formatted_text += colored_tags.join(", ")
	
	return formatted_text

# Função para exibir a descrição da habilidade no painel de informações
func show_skill_description(skill: SkillNode):
	if not skill.name.begins_with("talent_"):
		return
		
	var talent_id = int(skill.name.split("_")[1])
	var skill_description = $PanelContainer/HBoxContainer/InfoPanel/VBoxContainer/SkillDescription
	
	# Obtém a descrição formatada com tags coloridas
	var formatted_description = get_formatted_description(talent_id)
	
	# Adiciona informação sobre o status de desbloqueio
	if skill._level > 0:
		formatted_description += "\n\n[color=#50C878]✓ Unlocked[/color]"
	elif can_unlock_talent(talent_id) and total_talent_points > 0:
		formatted_description += "\n\n[color=#FFD700]Available for unlock[/color]"
	else:
		formatted_description += "\n\n[color=#FF6347]Requires prerequisites or talent points[/color]"
	
	# Define o texto formatado no RichTextLabel
	skill_description.bbcode_text = formatted_description
	
	# Define o ícone
	var skill_icon = $PanelContainer/HBoxContainer/InfoPanel/VBoxContainer/CenterContainer/SkillIcon
	if skill.icon:
		skill_icon.texture = skill.icon
