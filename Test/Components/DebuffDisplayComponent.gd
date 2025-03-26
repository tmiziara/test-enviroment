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
	entity = get_parent()
	
func _process(_delta):
	update_debuffs()
	
func update_debuffs():
	# Verifica se o pai tem meta 'marked_for_death'
	check_debuff("marked_for_death", "res://Test/Assets/Icons/debuffs/marked_icon.png", Color(0.9, 0.1, 0.1))
	
	# Você pode adicionar mais verificações para outros tipos de debuffs
	check_debuff("frozen", "res://assets/icons/frozen_icon.png", Color(0.2, 0.5, 0.9))
	check_debuff("burning", "res://assets/icons/fire_icon.png", Color(0.9, 0.5, 0.1))
	# etc...

func check_debuff(debuff_name: String, icon_path: String, color: Color):
	# Verifica se o debuff existe
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
	icon.custom_minimum_size = Vector2(10, 10)
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon.stretch_mode = TextureRect.STRETCH_SCALE
	icon.size_flags_vertical = Control.SIZE_FILL
	
	# Se você não tem ícones específicos, pode criar um sprite programaticamente
	if ResourceLoader.exists(icon_path):
		icon.texture = load(icon_path)
	else:
		pass
	
	icon.modulate = color
	active_debuff_icons[debuff_name] = icon

func remove_debuff_icon(debuff_name: String):
	if debuff_name in active_debuff_icons:
		active_debuff_icons[debuff_name].queue_free()
		active_debuff_icons.erase(debuff_name)
