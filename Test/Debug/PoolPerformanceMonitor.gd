extends Node
class_name PoolPerformanceMonitor

# Referência ao sistema de pool
var pool_system: ProjectilePoolSystem = null

# Variáveis para métricas
var created_count: Dictionary = {}
var reused_count: Dictionary = {}
var returned_count: Dictionary = {}

# Variáveis para taxa de criação
var last_second_created: int = 0
var creation_rate: float = 0.0

# Nó de interface para exibir estatísticas
var stats_display: Label = null

# Temporizador para atualização das estatísticas
var update_timer: Timer = null

func _ready():
	# Cria um temporizador para atualizar as estatísticas
	update_timer = Timer.new()
	update_timer.wait_time = 1.0
	update_timer.one_shot = false
	update_timer.autostart = true
	add_child(update_timer)
	update_timer.timeout.connect(_update_rates)
	
	# Cria um label para mostrar as estatísticas
	stats_display = Label.new()
	stats_display.name = "StatsDisplay"
	stats_display.position = Vector2(10, 10)
	stats_display.size = Vector2(300, 200)
	add_child(stats_display)

# Conecta ao sistema de pool
func connect_to_pool_system(system: ProjectilePoolSystem) -> void:
	pool_system = system
	
	# Conecta aos sinais
	system.projectile_created.connect(_on_projectile_created)
	system.projectile_reused.connect(_on_projectile_reused)
	system.projectile_returned.connect(_on_projectile_returned)
	
	print("PoolPerformanceMonitor: Conectado ao sistema de pool")

# Callback quando um projétil é criado
func _on_projectile_created(category: String, pool_name: String) -> void:
	var key = category + ":" + pool_name
	
	if not key in created_count:
		created_count[key] = 0
	
	created_count[key] += 1
	last_second_created += 1

# Callback quando um projétil é reutilizado
func _on_projectile_reused(category: String, pool_name: String) -> void:
	var key = category + ":" + pool_name
	
	if not key in reused_count:
		reused_count[key] = 0
	
	reused_count[key] += 1

# Callback quando um projétil é devolvido
func _on_projectile_returned(category: String, pool_name: String) -> void:
	var key = category + ":" + pool_name
	
	if not key in returned_count:
		returned_count[key] = 0
	
	returned_count[key] += 1

# Atualiza as taxas de criação
func _update_rates() -> void:
	# Atualiza a taxa de criação
	creation_rate = last_second_created
	last_second_created = 0
	
	# Atualiza o display
	_update_stats_display()

# Atualiza o display de estatísticas
func _update_stats_display() -> void:
	if not pool_system or not stats_display:
		return
	
	var stats_text = "Pool System Stats:\n"
	
	# Adiciona estatísticas por categoria
	stats_text += "\nPool Counts by Category:\n"
	for category in pool_system.pool_categories.keys():
		var cat_stats = pool_system.get_category_stats(category)
		stats_text += "- " + category + ": " + str(cat_stats.available) + " available, " + str(cat_stats.active) + " active\n"
	
	# Adiciona contadores de eventos
	stats_text += "\nEvent Counters:\n"
	
	# Agrupa contadores por categoria
	var category_totals = {}
	
	for key in created_count.keys():
		var parts = key.split(":")
		var category = parts[0]
		
		if not category in category_totals:
			category_totals[category] = {
				"created": 0,
				"reused": 0,
				"returned": 0
			}
		
		category_totals[category]["created"] += created_count[key]
	
	for key in reused_count.keys():
		var parts = key.split(":")
		var category = parts[0]
		
		if category in category_totals:
			category_totals[category]["reused"] += reused_count[key]
	
	for key in returned_count.keys():
		var parts = key.split(":")
		var category = parts[0]
		
		if category in category_totals:
			category_totals[category]["returned"] += returned_count[key]
	
	# Mostra totais por categoria
	for category in category_totals.keys():
		var totals = category_totals[category]
		stats_text += "- " + category + ": Created=" + str(totals.created) + ", Reused=" + str(totals.reused) + ", Returned=" + str(totals.returned) + "\n"
	
	# Adiciona taxa de criação
	stats_text += "\nCreation Rate: " + str(creation_rate) + " per second"
	
	# Atualiza o texto do label
	stats_display.text = stats_text

# Método para obter estatísticas atuais
func get_current_stats() -> Dictionary:
	if not pool_system:
		return {}
	
	var stats = {
		"categories": {},
		"events": {
			"created": {},
			"reused": {},
			"returned": {}
		},
		"creation_rate": creation_rate
	}
	
	# Adiciona estatísticas por categoria
	for category in pool_system.pool_categories.keys():
		stats.categories[category] = pool_system.get_category_stats(category)
	
	# Adiciona contadores de eventos
	for key in created_count.keys():
		stats.events.created[key] = created_count[key]
	
	for key in reused_count.keys():
		stats.events.reused[key] = reused_count[key]
	
	for key in returned_count.keys():
		stats.events.returned[key] = returned_count[key]
	
	return stats

# Resetar contadores
func reset_counters() -> void:
	created_count.clear()
	reused_count.clear()
	returned_count.clear()
	last_second_created = 0
	creation_rate = 0.0
