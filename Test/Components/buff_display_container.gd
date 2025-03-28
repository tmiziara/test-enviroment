# buff_display_container.gd
extends Control
class_name BuffDisplayContainer

# Configurações
@export var offset_y: float = -40  # Distância acima do soldado
@export var spacing: float = 2     # Espaçamento entre ícones
@export var icon_size: Vector2 = Vector2(24, 24)  # Tamanho padrão dos ícones

# Referência para os buffs atualmente visíveis
var buff_nodes = {}  # Dicionário com {nome_buff: nó}
var soldier = null
# Mapeamento para guardar referência aos buffs ativos
var active_buff_nodes = {}

func _ready():
	soldier = get_parent()
	# Posicionar acima do soldado
	position = Vector2(0, offset_y)

	# Registrar no soldier para que os talentos possam encontrar
	soldier.set_meta("buff_container", self)

func _process(_delta):
	# Reorganiza os buffs sempre que necessário
	if buff_nodes.size() > 0:
		organize_buffs()

# Adiciona ou atualiza um buff - pode receber um nó ou apenas o recurso da textura
func add_buff(buff_id: String, buff_content):
	var buff_node
	
	# Se o buff já existe, atualizamos
	if buff_id in buff_nodes:
		buff_node = buff_nodes[buff_id]
		
		# Se recebemos um novo nó, substituímos o antigo
		if buff_content is Node:
			buff_node.queue_free()
			buff_node = buff_content
			add_child(buff_node)
			buff_nodes[buff_id] = buff_node
		# Se é uma textura, atualizamos o nó existente
		elif buff_content is Texture2D:
			var texture_rect = buff_node.get_node_or_null("TextureRect")
			if texture_rect:
				texture_rect.texture = buff_content
		# Se é um número, assumimos que é um contador
		elif buff_content is int:
			var label = buff_node.get_node_or_null("CountLabel")
			if label:
				label.text = str(buff_content)
				
				# Animar para dar feedback visual do aumento
				if buff_content > 0:
					var tween = create_tween()
					tween.tween_property(buff_node, "scale", Vector2(1.2, 1.2), 0.15)
					tween.tween_property(buff_node, "scale", Vector2(1.0, 1.0), 0.15)
	
	# Se o buff não existe, criamos um novo
	else:
		# Se recebemos um nó pré-configurado
		if buff_content is Node:
			buff_node = buff_content
			add_child(buff_node)
		
		# Se recebemos uma textura, criamos um nó para ela
		elif buff_content is Texture2D:
			buff_node = create_icon_container(buff_content)
			add_child(buff_node)
		
		# Se recebemos um dicionário com informações
		elif buff_content is Dictionary:
			var texture = buff_content.get("texture")
			var count = buff_content.get("count", 0)
			
			if texture:
				buff_node = create_icon_container(texture, count)
				add_child(buff_node)
		
		# Armazena a referência
		if buff_node:
			buff_nodes[buff_id] = buff_node
	
	# Reorganiza os buffs
	organize_buffs()

# Cria um contêiner com ícone e opcionalmente um contador
func create_icon_container(texture: Texture2D, count: int = 0) -> Control:
	var container = Control.new()
	container.custom_minimum_size = icon_size
	
	# Adiciona a textura
	var texture_rect = TextureRect.new()
	texture_rect.name = "TextureRect"
	texture_rect.texture = texture
	texture_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	texture_rect.custom_minimum_size = icon_size
	container.add_child(texture_rect)
	
	# Adiciona um contador se necessário
	if count > 0:
		var label = Label.new()
		label.name = "CountLabel"
		label.text = str(count)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		label.custom_minimum_size = icon_size
		label.add_theme_font_size_override("font_size", 12)
		label.add_theme_color_override("font_color", Color(1,1,1))
		label.add_theme_color_override("font_outline_color", Color(0,0,0))
		label.add_theme_constant_override("outline_size", 1)
		container.add_child(label)
	
	# Animação de entrada
	container.modulate.a = 0
	var tween = create_tween()
	tween.tween_property(container, "modulate:a", 1.0, 0.3)
	
	return container

# Remove um buff
func remove_buff(buff_id: String):
	if buff_id in buff_nodes:
		var buff_node = buff_nodes[buff_id]
		
		# Animação de saída
		var tween = create_tween()
		tween.tween_property(buff_node, "modulate:a", 0.0, 0.3)
		tween.tween_callback(func():
			buff_node.queue_free()
			buff_nodes.erase(buff_id)
			organize_buffs()
		)

# Organiza os buffs em uma linha horizontal centralizada
func organize_buffs():
	var buff_list = buff_nodes.values()
	var total_width = buff_list.size() * (icon_size.x + spacing) - spacing
	
	# Posiciona os buffs lado a lado, centralizados
	var start_x = -total_width / 2
	var current_x = start_x
	
	for buff in buff_list:
		buff.position.x = current_x
		buff.position.y = 0
		current_x += icon_size.x + spacing
