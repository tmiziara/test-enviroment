# debuff_display_component.gd
extends Control
class_name DebuffDisplayComponent

# Referência ao nó pai que pode receber debuffs
var entity: Node

# Dicionário para rastrear ícones de debuff atualmente exibidos
var active_debuff_icons = {}

# HBoxContainer para organizar os ícones
@onready var container = $HBoxContainer

func _ready():
	entity = get_owner().get_parent()  # Pula o DamageBar para chegar ao entity
	
	# Conecta com o DebuffComponent se possível
	if entity.has_node("DebuffComponent"):
		var debuff_component = entity.get_node("DebuffComponent")
		debuff_component.connect("debuff_added", _on_debuff_added)
		debuff_component.connect("debuff_removed", _on_debuff_removed)

func _process(delta):
	update_debuffs()

func update_debuffs():
	# Verifica debuffs via DebuffComponent
	if entity.has_node("DebuffComponent"):
		var debuff_component = entity.get_node("DebuffComponent")
		var active_debuffs = debuff_component.get_active_debuffs()
		
		# Verifica cada tipo de debuff que queremos exibir
		check_debuff_type(GlobalDebuffSystem.DebuffType.MARKED_FOR_DEATH, 
			"res://Test/Assets/Icons/debuffs/mark_of_death.png", Color(0.9, 0.1, 0.1))
		
		check_debuff_type(GlobalDebuffSystem.DebuffType.BURNING, 
			"res://Test/Assets/Icons/debuffs/fire_icon.png", Color(0.9, 0.5, 0.1))
			
		check_debuff_type(GlobalDebuffSystem.DebuffType.BLEEDING, 
			"res://Test/Assets/Icons/debuffs/bleeding.png", Color(0.8, 0.1, 0.1))

func check_debuff_type(debuff_type: int, icon_path: String, color: Color):
	var type_name = str(debuff_type)  # Usamos o número como uma string para a chave
	
	# Verifica se o debuff está ativo via DebuffComponent
	if entity.has_node("DebuffComponent"):
		var debuff_component = entity.get_node("DebuffComponent")
		
		if debuff_component.has_debuff(debuff_type):
			# Se o ícone ainda não foi criado
			if not type_name in active_debuff_icons:
				create_debuff_icon(type_name, icon_path, color)
		else:
			# Se o debuff não existe mais, remove o ícone
			if type_name in active_debuff_icons:
				remove_debuff_icon(type_name)

# Esta função é para compatibilidade com o antigo sistema de metadados
func check_meta_debuff(debuff_name: String, icon_path: String, color: Color):
	# Verifica se o debuff existe como metadata
	if entity.has_meta(debuff_name):
		# Se o ícone ainda não foi criado
		if not debuff_name in active_debuff_icons:
			create_debuff_icon(debuff_name, icon_path, color)
	else:
		# Se o debuff não existe mais, remove o ícone
		if debuff_name in active_debuff_icons:
			remove_debuff_icon(debuff_name)

func create_debuff_icon(debuff_name: String, icon_path: String, color: Color):
	var icon = TextureRect.new()
	icon.custom_minimum_size = Vector2(16, 16)
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	
	# Carrega a textura do ícone
	if ResourceLoader.exists(icon_path):
		icon.texture = load(icon_path)
	else:
		# Fallback: criar um ícone genérico se o arquivo não existir
		var default_texture = create_default_icon(debuff_name, color)
		icon.texture = default_texture
	
	
	# Adiciona o ícone ao container
	container.add_child(icon)
	active_debuff_icons[debuff_name] = icon

func create_default_icon(debuff_name: String, color: Color) -> Texture2D:
	# Cria um ícone padrão para uso como fallback
	var img = Image.create(16, 16, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))  # Transparente
	
	# Desenha um círculo simples
	for x in range(16):
		for y in range(16):
			var dx = x - 8
			var dy = y - 8
			var dist = sqrt(dx*dx + dy*dy)
			
			if dist <= 7:
				img.set_pixel(x, y, color)
	
	return ImageTexture.create_from_image(img)

func remove_debuff_icon(debuff_name: String):
	if debuff_name in active_debuff_icons:
		active_debuff_icons[debuff_name].queue_free()
		active_debuff_icons.erase(debuff_name)

# Callbacks para os sinais do DebuffComponent
func _on_debuff_added(debuff_type: int):
	# Vai ser atualizado automaticamente no próximo update_debuffs
	pass

func _on_debuff_removed(debuff_type: int):
	# Vai ser atualizado automaticamente no próximo update_debuffs
	pass
