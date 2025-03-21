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
	
	# Verifica se temos acesso ao atirador para criar a segunda flecha
	if not "shooter" in projectile or not projectile.shooter:
		print("ERRO: Não foi possível acessar o atirador para o Double Shot")
		return
		
	# Verifica se é um projétil válido
	if not projectile is CharacterBody2D:
		print("ERRO: O projétil não é um CharacterBody2D")
		return
		
	# Pega referências importantes
	var shooter = projectile.shooter
	var direction = projectile.direction
	var start_position = projectile.global_position
	
	# Carrega a cena da flecha
	var arrow_scene = load("res://Test/Projectiles/Archer/Arrow.tscn")
	if not arrow_scene:
		print("ERRO: Não foi possível carregar a cena da flecha")
		return
		
	# Cria a segunda flecha com uma pequena variação de ângulo
	var second_arrow = arrow_scene.instantiate()
	
	# Configura posição e direção com desvio angular
	second_arrow.global_position = start_position
	var angle_offset = deg_to_rad(angle_spread)
	var rotated_direction = direction.rotated(angle_offset)
	second_arrow.direction = rotated_direction
	second_arrow.rotation = rotated_direction.angle()
	
	# Configura outras propriedades
	second_arrow.shooter = shooter
	second_arrow.damage = int(projectile.damage * second_arrow_damage_mult)
	
	# Copia tags da flecha original, exceto double_shot para evitar recursão
	if "tags" in projectile and projectile.tags is Array:
		second_arrow.tags = projectile.tags.duplicate()
		if "double_shot" in second_arrow.tags:
			second_arrow.tags.erase("double_shot")
	
	# Se a flecha original tem um DmgCalculatorComponent, configura o da segunda flecha
	if projectile.has_node("DmgCalculatorComponent") and second_arrow.has_node("DmgCalculatorComponent"):
		var original_calc = projectile.get_node("DmgCalculatorComponent")
		var second_calc = second_arrow.get_node("DmgCalculatorComponent")
		
		# Copia configurações básicas
		second_calc.base_damage = int(original_calc.base_damage * second_arrow_damage_mult)
		
		# Copia dano elemental (se existir)
		if "elemental_damage" in original_calc and original_calc.elemental_damage is Dictionary:
			second_calc.elemental_damage = original_calc.elemental_damage.duplicate()
			
		# Copia efeitos DoT (se existirem)
		if "dot_effects" in original_calc and original_calc.dot_effects is Array:
			# Em vez de copiar diretamente (que pode causar problemas de referência)
			# vamos recriar os efeitos DoT
			for dot_effect in original_calc.dot_effects:
				second_calc.add_dot_effect(
					dot_effect.get("damage", 0),
					dot_effect.get("duration", 0),
					dot_effect.get("interval", 1.0),
					dot_effect.get("type", "generic")
				)
	
	# Adiciona a segunda flecha à cena
	if shooter and shooter.get_parent():
		shooter.get_parent().call_deferred("add_child", second_arrow)
		print("Segunda flecha gerada pelo Double Shot")
	else:
		print("ERRO: Não foi possível adicionar a segunda flecha à cena")
