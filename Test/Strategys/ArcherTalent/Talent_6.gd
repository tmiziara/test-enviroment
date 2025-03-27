extends BaseProjectileStrategy
class_name Talent_6

# 20% do dano base será aplicado como dano de fogo
@export var fire_damage_percent: float = 0.20

# Chance de aplicar DoT
@export var dot_chance: float = 0.30  # 30% de chance de aplicar DoT

# DoT será uma porcentagem do dano base
@export var dot_percent_per_tick: float = 0.05   # 5% do dano base por tick
@export var dot_duration: float = 3.0           # Duração total do efeito em segundos
@export var dot_interval: float = 0.5           # Intervalo entre ticks de dano

# Propriedade para o sistema de debug
@export var talent_id: int = 6    # ID do talento correspondente

# Use get_strategy_name() em vez de get_class() para evitar conflitos
func get_strategy_name() -> String:
	return "Flaming Arrows"  # Nome amigável para o painel de debug

func apply_upgrade(projectile: Node) -> void:
	print("Aplicando upgrade de Flecha de Fogo!")
	
	# Adiciona tag de fogo ao projétil
	if not "tags" in projectile:
		projectile.tags = []
	
	if not "fire" in projectile.tags:
		projectile.tags.append("fire")
		print("Tag 'fire' adicionada")
	
	# Verifica o dano base para cálculos corretos
	var base_damage = get_base_damage(projectile)
	
	# Calcula o dano de fogo como porcentagem do dano base
	var fire_damage = calculate_fire_damage(base_damage)
	
	# Calcula o dano do DoT
	var dot_damage_per_tick = calculate_dot_damage(base_damage)
	
	# Aplica o dano de fogo e DoT ao projétil
	apply_fire_damage(projectile, fire_damage)
	setup_dot_processing(projectile, dot_damage_per_tick)
	
	# Conecta ao sinal on_hit para processar o DoT
	enhance_projectile_hit_processing(projectile)

# Obtém o dano base do projétil ou do DmgCalculator
func get_base_damage(projectile: Node) -> int:
	var base_damage = 10  # Valor padrão
	
	if projectile.has_node("DmgCalculatorComponent"):
		var dmg_calc = projectile.get_node("DmgCalculatorComponent")
		if "base_damage" in dmg_calc:
			base_damage = dmg_calc.base_damage
		elif "damage" in projectile:
			base_damage = projectile.damage
	elif "damage" in projectile:
		base_damage = projectile.damage
	
	return base_damage

# Calcula o dano de fogo baseado no dano base
func calculate_fire_damage(base_damage: int) -> int:
	var fire_damage = int(base_damage * fire_damage_percent)
	if fire_damage < 1:
		fire_damage = 1  # Garantir pelo menos 1 de dano de fogo
	return fire_damage

# Calcula o dano do DoT baseado no dano base
func calculate_dot_damage(base_damage: int) -> int:
	var dot_damage = int(base_damage * dot_percent_per_tick)
	if dot_damage < 1:
		dot_damage = 1  # Garantir pelo menos 1 de dano
	return dot_damage

# Aplica o dano de fogo ao projétil
func apply_fire_damage(projectile: Node, fire_damage: int) -> void:
	if projectile.has_node("DmgCalculatorComponent"):
		var dmg_calc = projectile.get_node("DmgCalculatorComponent")
		
		# Garante que o dicionário elemental_damage existe
		if not "elemental_damage" in dmg_calc:
			dmg_calc.elemental_damage = {}
		
		# Adiciona dano elemental de fogo
		if "fire" in dmg_calc.elemental_damage:
			dmg_calc.elemental_damage["fire"] += fire_damage
		else:
			dmg_calc.elemental_damage["fire"] = fire_damage
		
		print("Dano de fogo adicionado:", dmg_calc.elemental_damage["fire"], "(", fire_damage_percent * 100, "% do dano base)")
	else:
		# Caso não tenha DmgCalculator, aplicamos diretamente no projétil
		if projectile.has_meta("fire_damage"):
			projectile.set_meta("fire_damage", projectile.get_meta("fire_damage") + fire_damage)
		else:
			projectile.set_meta("fire_damage", fire_damage)
			
		print("Dano de fogo adicionado como meta:", fire_damage)

# Configura o processamento do DoT para o projétil
func setup_dot_processing(projectile: Node, dot_damage: int) -> void:
	# Adiciona os dados do DoT como um metadado
	projectile.set_meta("fire_dot_data", {
		"damage_per_tick": dot_damage,
		"duration": dot_duration,
		"interval": dot_interval,
		"type": "fire",
		"chance": dot_chance
	})
	
	print("Dados de DoT configurados:", dot_damage, "a cada", dot_interval, "s durante", dot_duration, "s, com chance de", dot_chance * 100, "%")
	
	# Se o projétil for uma Arrow, configura o processamento direto no process_on_hit
	if projectile is Arrow:
		# Guarda self como uma referência fraca no projétil
		projectile.set_meta("fire_dot_strategy", weakref(self))
		
		# Certifica-se de que a Arrow processe o DoT corretamente
		if not projectile.has_meta("has_fire_dot_processing"):
			projectile.set_meta("has_fire_dot_processing", true)
			
			# No caso da classe Arrow, ela já tem seu próprio process_on_hit
			# que vai ser chamado quando a flecha acertar um alvo
			
	elif projectile.has_method("process_on_hit"):
		# Para outros projéteis com process_on_hit, guarda a referência
		projectile.set_meta("fire_dot_strategy", weakref(self))
		projectile.set_meta("has_fire_dot_processing", true)

# Método para melhorar o processamento de hit do projétil
func enhance_projectile_hit_processing(projectile: Node) -> void:
	# Se for uma flecha Arrow, podemos nos conectar ao sinal on_hit
	if projectile is Arrow and projectile.has_signal("on_hit"):
		var signals = projectile.get_signal_connection_list("on_hit")
		var already_connected = false
		
		# Verifica se já está conectado para evitar conexões duplicadas
		for s in signals:
			if s.callable.get_object() == self:
				already_connected = true
				break
				
		if not already_connected:
			# Usa uma referência fraca para evitar erros de ciclo
			var self_ref = weakref(self)
			
			projectile.connect("on_hit", func(target, proj):
				if proj == projectile and is_instance_valid(target):
					var strategy = self_ref.get_ref()
					if strategy:
						strategy.apply_dot_chance(projectile, target)
			)
			
			print("Conectado ao sinal on_hit para processamento de DoT")
	
	# Se tiver um método process_hit_target, podemos configurar para verificar o meta
	if projectile.has_method("process_hit_target"):
		projectile.set_meta("check_dot_on_hit", true)
		projectile.set_meta("fire_dot_strategy", weakref(self))

# Método que aplica o DoT baseado na chance
func apply_dot_chance(projectile: Node, target: Node) -> void:
	if not projectile.has_meta("fire_dot_data"):
		return
		
	var dot_data = projectile.get_meta("fire_dot_data")
	var roll = randf()
	
	if roll <= dot_data.chance:
		print("DoT ativado! (rolou", roll, "<=", dot_data.chance, ")")
		
		# Verifica se o alvo tem HealthComponent para aplicar o DoT
		if target.has_node("HealthComponent"):
			var health_component = target.get_node("HealthComponent")
			
			# Certifica que o dano por tick é no mínimo 1
			var dot_damage = max(1, dot_data.damage_per_tick)
			
			# Aplica o DoT diretamente
			health_component.apply_dot(
				dot_damage,
				dot_data.duration,
				dot_data.interval,
				dot_data.type
			)
			
			print("DoT de fogo aplicado ao alvo com", dot_damage, "de dano por tick")
	else:
		print("DoT não ativado (rolou", roll, ">", dot_data.chance, ")")

# Método auxiliar para adicionar um DoT a um pacote de dano
func add_dot_to_damage_package(damage_package: Dictionary, projectile: Node) -> Dictionary:
	if not projectile.has_meta("fire_dot_data"):
		return damage_package
		
	var dot_data = projectile.get_meta("fire_dot_data")
	var roll = randf()
	
	if roll <= dot_data.chance:
		print("DoT adicionado ao pacote de dano! (rolou", roll, "<=", dot_data.chance, ")")
		
		# Adiciona o efeito DoT ao pacote
		if not "dot_effects" in damage_package:
			damage_package["dot_effects"] = []
		
		# Certifica que o dano por tick é no mínimo 1
		var dot_damage = max(1, dot_data.damage_per_tick)
		
		# Adiciona efeito de DoT
		damage_package["dot_effects"].append({
			"damage": dot_damage,
			"duration": dot_data.duration,
			"interval": dot_data.interval,
			"type": dot_data.type
		})
	else:
		print("DoT não adicionado ao pacote de dano (rolou", roll, ">", dot_data.chance, ")")
		
	return damage_package
