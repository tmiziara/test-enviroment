extends Node2D

@export var talent_tree_scene: PackedScene
@export var debug_panel_scene: PackedScene

var talent_tree_instance: Control = null
var debug_panel: ArcherDebugPanel = null

func _ready():
	# Carrega a cena do painel de debug se não for atribuído no Inspector
	if not debug_panel_scene:
		debug_panel_scene = load("res://archer_debug_panel.tscn")

	# Instancia o painel de debug
	debug_panel = debug_panel_scene.instantiate()
	$CanvasLayer.add_child(debug_panel)
	
	# Configura o painel para monitorar o arqueiro
	var archer = get_node("CharacterBody2D")
	if archer:
		debug_panel.set_archer(archer)
	else:
		print("ERRO: Arqueiro não encontrado.")

func _on_talent_button_pressed():
	# Se já existe uma árvore de talentos aberta, não cria outra
	if talent_tree_instance:
		return
		
	# Cria a árvore de talentos
	talent_tree_instance = talent_tree_scene.instantiate()
	
	# Obtém o arqueiro
	var archer = get_node("CharacterBody2D")
	
	# Inicializa a árvore com o estado atual do arqueiro
	talent_tree_instance.initialize(archer.unlocked_talents, archer.talent_points, archer)
	
	# Conecta o sinal 'tree_closed' para atualizar o arqueiro quando fechar
	talent_tree_instance.tree_closed.connect(func():
		# Atualiza o estado do arqueiro
		archer.unlocked_talents = talent_tree_instance.get_unlocked_talents()
		archer.talent_points = talent_tree_instance.total_talent_points
		# Aplica os efeitos dos talentos
		archer.apply_talent_effects()
		# Limpa a referência
		talent_tree_instance = null
	)
	
	# Adiciona à cena
	$CanvasLayer.add_child(talent_tree_instance)

func _unhandled_input(event):
	if event.is_action_pressed("toggle_performance_monitor"):
		# Use o nome exato do singleton como está configurado
		var performance_monitor = get_tree().root.get_node_or_null("PoolPerformanceMonitor2")
		
		if performance_monitor:
			if performance_monitor.debug_label:
				# Alterna a visibilidade
				performance_monitor.debug_label.visible = !performance_monitor.debug_label.visible
				print("Visibilidade do monitor: ", performance_monitor.debug_label.visible)
			
			# Tenta imprimir o resumo
			print(performance_monitor.get_stats_summary())
		else:
			print("ERRO CRÍTICO: Monitor de desempenho NÃO ENCONTRADO")
