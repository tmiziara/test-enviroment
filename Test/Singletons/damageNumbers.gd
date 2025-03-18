extends Node

func display_number(value: int, position: Vector2, is_critical: bool = false, damage_type: String = ""):
	# Não exibe números para dano zero
	if value <= 0:
		return
		
	var number = Label.new()
	
	# Adiciona uma variação aleatória à posição para evitar sobreposição
	var random_offset = Vector2(
		randf_range(-15, 15),  # Variação horizontal aleatória
		randf_range(-10, 5)    # Variação vertical aleatória
	)
	
	number.global_position = position + random_offset
	
	# Adiciona símbolos baseados no tipo de dano
	var prefix = ""
	if damage_type == "fire":
		prefix = "🔥 "  # Emoji de fogo
	elif damage_type == "ice":
		prefix = "❄️ "  # Emoji de gelo
	elif damage_type == "poison":
		prefix = "☠️ "  # Emoji de veneno
	
	number.text = prefix + str(value)
	number.z_index = 5
	number.label_settings = LabelSettings.new()
	
	# Define a cor baseada no tipo de dano e status crítico
	var color = "#FFF"  # Cor padrão (branco)
	
	# Primeiro verifica o tipo de dano
	if damage_type == "fire":
		color = "#F72"  # Laranja avermelhado para fogo
	elif damage_type == "ice":
		color = "#7DF"  # Azul claro para gelo
	elif damage_type == "poison":
		color = "#7D2"  # Verde para veneno
	
	# Depois considera se é crítico - crítico tem prioridade
	if is_critical:
		color = "#F22"  # Vermelho para crítico
	
	number.label_settings.font_color = color
	number.label_settings.font_size = 18
	number.label_settings.outline_color = "#000"
	number.label_settings.outline_size = 1
	
	call_deferred("add_child", number)
	await number.resized
	number.pivot_offset = Vector2(number.size / 2)
	
	# Altura aleatória de subida para variação visual
	var rise_height = randf_range(20, 30)
	
	var tween = get_tree().create_tween()
	tween.set_parallel(true)
	tween.tween_property(number, "position:y", number.position.y - rise_height, 0.3).set_ease(Tween.EASE_OUT)
	tween.tween_property(number, "position:y", number.position.y, 0.6).set_ease(Tween.EASE_IN).set_delay(0.3)
	tween.tween_property(number, "scale", Vector2.ZERO, 0.25).set_ease(Tween.EASE_IN).set_delay(0.65)
	
	# Pequeno movimento horizontal aleatório
	var end_x = number.position.x + randf_range(-10, 10)
	tween.tween_property(number, "position:x", end_x, 0.9).set_ease(Tween.EASE_OUT)
	
	await tween.finished
	number.queue_free()
