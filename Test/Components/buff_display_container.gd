extends Control
class_name BuffDisplayContainer

# This class manages the visual display of buffs and debuffs
# Attach this to entities directly above the healthbar position

# Configuration
@export var max_icons: int = 6  # Maximum number of icons to display
@export var icon_size: Vector2 = Vector2(16, 16)  # Size of each icon
@export var icon_spacing: int = 2  # Spacing between icons
@export var display_orientation: int = 0  # 0 = horizontal, 1 = vertical
@export var show_stack_count: bool = true  # Show stack numbers
@export var show_duration: bool = true  # Show duration bar
@export var show_tooltips: bool = true  # Show tooltips on hover
@export var debug_outline: bool = true  # Show outline for debugging
@onready var container: HBoxContainer = $IconContainer


# Preload the icon template scene or create it dynamically
var buff_icon_scene = preload("res://Test/UI/BuffIcon.tscn")  # Create this scene or adjust path

# Dictionary to store active buff icon instances
var active_buff_icons = {}

func _ready():
	# Make sure container is properly set up for centering
	container.alignment = BoxContainer.ALIGNMENT_CENTER
	container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

# Add a new buff/debuff icon
func add_buff_icon(id, icon_texture, color: Color, name: String, duration: float, description: String = "") -> void:
	# Don't add if already exists
	if id in active_buff_icons:
		update_buff_icon(id, duration)
		return
	
	# Don't exceed maximum
	if container.get_child_count() >= max_icons:
		return
	
	# Try to instance the icon
	var buff_icon
	if buff_icon_scene:
		# Instance from scene
		buff_icon = buff_icon_scene.instantiate()
	else:
		# Create from scratch
		buff_icon = _create_buff_icon()
	
	# Configure the icon
	buff_icon.name = "BuffIcon_" + str(id)
	
	# Set icon texture
	var icon_texture_rect = buff_icon.get_node_or_null("Icon")
	if icon_texture_rect:
		icon_texture_rect.texture = icon_texture
	
	# Set background color
	var background = buff_icon.get_node_or_null("Background")
	if background:
		background.modulate = color
	
	# Set duration progress
	var duration_bar = buff_icon.get_node_or_null("DurationBar")
	if duration_bar and show_duration:
		duration_bar.max_value = duration
		duration_bar.value = duration
		duration_bar.visible = true
	elif duration_bar:
		duration_bar.visible = false
	
	# Set stack count
	var stack_label = buff_icon.get_node_or_null("StackCount")
	if stack_label:
		stack_label.text = "1"
		stack_label.visible = show_stack_count
	
	# Set tooltip
	if show_tooltips:
		var tooltip_text = name
		if description:
			tooltip_text += "\n" + description
		buff_icon.tooltip_text = tooltip_text
	
	# Store data
	buff_icon.set_meta("id", id)
	buff_icon.set_meta("duration", duration)
	buff_icon.set_meta("stacks", 1)
	
	# Add to container
	container.add_child(buff_icon)
	active_buff_icons[id] = buff_icon
	
	# Start duration timer
	if duration > 0 and show_duration:
		_start_duration_timer(id, duration)
	
	# Add a fancy intro animation
	buff_icon.scale = Vector2(0.5, 0.5)
	var tween = create_tween()
	tween.tween_property(buff_icon, "scale", Vector2(1.0, 1.0), 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

# Rest of the functions remain the same...
# Update an existing buff/debuff icon
func update_buff_icon(id, remaining_time: float, stacks: int = -1) -> void:
	if not id in active_buff_icons:
		return
	
	var buff_icon = active_buff_icons[id]
	
	# Update duration
	if remaining_time > 0 and show_duration:
		var duration_bar = buff_icon.get_node_or_null("DurationBar")
		if duration_bar:
			duration_bar.max_value = buff_icon.get_meta("duration")
			duration_bar.value = remaining_time
	
	# Update stack count
	if stacks > 0 and show_stack_count:
		var stack_label = buff_icon.get_node_or_null("StackCount")
		if stack_label:
			stack_label.text = str(stacks)
			buff_icon.set_meta("stacks", stacks)
			
			# Pulsing animation for stacks change
			var pulse = create_tween()
			pulse.tween_property(buff_icon, "scale", Vector2(1.25, 1.25), 0.1)
			pulse.tween_property(buff_icon, "scale", Vector2(1.0, 1.0), 0.1)

# Remove a buff/debuff icon
func remove_buff_icon(id) -> void:
	if id in active_buff_icons:
		var buff_icon = active_buff_icons[id]
		
		# Cancel any timers
		var timer = buff_icon.get_node_or_null("DurationTimer")
		if timer:
			timer.stop()
		
		# Create fade out animation
		var tween = create_tween()
		tween.tween_property(buff_icon, "scale", Vector2(0.5, 0.5), 0.2)
		tween.parallel().tween_property(buff_icon, "modulate", Color(1, 1, 1, 0), 0.2)
		tween.tween_callback(buff_icon.queue_free)
		
		# Remove from tracking
		active_buff_icons.erase(id)
		# Force the container to recalculate its minimum size
		container.queue_sort()

# Handle all buff icon durations in _process
func _process(delta: float) -> void:
	if not show_duration:
		return
	
	# Update duration bars for all active buff icons
	var to_remove = []
	
	for id in active_buff_icons.keys():
		var buff_icon = active_buff_icons[id]
		var duration_bar = buff_icon.get_node_or_null("DurationBar")
		
		if duration_bar and duration_bar.visible:
			# Decrease value
			duration_bar.value -= delta
			
			# Check if duration has expired
			if duration_bar.value <= 0:
				to_remove.append(id)
	
	# Remove expired icons
	for id in to_remove:
		remove_buff_icon(id)

# Create a duration timer for automatic removal
func _start_duration_timer(id, duration: float) -> void:
	var buff_icon = active_buff_icons[id]
	
	# Create timer if needed
	var timer = buff_icon.get_node_or_null("DurationTimer")
	if not timer:
		timer = Timer.new()
		timer.name = "DurationTimer"
		timer.one_shot = true
		buff_icon.add_child(timer)
		timer.timeout.connect(func(): remove_buff_icon(id))
	
	# Set timer
	timer.wait_time = duration
	timer.start()

# Create a buff icon from scratch if no scene is available
func _create_buff_icon() -> Control:
	var panel = Panel.new()
	panel.custom_minimum_size = icon_size
	
	# Background
	var background = ColorRect.new()
	background.name = "Background"
	background.color = Color(0.3, 0.3, 0.3, 0.7)
	background.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	background.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(background)
	
	# Icon
	var icon = TextureRect.new()
	icon.name = "Icon"
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	icon.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(icon)
	
	# Stack count
	var stack_label = Label.new()
	stack_label.name = "StackCount"
	stack_label.text = "1"
	stack_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	stack_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	stack_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stack_label.add_theme_color_override("font_outline_color", Color.BLACK)
	stack_label.add_theme_constant_override("outline_size", 1)
	panel.add_child(stack_label)
	
	# Duration bar
	var prog_bar = ProgressBar.new()
	prog_bar.name = "DurationBar"
	prog_bar.max_value = 1.0
	prog_bar.value = 1.0
	prog_bar.show_percentage = false
	prog_bar.custom_minimum_size = Vector2(icon_size.x, 3)
	prog_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	prog_bar.size_flags_vertical = Control.SIZE_SHRINK_END
	prog_bar.position.y = icon_size.y - 3
	panel.add_child(prog_bar)
	
	return panel
	
# Call this when the entity dies to clear all buffs immediately
func clear_all_buffs() -> void:
	# Create a copy of the keys to avoid modification during iteration
	var buff_ids = active_buff_icons.keys()
	
	# If you want a special removal animation for death
	var fade_tween = create_tween()
	for id in buff_ids:
		var buff_icon = active_buff_icons[id]
		if buff_icon and is_instance_valid(buff_icon):
			# Add each buff to a parallel animation
			fade_tween.parallel().tween_property(buff_icon, "modulate", Color(1, 1, 1, 0), 0.2)
	
	# After the fade completes, completely remove all buffs
	fade_tween.tween_callback(func():
		for id in buff_ids:
			if id in active_buff_icons:
				var buff_icon = active_buff_icons[id]
				if buff_icon and is_instance_valid(buff_icon):
					# Cancel any timers
					var timer = buff_icon.get_node_or_null("DurationTimer")
					if timer:
						timer.stop()
					# Remove the icon
					buff_icon.queue_free()
				# Remove from tracking
				active_buff_icons.erase(id)
		# Reset container
		container.queue_sort()
	)
