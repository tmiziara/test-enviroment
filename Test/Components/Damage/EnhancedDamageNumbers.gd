extends Node
class_name EnhancedDamageNumbers

# Singleton para exibir números de dano
# Adicione esta classe como autoload em seu projeto

# Cores para cada tipo de dano
const DAMAGE_COLORS = {
	DamageCalculator.DamageType.PHYSICAL: Color(0.9, 0.9, 0.9),    # Branco/cinza
	DamageCalculator.DamageType.FIRE: Color(1.0, 0.5, 0.0),        # Laranja
	DamageCalculator.DamageType.ICE: Color(0.5, 0.8, 1.0),         # Azul claro
	DamageCalculator.DamageType.WIND: Color(0.7, 1.0, 0.7),        # Verde claro
	DamageCalculator.DamageType.ELECTRIC: Color(1.0, 1.0, 0.0),    # Amarelo
	DamageCalculator.DamageType.POISON: Color(0.5, 1.0, 0.0),      # Verde venenoso
	DamageCalculator.DamageType.BLEED: Color(1.0, 0.0, 0.0),       # Vermelho
	DamageCalculator.DamageType.MAGIC: Color(0.5, 0.0, 1.0),       # Roxo
}

# Nomes dos tipos de dano para exibição
const DAMAGE_TYPE_NAMES = {
	DamageCalculator.DamageType.PHYSICAL: "Físico",
	DamageCalculator.DamageType.FIRE: "Fogo",
	DamageCalculator.DamageType.ICE: "Gelo",
	DamageCalculator.DamageType.WIND: "Vento",
	DamageCalculator.DamageType.ELECTRIC: "Elétrico",
	DamageCalculator.DamageType.POISON: "Veneno",
	DamageCalculator.DamageType.BLEED: "Sangramento",
	DamageCalculator.DamageType.MAGIC: "Mágico",
}

# Singleton instance
static var instance: EnhancedDamageNumbers

func _ready():
	# Armazena a instância para acesso a partir de métodos estáticos
	instance = self

# Exibe números de dano para cada tipo - agora é uma interface estática para o método real
static func display_damage(damage_packet: DamageCalculator.DamagePacket, position: Vector2) -> void:
	if instance:
		instance._display_damage(damage_packet, position)

# Implementação real, não estática
func _display_damage(damage_packet: DamageCalculator.DamagePacket, position: Vector2) -> void:
	var offset_y = 0
	
	# Para cada tipo de dano
	for damage_type in damage_packet.damage_values.keys():
		var damage = damage_packet.damage_values[damage_type]
		if damage <= 0:
			continue
		
		# Cria o número de dano
		var number = Label.new()
		number.global_position = position + Vector2(0, offset_y)
		number.text = str(damage)
		
		# Define a cor baseada no tipo de dano
		var color = DAMAGE_COLORS[damage_type]
		
		# Torna a cor mais intensa para críticos e adiciona texto
		if damage_packet.is_critical:
			color = color.lightened(0.3)
			number.text += "!"
		
		# Aplica a cor e o sombreamento
		number.add_theme_color_override("font_color", color)
		
		# Adiciona um efeito de sombra para melhor visibilidade
		number.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.5))
		number.add_theme_constant_override("shadow_offset_x", 1)
		number.add_theme_constant_override("shadow_offset_y", 1)
		
		# Adiciona à cena
		get_tree().root.add_child(number)
		
		# Cria animação
		var tween = number.create_tween()
		tween.set_parallel(true)
		
		# Movimento para cima com um pouco de aleatoriedade
		var random_x = randf_range(-10, 10)
		tween.tween_property(number, "position", number.position + Vector2(random_x, -30), 0.5)
		
		# Fade out
		tween.tween_property(number, "modulate:a", 0, 0.5)
		
		# Escala para críticos
		if damage_packet.is_critical:
			tween.tween_property(number, "scale", Vector2(1.5, 1.5), 0.1)
			tween.tween_property(number, "scale", Vector2(1.0, 1.0), 0.2).set_delay(0.1)
		
		# Remove o número após a animação
		tween.tween_callback(number.queue_free).set_delay(0.5)
		
		# Incrementa o offset para o próximo número
		offset_y -= 15
	
	# Exibe o dano total para golpes com múltiplos tipos
	var total_types = 0
	for damage_type in damage_packet.damage_values.keys():
		if damage_packet.damage_values[damage_type] > 0:
			total_types += 1
	
	# Se houver mais de um tipo de dano, mostra o total
	if total_types > 1:
		var total_number = Label.new()
		total_number.global_position = position + Vector2(0, offset_y - 10)
		total_number.text = "Total: " + str(damage_packet.get_total_damage())
		
		# Estilo diferenciado para o total
		total_number.add_theme_font_size_override("font_size", 14)
		total_number.add_theme_color_override("font_color", Color(1, 1, 1))
		total_number.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.5))
		
		get_tree().root.add_child(total_number)
		
		# Animação para o total
		var tween = total_number.create_tween()
		tween.set_parallel(true)
		tween.tween_property(total_number, "position:y", total_number.position.y - 20, 0.7)
		tween.tween_property(total_number, "modulate:a", 0, 0.7)
		tween.tween_callback(total_number.queue_free).set_delay(0.7)

# Exibe efeito de texto para status aplicados - interface estática
static func display_status_effect(status_type: int, position: Vector2) -> void:
	if instance:
		instance._display_status_effect(status_type, position)

# Implementação real, não estática
func _display_status_effect(status_type: int, position: Vector2) -> void:
	var status_text = Label.new()
	status_text.global_position = position
	
	# Define o texto baseado no tipo
	match status_type:
		DamageCalculator.DamageType.FIRE:
			status_text.text = "QUEIMANDO"
		DamageCalculator.DamageType.POISON:
			status_text.text = "ENVENENADO"
		DamageCalculator.DamageType.BLEED:
			status_text.text = "SANGRANDO"
		DamageCalculator.DamageType.ICE:
			status_text.text = "CONGELADO"
		DamageCalculator.DamageType.ELECTRIC:
			status_text.text = "ELETRIFICADO"
		_:
			status_text.text = "EFEITO"
	
	# Define a cor baseada no tipo
	status_text.add_theme_color_override("font_color", DAMAGE_COLORS[status_type])
	status_text.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	
	# Adiciona à cena
	get_tree().root.add_child(status_text)
	
	# Animação para o texto de status
	var tween = status_text.create_tween()
	tween.set_parallel(true)
	
	# Movimento para cima suave
	tween.tween_property(status_text, "position:y", status_text.position.y - 40, 1.0)
	
	# Fade out
	tween.tween_property(status_text, "modulate:a", 0, 1.0)
	
	# Remove após a animação
	tween.tween_callback(status_text.queue_free).set_delay(1.0)

# Exibe dano adicional do DoT (dano ao longo do tempo) - interface estática
static func display_dot_damage(damage: int, damage_type: int, position: Vector2) -> void:
	if instance:
		instance._display_dot_damage(damage, damage_type, position)

# Implementação real, não estática
func _display_dot_damage(damage: int, damage_type: int, position: Vector2) -> void:
	var dot_text = Label.new()
	dot_text.global_position = position
	dot_text.text = str(damage)
	
	# Adiciona identificador do tipo de DoT
	match damage_type:
		DamageCalculator.DamageType.FIRE:
			dot_text.text += " 🔥"
		DamageCalculator.DamageType.POISON:
			dot_text.text += " ☠️"
		DamageCalculator.DamageType.BLEED:
			dot_text.text += " 🩸"
	
	# Define a cor e o estilo
	dot_text.add_theme_color_override("font_color", DAMAGE_COLORS[damage_type])
	dot_text.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	dot_text.add_theme_font_size_override("font_size", 12)
	
	# Adiciona à cena
	get_tree().root.add_child(dot_text)
	
	# Animação mais sutil para DoT
	var tween = dot_text.create_tween()
	tween.set_parallel(true)
	
	# Movimento mais sutil
	tween.tween_property(dot_text, "position:y", dot_text.position.y - 15, 0.7)
	
	# Fade out
	tween.tween_property(dot_text, "modulate:a", 0, 0.7)
	
	# Remove após a animação
	tween.tween_callback(dot_text.queue_free).set_delay(0.7)
