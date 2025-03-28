extends Node
class_name PoolPerformanceMonitor

# Estatísticas do sistema de pooling
var total_reuse_count: int = 0
var total_create_count: int = 0
var reuse_per_second: float = 0
var create_per_second: float = 0
var last_second_reuse: int = 0
var last_second_create: int = 0

# Estatísticas por pool
var pool_stats: Dictionary = {}

# Temporizadores
var update_timer: Timer
var last_update_time: int = 0

# Interface (opcional)
var debug_label: Label = null

func _process(_delta):
	# Atualiza a label a cada frame se estiver visível
	if debug_label and debug_label.visible:
		_update_debug_interface()
		
func _init():
	# Configura temporizador de atualização
	update_timer = Timer.new()
	update_timer.wait_time = 1.0  # Atualiza a cada segundo
	update_timer.one_shot = false
	update_timer.autostart = true
	update_timer.timeout.connect(_update_stats)
	add_child(update_timer)
	
	last_update_time = Time.get_ticks_msec()
	
	# Inicializa a interface de debug (opcional)
	_setup_debug_interface()
# Modifique o _ready() para configurar a interface
func _ready():
	print("PoolPerformanceMonitor inicializado!")
	
	# Use call_deferred para garantir que a cena esteja completamente carregada
	call_deferred("_setup_debug_interface")
# Hook para se conectar ao sistema de pooling
func connect_to_pool_system(pool_system: ProjectilePoolSystem) -> void:
	# Monitora cada pool no sistema
	pool_system.connect("projectile_created", _on_projectile_created)
	pool_system.connect("projectile_reused", _on_projectile_reused)
	pool_system.connect("projectile_returned", _on_projectile_returned)
	
	# Inicializa estatísticas para pools existentes
	for pool_name in pool_system.pools.keys():
		_init_pool_stats(pool_name)

# Inicializa estatísticas para um pool específico
func _init_pool_stats(pool_name: String) -> void:
	pool_stats[pool_name] = {
		"total_count": 0,
		"active_count": 0,
		"reuse_count": 0,
		"create_count": 0,
		"peak_active": 0,
		"average_active": 0,
		"total_active_samples": 0,
		"cumulative_active": 0
	}

# Callbacks para eventos do sistema de pooling
func _on_projectile_created(pool_name: String) -> void:
	total_create_count += 1
	last_second_create += 1
	
	# Atualiza estatísticas do pool específico
	if not pool_name in pool_stats:
		_init_pool_stats(pool_name)
	
	pool_stats[pool_name]["total_count"] += 1
	pool_stats[pool_name]["create_count"] += 1
	pool_stats[pool_name]["active_count"] += 1
	
	# Atualiza pico de uso
	if pool_stats[pool_name]["active_count"] > pool_stats[pool_name]["peak_active"]:
		pool_stats[pool_name]["peak_active"] = pool_stats[pool_name]["active_count"]

func _on_projectile_reused(pool_name: String) -> void:
	total_reuse_count += 1
	last_second_reuse += 1
	
	# Atualiza estatísticas do pool específico
	if not pool_name in pool_stats:
		_init_pool_stats(pool_name)
	
	pool_stats[pool_name]["reuse_count"] += 1
	pool_stats[pool_name]["active_count"] += 1
	
	# Atualiza pico de uso
	if pool_stats[pool_name]["active_count"] > pool_stats[pool_name]["peak_active"]:
		pool_stats[pool_name]["peak_active"] = pool_stats[pool_name]["active_count"]

func _on_projectile_returned(pool_name: String) -> void:
	# Atualiza estatísticas do pool específico
	if not pool_name in pool_stats:
		_init_pool_stats(pool_name)
	
	pool_stats[pool_name]["active_count"] -= 1

# Atualiza estatísticas a cada segundo
func _update_stats() -> void:
	var current_time = Time.get_ticks_msec()
	var elapsed_seconds = (current_time - last_update_time) / 1000.0
	
	if elapsed_seconds > 0:
		reuse_per_second = last_second_reuse / elapsed_seconds
		create_per_second = last_second_create / elapsed_seconds
	
	# Atualiza estatísticas de uso médio
	for pool_name in pool_stats.keys():
		var stats = pool_stats[pool_name]
		stats["total_active_samples"] += 1
		stats["cumulative_active"] += stats["active_count"]
		stats["average_active"] = stats["cumulative_active"] / stats["total_active_samples"]
	
	# Reseta contadores
	last_second_reuse = 0
	last_second_create = 0
	last_update_time = current_time
	
	# Atualiza a interface de debug
	_update_debug_interface()

# Configura uma interface visual para depuração
func _setup_debug_interface() -> void:
	# Adicione verificações mais robustas
	if not is_inside_tree():
		print("ERRO: Nó não está dentro de uma árvore")
		return

	# Cria a label
	debug_label = Label.new()
	debug_label.name = "PoolStatsLabel"
	debug_label.position = Vector2(10, 10)
	debug_label.size = Vector2(300, 200)
	
	# Configurações de estilo
	debug_label.add_theme_font_size_override("font_size", 16)
	debug_label.add_theme_color_override("font_color", Color.WHITE)
	debug_label.add_theme_color_override("font_background_color", Color(0, 0, 0, 0.5))
	
	# Cria CanvasLayer
	var canvas_layer = CanvasLayer.new()
	canvas_layer.name = "PoolStatsLayer"
	canvas_layer.layer = 100
	
	# Adiciona ao owner da cena atual
	var root = get_tree().root
	if root:
		root.add_child(canvas_layer)
		canvas_layer.add_child(debug_label)
		debug_label.visible = false  # Começa invisível
		print("Debug label criada e adicionada")
	else:
		print("ERRO: Não foi possível encontrar a root da cena")

# Método auxiliar para adicionar a layer de debug
func _add_debug_layer(canvas_layer: CanvasLayer, background: ColorRect, label: Label) -> void:
	# Adiciona ao root de forma segura
	if get_tree() and get_tree().root:
		get_tree().root.add_child(canvas_layer)
		
		# Adiciona background e label ao CanvasLayer
		canvas_layer.add_child(background)
		canvas_layer.add_child(label)
		
		# Torna a label visível por padrão
		label.visible = true
		
		print("Debug layer adicionada à cena")
	else:
		print("ERRO: Não foi possível adicionar debug layer")
	
func _update_debug_interface() -> void:
	if not debug_label:
		return
	
	var text = "== POOL PERFORMANCE ==\n"
	text += "Total Reuses: " + str(total_reuse_count) + "\n"
	text += "Total Creates: " + str(total_create_count) + "\n"
	
	# Adiciona sempre algo, mesmo que não haja pools
	if pool_stats.size() == 0:
		text += "No pools created yet\n"
	else:
		for pool_name in pool_stats.keys():
			var stats = pool_stats[pool_name]
			text += "\n" + pool_name + ":\n"
			text += "  Active: " + str(stats["active_count"]) + "\n"
			text += "  Peak: " + str(stats["peak_active"]) + "\n"
	
	debug_label.text = text

# Ativa/desativa a visualização das estatísticas
func toggle_stats_display(visible: bool) -> void:
	if debug_label:
		debug_label.visible = visible

# Obter resumo das estatísticas em formato de texto
func get_stats_summary() -> String:
	var text = "Pool Performance Summary:\n"
	text += "Total Reuses: " + str(total_reuse_count) + "\n"
	text += "Total Creates: " + str(total_create_count) + "\n"
	text += "Reuse Rate: " + str(100.0 * total_reuse_count / max(1, total_reuse_count + total_create_count)) + "%\n\n"
	
	for pool_name in pool_stats.keys():
		var stats = pool_stats[pool_name]
		text += pool_name + ":\n"
		text += "  Total Objects: " + str(stats["total_count"]) + "\n"
		text += "  Active Objects: " + str(stats["active_count"]) + "\n"
		text += "  Peak Usage: " + str(stats["peak_active"]) + "\n"
		text += "  Average Usage: " + str(stats["average_active"]) + "\n"
	
	return text

# Restaura as estatísticas para zero
func reset_stats() -> void:
	total_reuse_count = 0
	total_create_count = 0
	reuse_per_second = 0
	create_per_second = 0
	last_second_reuse = 0
	last_second_create = 0
	
	# Reinicia estatísticas para cada pool
	for pool_name in pool_stats.keys():
		_init_pool_stats(pool_name)
