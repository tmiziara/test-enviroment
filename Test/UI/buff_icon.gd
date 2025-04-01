extends Panel

func _ready():
	# Ensure minimum size
	custom_minimum_size = Vector2(16, 16)
	
	# Configure tooltip
	mouse_filter = MOUSE_FILTER_STOP
	tooltip_text = "Buff effect"
	
	# Ensure components are properly set up
	var background = get_node_or_null("Background")
	if background:
		background.mouse_filter = MOUSE_FILTER_IGNORE
	
	var icon = get_node_or_null("Icon")
	if icon:
		icon.mouse_filter = MOUSE_FILTER_IGNORE
		
	var stack_count = get_node_or_null("StackCount")
	if stack_count:
		stack_count.mouse_filter = MOUSE_FILTER_IGNORE
		
	var duration_bar = get_node_or_null("DurationBar")
	if duration_bar:
		duration_bar.mouse_filter = MOUSE_FILTER_IGNORE
