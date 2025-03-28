extends BaseProjectileStrategy
class_name Talent_18

# Bloodseeker parameters
@export var damage_increase_per_stack: float = 0.1  # 10% damage increase per stack
@export var max_stacks: int = 5  # Maximum number of stacks
@export var talent_id: int = 18  # ID for this talent in the talent tree

# Name for debug panel
func get_strategy_name() -> String:
	return "Bloodseeker"

# Main upgrade application
func apply_upgrade(projectile: Node) -> void:
	print("Applying Bloodseeker upgrade - Consecutive hits stack damage")
	
	# Add tag for identification
	if "tags" in projectile and projectile.has_method("add_tag"):
		projectile.add_tag("bloodseeker")
	elif "tags" in projectile:
		if not "bloodseeker" in projectile.tags:
			projectile.tags.append("bloodseeker")
	
	# Mark projectile as having bloodseeker effect
	projectile.set_meta("has_bloodseeker_effect", true)
	
	# Store bloodseeker parameters in projectile
	projectile.set_meta("damage_increase_per_stack", damage_increase_per_stack)
	projectile.set_meta("max_stacks", max_stacks)
	
	# Get reference to the shooter
	var shooter = projectile.shooter
	if shooter:
		# Initialize stack tracking for the shooter if not already done
		if not has_bloodseeker_data(shooter):
			init_bloodseeker_data(shooter)
			
		# Apply current damage bonus based on stacks
		apply_current_bloodseeker_bonus(projectile, shooter)
		# Conectar ao sinal de mudança de alvo
		connect_to_target_change(shooter)
	# If projectile is an Arrow, enhance its hit processing
	if projectile is Arrow:
		enhance_arrow_hit_processing(projectile)
	
	print("Bloodseeker successfully applied to projectile")

# Check if shooter already has bloodseeker data
func has_bloodseeker_data(shooter: Node) -> bool:
	return shooter.has_meta("bloodseeker_data")

# Initialize bloodseeker data structure for shooter
func init_bloodseeker_data(shooter: Node) -> void:
	var data = {
		"target": null,
		"stacks": 0,
		"last_hit_time": 0
	}
	shooter.set_meta("bloodseeker_data", data)
	# Create visual indicator for player
	create_stack_visual_on_player(shooter, 0)

# Enhance Arrow hit processing for Bloodseeker effect
func enhance_arrow_hit_processing(arrow: Arrow) -> void:
	print("Enhancing arrow hit processing for Bloodseeker effect")
	
	# Store reference to self for later
	var self_ref = weakref(self)
	
	# Connect to the arrow's 'on_hit' signal if it exists
	if arrow.has_signal("on_hit"):
		# Check if we're already connected
		var connections = arrow.get_signal_connection_list("on_hit")
		var already_connected = false
		
		for connection in connections:
			if connection.callable.get_object() == self:
				already_connected = true
				break
		
		if not already_connected:
			# Define a callback function for the on_hit signal
			var on_hit_callback = func(target, proj):
				# Skip if arrow is invalid
				if not is_instance_valid(proj) or proj != arrow:
					return
					
				# Skip if shooter is invalid
				var shooter = arrow.shooter
				if not shooter or not is_instance_valid(shooter):
					return
				
				# Get the shooter's current target
				var current_primary_target = null
				if shooter.has_method("get_current_target"):
					current_primary_target = shooter.get_current_target()
				
				# Only process stacks if this is the primary target
				if current_primary_target != target:
					return
					
				# Get a reference to this strategy
				var strategy = self_ref.get_ref()
				if strategy:
					# Process the stack logic
					strategy.process_bloodseeker_stacks(shooter, target)
					
			# Connect the callback to the on_hit signal
			arrow.connect("on_hit", on_hit_callback)
			print("Connected to arrow's on_hit signal")
		else:
			print("Already connected to on_hit signal")
	else:
		print("Arrow doesn't have on_hit signal, using metadata")
		# Set metadata for the arrow to know to use bloodseeker
		arrow.set_meta("bloodseeker_strategy", self_ref)

# Process stacks when a hit occurs
func process_bloodseeker_stacks(shooter: Node, target: Node) -> void:
	if not shooter or not is_instance_valid(shooter) or not target or not is_instance_valid(target):
		return
	
	# Ensure data exists
	if not has_bloodseeker_data(shooter):
		init_bloodseeker_data(shooter)
	
	# Get bloodseeker data
	var data = shooter.get_meta("bloodseeker_data")
	var current_target = data["target"]
	
	# Update the time of last hit
	data["last_hit_time"] = Time.get_ticks_msec()
	
	# Check if this is a new target
	if target != current_target:
		# New target, reset stacks to 1
		data["target"] = target
		data["stacks"] = 1
		print("Bloodseeker: New target, stacks reset to 1")
	else:
		# Same target, increment stacks up to max
		var stacks = data["stacks"]
		stacks = min(stacks + 1, max_stacks)
		data["stacks"] = stacks
		print("Bloodseeker: Hit on same target, stacks now ", stacks)
	
	# Update the displayed stacks on the player
	create_stack_visual_on_player(shooter, data["stacks"])
	
	# Update the metadata with new values
	shooter.set_meta("bloodseeker_data", data)

# Apply current bloodseeker bonus to projectile
func apply_current_bloodseeker_bonus(projectile: Node, shooter: Node) -> void:
	if not has_bloodseeker_data(shooter):
		return
		
	var data = shooter.get_meta("bloodseeker_data")
	var stacks = data["stacks"]
	
	if stacks <= 0:
		return
		
	# Calculate total damage increase
	var total_increase = damage_increase_per_stack * stacks
	
	# Apply bonus to direct damage
	if "damage" in projectile:
		var original_damage = projectile.damage
		projectile.damage = int(original_damage * (1 + total_increase))
		print("Bloodseeker: Direct damage increased from ", original_damage, " to ", projectile.damage)
	
	# Apply to damage calculator if available
	if projectile.has_node("DmgCalculatorComponent"):
		var dmg_calc = projectile.get_node("DmgCalculatorComponent")
		
		# Apply multiplier to DmgCalculator
		if "damage_multiplier" in dmg_calc:
			dmg_calc.damage_multiplier *= (1 + total_increase)
			print("Bloodseeker: Applied damage multiplier ", (1 + total_increase), " (", stacks, " stacks)")
		
		# Apply to base damage if available
		if "base_damage" in dmg_calc:
			dmg_calc.base_damage = int(dmg_calc.base_damage * (1 + total_increase))
			
		# Also apply to elemental damages
		if "elemental_damage" in dmg_calc:
			for element in dmg_calc.elemental_damage:
				dmg_calc.elemental_damage[element] = int(dmg_calc.elemental_damage[element] * (1 + total_increase))

# Static variable to track the display node
static var stack_display_node: Node = null

# Modificação para o Talent_18.gd para integrar visualização personalizada

# Função que cria um nó visual personalizado para os stacks
func create_custom_stack_visual(stacks: int) -> Control:
	# Criar container para a visualização personalizada
	var container = Control.new()
	container.name = "BloodseekerStacksVisual"
	
	# Número de stacks a exibir (limitado ao máximo)
	var actual_stacks = min(stacks, max_stacks)
	
	# Define a largura total que queremos (16 pixels por stack)
	var total_width = 16 * actual_stacks
	container.custom_minimum_size = Vector2(total_width, 16)
	
	# Cria um único TextureRect para exibir todos os stacks juntos
	var single_icon = TextureRect.new()
	single_icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH
	single_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	single_icon.size_flags_horizontal = Control.SIZE_FILL
	single_icon.size_flags_vertical = Control.SIZE_FILL
	single_icon.custom_minimum_size = Vector2(total_width, 16)
	
	# O caminho da textura
	var texture_path = "res://Test/Assets/Icons/buffs/bloodseeker_stack.png"
	
	if ResourceLoader.exists(texture_path):
		# Carrega a textura com todos os stacks
		var base_texture = load(texture_path)
		
		# Cria uma nova textura para conter apenas os stacks que precisamos
		var image = Image.new()
		image.copy_from(base_texture.get_image())
		
		# Recorta a imagem para incluir apenas os stacks necessários
		# Se a imagem tiver todos os stacks horizontalmente (cada 204px de largura)
		var cropped_image = Image.create(204 * actual_stacks, image.get_height(), false, image.get_format())
		
		# Copia apenas as partes que precisamos (os stacks ativos)
		for i in range(actual_stacks):
			var src_rect = Rect2(i * 204, 0, 204, image.get_height())
			cropped_image.blit_rect(image, src_rect, Vector2(i * 204, 0))
			
		# Cria textura a partir da imagem recortada
		var cropped_texture = ImageTexture.create_from_image(cropped_image)
		single_icon.texture = cropped_texture
	else:
		# Fallback para textura ausente
		var color_rect = ColorRect.new()
		color_rect.color = Color(1.0, 0.2, 0.2)
		color_rect.size = Vector2(total_width, 16)
		single_icon.add_child(color_rect)
	
	# Adiciona o ícone ao container
	container.add_child(single_icon)
	
	# Adiciona efeito visual se alcançou o máximo de stacks
	if stacks >= max_stacks:
		# Tween para destacar visuamente com cor
		var max_stack_tween = container.create_tween()
		max_stack_tween.tween_property(container, "modulate", Color(1.0, 0.5, 0.0, 1.0), 0.3)
		max_stack_tween.tween_property(container, "modulate", Color(1.0, 0.0, 0.0, 1.0), 0.3)
		max_stack_tween.set_loops(2)  # Pisca duas vezes para indicar stacks máximos
	
	return container

# Função modificada para criar e atualizar o visual de stacks
func create_stack_visual_on_player(player: Node, stacks: int) -> void:
	if not is_instance_valid(player):
		return
	
	# Procura o BuffDisplayContainer
	var buff_container = null
	
	# Primeiro tenta encontrar pelo nome
	buff_container = player.get_node_or_null("BuffDisplayContainer")
	
	# Se não encontrou, tenta pela metadata
	if not buff_container and player.has_meta("buff_container"):
		buff_container = player.get_meta("buff_container")
	
	# Se não houver stacks, remove qualquer exibição existente
	if stacks <= 0:
		if buff_container and buff_container.has_method("remove_buff"):
			buff_container.remove_buff("bloodseeker")
		elif stack_display_node != null and is_instance_valid(stack_display_node):
			stack_display_node.queue_free()
			stack_display_node = null
		return
	
	# Se encontramos o BuffDisplayContainer
	if buff_container and buff_container.has_method("add_buff"):
		# Cria o nó visual personalizado
		var custom_stack_visual = create_custom_stack_visual(stacks)
		
		# Passa o nó visual para o BuffDisplayContainer
		buff_container.add_buff("bloodseeker", custom_stack_visual)
	else:
		# Fallback: criar e posicionar o stack visual diretamente
		if stack_display_node != null and is_instance_valid(stack_display_node):
			stack_display_node.queue_free()
		
		var custom_stack_visual = create_custom_stack_visual(stacks)
		custom_stack_visual.position = Vector2(0, -40) # Posiciona acima do jogador
		custom_stack_visual.z_index = 100
		
		# Adiciona animação de surgimento
		var tween = custom_stack_visual.create_tween()
		tween.tween_property(custom_stack_visual, "scale", Vector2(1.2, 1.2), 0.25)
		tween.tween_property(custom_stack_visual, "scale", Vector2(1.0, 1.0), 0.25)
		
		# Armazena a referência e adiciona ao jogador
		player.add_child(custom_stack_visual)
		stack_display_node = custom_stack_visual
	
		
# Função para conectar ao sinal target_change
func connect_to_target_change(shooter: Node) -> void:
	# Evitar conexões duplicadas
	if shooter.has_meta("bloodseeker_connected_to_target_change"):
		return
		
	shooter.set_meta("bloodseeker_connected_to_target_change", true)
	
	# Verificar se o sinal existe
	if shooter.has_signal("target_change"):
		# Referência fraca para a estratégia
		var self_ref = weakref(self)
		
		# Conectar ao sinal
		shooter.connect("target_change", func(new_target):
			print("Bloodseeker: Target change signal received!")
			
			# Garantir que temos os dados do Bloodseeker
			if not has_bloodseeker_data(shooter):
				init_bloodseeker_data(shooter)
				
			# Resetar os stacks
			var data = shooter.get_meta("bloodseeker_data")
			data["target"] = new_target
			data["stacks"] = 0
			shooter.set_meta("bloodseeker_data", data)
			
			# Atualizar a visualização
			var strategy = self_ref.get_ref()
			if strategy:
				strategy.create_stack_visual_on_player(shooter, 0)
		)
	else:
		print("WARNING: Shooter doesn't have the target_change signal")
