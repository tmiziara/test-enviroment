extends Node

var active_chain_arrows = []
var chain_count = 0
var max_elapsed_time = 5.0  # Maximum time in seconds before we consider an arrow stuck

func _ready():
	# Start the monitoring process
	var timer = Timer.new()
	timer.wait_time = 1.0  # Check every second
	timer.autostart = true
	timer.timeout.connect(_check_chain_arrows)
	add_child(timer)

func _check_chain_arrows():
	# Get all active arrows in the scene
	var arrows = get_tree().get_nodes_in_group("projectiles")
	var current_time = Time.get_ticks_msec()
	
	var cleanup_count = 0
	
	# Examine each arrow for chain shot status
	for arrow in arrows:
		if not is_instance_valid(arrow):
			continue
			
		# Check if it's an active chain shot arrow
		if arrow.has_meta("is_part_of_chain") or arrow.has_meta("chain_shot_debug"):
			# Check if this arrow has been around too long
			var creation_time = 0
			
			if arrow.has_meta("chain_shot_debug"):
				var debug_data = arrow.get_meta("chain_shot_debug")
				if "timestamp" in debug_data:
					creation_time = debug_data.timestamp
			
			# If we have a timestamp, check elapsed time
			if creation_time > 0:
				var elapsed_seconds = (current_time - creation_time) / 1000.0
				
				# If this arrow has been around too long, it's probably stuck
				if elapsed_seconds > max_elapsed_time:
					print("WARNING: Found stuck chain shot arrow, cleaning up")
					print("  - Chain status: ", arrow.current_chains, "/", arrow.max_chains)
					print("  - Position: ", arrow.global_position)
					print("  - Velocity: ", arrow.velocity)
					print("  - Is processing ricochet: ", arrow.is_processing_ricochet)
					
					# Force cleanup
					arrow.is_processing_ricochet = false
					arrow.will_chain = false
					
					# If the arrow is pooled, return it to the pool
					if arrow.is_pooled():
						if arrow.has_method("reset_for_reuse"):
							arrow.reset_for_reuse()
						arrow.return_to_pool()
					else:
						arrow.queue_free()
						
					cleanup_count += 1
	
	if cleanup_count > 0:
		print("Cleaned up ", cleanup_count, " stuck chain shot arrows")
