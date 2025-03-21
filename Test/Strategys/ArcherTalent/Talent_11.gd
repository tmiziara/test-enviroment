extends BaseProjectileStrategy
class_name Talent_11

# Configuração para tiro duplo
@export var angle_spread: float = 1.0  # Separação angular entre as flechas em graus
@export var second_arrow_damage_mult: float = 1.0  # Multiplicador de dano para a segunda flecha

# Propriedade para o sistema de debug
@export var talent_id: int = 11    # ID do talento correspondente

# Use get_strategy_name() em vez de get_class() para evitar conflitos
func get_strategy_name() -> String:
	return "DoubleShotStrategy"  # Nome amigável para o painel de debug

func apply_upgrade(projectile: Node) -> void:
	print("Aplicando upgrade de Tiro Duplo!")
	
	# Verificações de segurança (código atual)...
	
	# Pega referências importantes
	var shooter = projectile.shooter
	var direction = projectile.direction
	var start_position = projectile.global_position
	
	# Carrega a cena da flecha
	var arrow_scene = load("res://Test/Projectiles/Archer/Arrow.tscn")
	if not arrow_scene:
		print("ERRO: Não foi possível carregar a cena da flecha")
		return
		
	# Cria a segunda flecha
	var second_arrow = arrow_scene.instantiate()
	
	# Configura posição e direção com desvio angular
	second_arrow.global_position = start_position
	var angle_offset = deg_to_rad(angle_spread)
	var rotated_direction = direction.rotated(angle_offset)
	second_arrow.direction = rotated_direction
	second_arrow.rotation = rotated_direction.angle()
	
	# Configura o atirador (IMPORTANTE: faça isso antes de adicionar à árvore)
	second_arrow.shooter = shooter
	
	# Adiciona a tag de double_shot para evitar recursão infinita
	if "add_tag" in second_arrow:
		second_arrow.add_tag("double_shot")
	
	# NOVO: Obtém as outras estratégias para aplicar
	var other_strategies = []
	# Verifica se o shooter é do tipo esperado
	if shooter is Soldier_Base:
		# Se for um Soldier_Base, podemos acessar attack_upgrades com segurança
		for strategy in shooter.attack_upgrades:
			if not strategy is Talent_11:
				other_strategies.append(strategy)
	else:
		print("AVISO: Atirador não é um Soldier_Base, não foi possível obter upgrades.")
	
	# Adiciona a segunda flecha à cena
	if shooter and shooter.get_parent():
		shooter.get_parent().call_deferred("add_child", second_arrow)
		print("Segunda flecha gerada pelo Double Shot")
		
		# NOVO: Aplica as outras estratégias à flecha secundária
		for strategy in other_strategies:
			if strategy and is_instance_valid(strategy):
				strategy.apply_upgrade(second_arrow)
				print("Aplicando estratégia à flecha secundária:", strategy.get_strategy_name() if strategy.has_method("get_strategy_name") else "Estratégia")
	else:
		print("ERRO: Não foi possível adicionar a segunda flecha à cena")
