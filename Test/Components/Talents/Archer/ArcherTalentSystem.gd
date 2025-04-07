extends GenericTalentSystem
class_name ArcherTalentSystem

# Classe compilada específica para efeitos de arqueiro
class ArcherEffects extends CompiledEffects:
	# Efeitos básicos
	var damage_multiplier: float = 1.0
	var crit_chance_bonus: float = 0.0
	var crit_damage_multiplier: float = 1.0
	var armor_penetration: float = 0.0
	var range_multiplier: float = 1.0
	var attack_speed_multiplier: float = 1.0
	var piercing_count: int = 0
	
	# Efeitos de dano elemental
	var fire_damage_percent: float = 0.0
	var fire_dot_damage_percent: float = 0.0
	var fire_dot_duration: float = 0.0
	var fire_dot_interval: float = 0.0
	var fire_dot_chance: float = 0.0
	
	# Chain Shot properties
	var can_chain: bool = false
	var chain_chance: float = 0.0
	var chain_range: float = 0.0
	var chain_damage_decay: float = 0.0
	var max_chains: int = 0
	
	# Efeitos de múltiplos projéteis
	var double_shot_enabled: bool = false
	var double_shot_angle: float = 0.0
	var second_arrow_damage_modifier: float = 1.0
	
	# Efeitos especiais de acerto
	var focused_shot_enabled: bool = false
	var focused_shot_bonus: float = 0.0
	var focused_shot_threshold: float = 0.0
	
	var mark_enabled: bool = false
	var mark_duration: float = 0.0
	var mark_crit_bonus: float = 0.0
	
	var bleed_on_crit: bool = false
	var bleed_damage_percent: float = 0.0
	var bleed_duration: float = 0.0
	var bleed_interval: float = 0.0
	
	# Efeitos de área e outros
	var explosion_enabled: bool = false
	var explosion_damage_percent: float = 0.0
	var explosion_radius: float = 0.0
	
	var arrow_rain_enabled: bool = false
	var arrow_rain_count: int = 0
	var arrow_rain_damage_percent: float = 0.0
	var arrow_rain_radius: float = 0.0
	var arrow_rain_interval: int = 0
	
	var pressure_wave_enabled: bool = false
	var knockback_force: float = 0.0
	var slow_percent: float = 0.0
	var slow_duration: float = 0.0
	var ground_duration: float = 3.0
	
	var bloodseeker_enabled: bool = false
	var bloodseeker_bonus_per_stack: float = 0.0
	var bloodseeker_max_stacks: int = 0
	
	# Override do método copy
	func copy() -> ArcherEffects:
		var new_effects = ArcherEffects.new()
		
		# Copia propriedades básicas
		new_effects.damage_multiplier = self.damage_multiplier
		new_effects.crit_chance_bonus = self.crit_chance_bonus
		new_effects.crit_damage_multiplier = self.crit_damage_multiplier
		new_effects.armor_penetration = self.armor_penetration
		new_effects.range_multiplier = self.range_multiplier
		new_effects.attack_speed_multiplier = self.attack_speed_multiplier
		new_effects.piercing_count = self.piercing_count
		
		# Efeitos elementais
		new_effects.fire_damage_percent = self.fire_damage_percent
		new_effects.fire_dot_damage_percent = self.fire_dot_damage_percent
		new_effects.fire_dot_duration = self.fire_dot_duration
		new_effects.fire_dot_interval = self.fire_dot_interval
		new_effects.fire_dot_chance = self.fire_dot_chance
		
		# Chain shot
		new_effects.can_chain = self.can_chain
		new_effects.chain_chance = self.chain_chance
		new_effects.chain_range = self.chain_range
		new_effects.chain_damage_decay = self.chain_damage_decay
		new_effects.max_chains = self.max_chains
		
		# Double shot
		new_effects.double_shot_enabled = self.double_shot_enabled
		new_effects.double_shot_angle = self.double_shot_angle
		new_effects.second_arrow_damage_modifier = self.second_arrow_damage_modifier
		
		# Efeitos especiais
		new_effects.focused_shot_enabled = self.focused_shot_enabled
		new_effects.focused_shot_bonus = self.focused_shot_bonus
		new_effects.focused_shot_threshold = self.focused_shot_threshold
		
		new_effects.mark_enabled = self.mark_enabled
		new_effects.mark_duration = self.mark_duration
		new_effects.mark_crit_bonus = self.mark_crit_bonus
		
		new_effects.bleed_on_crit = self.bleed_on_crit
		new_effects.bleed_damage_percent = self.bleed_damage_percent
		new_effects.bleed_duration = self.bleed_duration
		new_effects.bleed_interval = self.bleed_interval
		
		# Efeitos de área
		new_effects.explosion_enabled = self.explosion_enabled
		new_effects.explosion_damage_percent = self.explosion_damage_percent
		new_effects.explosion_radius = self.explosion_radius
		
		new_effects.arrow_rain_enabled = self.arrow_rain_enabled
		new_effects.arrow_rain_count = self.arrow_rain_count
		new_effects.arrow_rain_damage_percent = self.arrow_rain_damage_percent
		new_effects.arrow_rain_radius = self.arrow_rain_radius
		new_effects.arrow_rain_interval = self.arrow_rain_interval
		
		new_effects.pressure_wave_enabled = self.pressure_wave_enabled
		new_effects.knockback_force = self.knockback_force
		new_effects.slow_percent = self.slow_percent
		new_effects.slow_duration = self.slow_duration
		new_effects.ground_duration = self.ground_duration
		
		new_effects.bloodseeker_enabled = self.bloodseeker_enabled
		new_effects.bloodseeker_bonus_per_stack = self.bloodseeker_bonus_per_stack
		new_effects.bloodseeker_max_stacks = self.bloodseeker_max_stacks
		
		return new_effects

# Inicializa o sistema para um arqueiro específico
func _init(archer: SoldierBase):
	super._init(archer)
	
	# Registra processadores específicos para estratégias de arqueiro
	_register_archer_processors()

# Função para compilar efeitos específicos de arqueiro
func compile_archer_effects() -> ArcherEffects:
	return compile_effects(ArcherEffects) as ArcherEffects

# Registra processadores de estratégia para arqueiro
func _register_archer_processors():
	# Exemplos de registro para algumas estratégias comuns
	register_strategy_processor("PreciseAim", _process_precise_aim)
	register_strategy_processor("EnhancedRange", _process_enhanced_range)
	register_strategy_processor("SharpArrows", _process_sharp_arrows)
	register_strategy_processor("PiercingShot", _process_piercing_shot)
	register_strategy_processor("FlamingArrows", _process_flaming_arrows)
	register_strategy_processor("DoubleShot", _process_double_shot)
	register_strategy_processor("ChainShot", _process_chain_shot)
	register_strategy_processor("ArrowRain", _process_arrow_rain)
	
	# Registra processadores por números de talento
	register_strategy_processor("Talent_1", _process_precise_aim)
	register_strategy_processor("Talent_2", _process_enhanced_range)
	register_strategy_processor("Talent_3", _process_sharp_arrows)
	register_strategy_processor("Talent_4", _process_piercing_shot)
	register_strategy_processor("Talent_6", _process_flaming_arrows)
	register_strategy_processor("Talent_11", _process_double_shot)
	register_strategy_processor("Talent_12", _process_chain_shot)
	register_strategy_processor("Talent_13", _process_arrow_rain)
	# ... outros processadores

# Processadores específicos para cada tipo de estratégia
func _process_precise_aim(strategy, effects: ArcherEffects):
	var damage_bonus = strategy.get("damage_increase_percent")
	if damage_bonus != null:
		effects.damage_multiplier += damage_bonus / 100.0

func _process_enhanced_range(strategy, effects: ArcherEffects):
	var range_bonus = strategy.get("range_increase_percentage")
	if range_bonus != null:
		effects.range_multiplier += range_bonus / 100.0

func _process_sharp_arrows(strategy, effects: ArcherEffects):
	var armor_pen = strategy.get("armor_penetration")
	if armor_pen != null:
		effects.armor_penetration += armor_pen

func _process_piercing_shot(strategy, effects: ArcherEffects):
	var pierce_count = strategy.get("piercing_count")
	if pierce_count != null:
		effects.piercing_count += pierce_count

func _process_flaming_arrows(strategy, effects: ArcherEffects):
	var fire_damage_percent = strategy.get("fire_damage_percent")
	var dot_percent_per_tick = strategy.get("dot_percent_per_tick")
	var dot_duration = strategy.get("dot_duration")
	var dot_interval = strategy.get("dot_interval")
	var dot_chance = strategy.get("dot_chance")
	
	if fire_damage_percent != null:
		effects.fire_damage_percent += fire_damage_percent
	if dot_percent_per_tick != null:
		effects.fire_dot_damage_percent += dot_percent_per_tick
	if dot_duration != null:
		effects.fire_dot_duration = max(effects.fire_dot_duration, dot_duration)
	if dot_interval != null:
		effects.fire_dot_interval = dot_interval
	if dot_chance != null:
		effects.fire_dot_chance = max(effects.fire_dot_chance, dot_chance)

func _process_double_shot(strategy, effects: ArcherEffects):
	var angle_spread = strategy.get("angle_spread")
	var damage_mod = strategy.get("second_arrow_damage_modifier")
	
	effects.double_shot_enabled = true
	
	if angle_spread != null:
		effects.double_shot_angle = angle_spread
	if damage_mod != null:
		effects.second_arrow_damage_modifier = damage_mod

func _process_chain_shot(strategy, effects: ArcherEffects):
	var chain_chance = strategy.get("chain_chance")
	var chain_range = strategy.get("chain_range")
	var chain_decay = strategy.get("chain_damage_decay")
	var max_chains = strategy.get("max_chains")
	
	effects.can_chain = true
	
	if chain_chance != null:
		effects.chain_chance = chain_chance
	if chain_range != null:
		effects.chain_range = chain_range
	if chain_decay != null:
		effects.chain_damage_decay = chain_decay
	if max_chains != null:
		effects.max_chains = max_chains

func _process_arrow_rain(strategy, effects: ArcherEffects):
	var arrow_count = strategy.get("arrow_count")
	var damage_per_arrow = strategy.get("damage_per_arrow")
	var radius = strategy.get("radius")
	var attacks_threshold = strategy.get("attacks_threshold")
	
	effects.arrow_rain_enabled = true
	
	if arrow_count != null:
		effects.arrow_rain_count = arrow_count
	if damage_per_arrow != null:
		effects.arrow_rain_damage_percent = damage_per_arrow
	if radius != null:
		effects.arrow_rain_radius = radius
	if attacks_threshold != null:
		effects.arrow_rain_interval = attacks_threshold

# Método para aplicar efeitos compilados a um projétil
func apply_effects_to_projectile(projectile: Node, effects: ArcherEffects) -> void:
	# Aplica efeitos básicos
	_apply_base_stats(projectile, effects)
	
	# Aplica efeitos elementais
	_apply_elemental_effects(projectile, effects)
	
	# Aplica efeitos de movimento
	_apply_movement_effects(projectile, effects)
	
	# Aplica habilidades especiais
	_apply_special_abilities(projectile, effects)

# Aplicação de efeitos específicos (dividido para clareza)
func _apply_base_stats(projectile: Node, effects: ArcherEffects) -> void:
	if "damage" in projectile:
		projectile.damage = int(projectile.damage * effects.damage_multiplier)
	
	if "crit_chance" in projectile:
		projectile.crit_chance = min(projectile.crit_chance + effects.crit_chance_bonus, 1.0)
	
	# Atualiza o DmgCalculatorComponent
	if projectile.has_node("DmgCalculatorComponent"):
		var dmg_calc = projectile.get_node("DmgCalculatorComponent")
		
		if "base_damage" in dmg_calc:
			dmg_calc.base_damage = int(dmg_calc.base_damage * effects.damage_multiplier)
		
		if "damage_multiplier" in dmg_calc:
			dmg_calc.damage_multiplier = effects.damage_multiplier
		
		if effects.armor_penetration > 0:
			dmg_calc.armor_penetration = effects.armor_penetration
			_ensure_tag(projectile, "armor_piercing")

func _apply_elemental_effects(projectile: Node, effects: ArcherEffects) -> void:
	# Aplica efeitos de fogo
	if effects.fire_damage_percent > 0:
		_ensure_tag(projectile, "fire")
		
		if projectile.has_node("DmgCalculatorComponent"):
			var dmg_calc = projectile.get_node("DmgCalculatorComponent")
			var total_damage = dmg_calc.calculate_damage()
			
			# Adiciona dano elemental de fogo
			var fire_damage = int(total_damage["physical_damage"] * effects.fire_damage_percent)
			if "elemental_damage" in dmg_calc:
				if "fire" in dmg_calc.elemental_damage:
					dmg_calc.elemental_damage["fire"] += fire_damage
				else:
					dmg_calc.elemental_damage["fire"] = fire_damage
			
			# Configura dados de DoT
			if effects.fire_dot_damage_percent > 0:
				var dot_data = {
					"damage_per_tick": int(total_damage["physical_damage"] * effects.fire_dot_damage_percent),
					"duration": effects.fire_dot_duration,
					"interval": effects.fire_dot_interval,
					"chance": effects.fire_dot_chance,
					"type": "fire"
				}
				dmg_calc.set_meta("fire_dot_data", dot_data)

func _apply_movement_effects(projectile: Node, effects: ArcherEffects) -> void:
	# Aplica piercing
	if effects.piercing_count > 0:
		projectile.piercing = true
		projectile.set_meta("piercing_count", effects.piercing_count)
		_ensure_tag(projectile, "piercing")
		
		# Para projéteis físicos, desabilita colisão com inimigos
		if projectile is CharacterBody2D:
			projectile.set_collision_mask_value(2, false)

func _apply_special_abilities(projectile: Node, effects: ArcherEffects) -> void:
	# Double Shot
	if effects.double_shot_enabled:
		projectile.set_meta("double_shot_enabled", true)
		projectile.set_meta("double_shot_angle", effects.double_shot_angle)
		projectile.set_meta("second_arrow_damage_modifier", effects.second_arrow_damage_modifier)
		_ensure_tag(projectile, "double_shot")
	
	# Chain Shot
	if effects.can_chain:
		_setup_chain_shot(projectile, effects)
	
	# Arrow Rain
	if effects.arrow_rain_enabled and not projectile.has_meta("is_rain_arrow"):
		projectile.set_meta("arrow_rain_enabled", true)
		projectile.set_meta("arrow_rain_count", effects.arrow_rain_count)
		projectile.set_meta("arrow_rain_damage_percent", effects.arrow_rain_damage_percent)
		projectile.set_meta("arrow_rain_radius", effects.arrow_rain_radius)
		projectile.set_meta("arrow_rain_interval", effects.arrow_rain_interval)
		_ensure_tag(projectile, "arrow_rain")
	
	# Focused Shot
	if effects.focused_shot_enabled:
		projectile.set_meta("focused_shot_enabled", true)
		projectile.set_meta("focused_shot_bonus", effects.focused_shot_bonus)
		projectile.set_meta("focused_shot_threshold", effects.focused_shot_threshold)
		_ensure_tag(projectile, "focused_shot")
	
	# Mark for Death
	if effects.mark_enabled:
		projectile.set_meta("has_mark_effect", true)
		projectile.set_meta("mark_duration", effects.mark_duration)
		projectile.set_meta("mark_crit_bonus", effects.mark_crit_bonus)
		_ensure_tag(projectile, "marked_for_death")
	
	# Bloodseeker
	if effects.bloodseeker_enabled:
		projectile.set_meta("has_bloodseeker_effect", true)
		projectile.set_meta("damage_increase_per_stack", effects.bloodseeker_bonus_per_stack)
		projectile.set_meta("max_stacks", effects.bloodseeker_max_stacks)
		_ensure_tag(projectile, "bloodseeker")
	
	# Pressure Wave
	if effects.pressure_wave_enabled and (projectile.has_meta("arrow_rain_enabled") or projectile.has_meta("is_rain_arrow")):
		projectile.set_meta("pressure_wave_enabled", true)
		projectile.set_meta("knockback_force", effects.knockback_force)
		projectile.set_meta("slow_percent", effects.slow_percent)
		projectile.set_meta("slow_duration", effects.slow_duration)
		projectile.set_meta("wave_visual_enabled", true)
		projectile.set_meta("ground_duration", effects.ground_duration)
		_ensure_tag(projectile, "pressure_wave")

# Utilitário para configurar Chain Shot
func _setup_chain_shot(projectile, effects: ArcherEffects) -> void:
	# Configuração específica para flechas reais
	if "chain_shot_enabled" in projectile:
		projectile.chain_shot_enabled = true
		projectile.chain_chance = effects.chain_chance
		projectile.chain_range = effects.chain_range
		projectile.chain_damage_decay = effects.chain_damage_decay
		projectile.max_chains = effects.max_chains
		projectile.current_chains = 0
		projectile.will_chain = false
	else:
		# Para outros tipos de projéteis, usa metadados
		projectile.set_meta("chain_shot_enabled", true)
		projectile.set_meta("chain_chance", effects.chain_chance)
		projectile.set_meta("chain_range", effects.chain_range)
		projectile.set_meta("chain_damage_decay", effects.chain_damage_decay)
		projectile.set_meta("max_chains", effects.max_chains)
		projectile.set_meta("current_chains", 0)
		projectile.set_meta("will_chain", null)
		projectile.set_meta("hit_targets", [])
	
	# Adiciona tag
	_ensure_tag(projectile, "chain_shot")

# Utilitário para garantir que uma tag existe
func _ensure_tag(projectile: Node, tag_name: String) -> void:
	if not "tags" in projectile:
		projectile.tags = []
	
	# Garante que projectile tenha o método add_tag
	if not projectile.has_method("add_tag"):
		projectile.add_tag = func(tag: String) -> void:
			if not tag in projectile.tags:
				projectile.tags.append(tag)
	
	projectile.add_tag(tag_name)

# Método para aplicar efeitos compilados a um soldado arqueiro
func apply_effects_to_soldier(archer: ArcherBase, effects: ArcherEffects) -> void:
	# Aplica modificadores de estatísticas
	archer.damage_multiplier = effects.damage_multiplier
	archer.range_multiplier = effects.range_multiplier
	archer.cooldown_multiplier = 1.0 / max(0.01, effects.attack_speed_multiplier)  # Inverte pois cooldown é o inverso da velocidade
	
	# Aplica modificadores elementais
	archer.fire_damage_modifier = effects.fire_damage_percent
	
	# Define penetração de armadura
	archer.armor_penetration = effects.armor_penetration
	
	# Configura Double Shot
	if effects.double_shot_enabled:
		archer.set_meta("double_shot_active", true)
		archer.set_meta("double_shot_angle", effects.double_shot_angle)
		archer.set_meta("double_shot_damage_modifier", effects.second_arrow_damage_modifier)
	else:
		# Limpa metadados se Double Shot não estiver ativo
		if archer.has_meta("double_shot_active"):
			archer.remove_meta("double_shot_active")
	
	# Armazena compiled_effects para uso futuro
	archer.set_meta("compiled_effects", effects)# Método para lidar com mudanças de alvo
func _on_target_change(new_target: Node) -> void:
	# Se não houver alvo novo ou não for válido, ignora
	if not new_target or not is_instance_valid(new_target):
		return
		
	# Reseta stacks do Bloodseeker quando alvo muda
	_reset_bloodseeker_stacks()

# Método para resetar stacks do Bloodseeker
func _reset_bloodseeker_stacks() -> void:
	if not soldier:
		return
		
	# Se o soldier tem dados de Bloodseeker, reseta
	if soldier.has_meta("bloodseeker_data"):
		var data = soldier.get_meta("bloodseeker_data")
		data["target"] = null
		data["target_instance_id"] = -1
		data["stacks"] = 0
		soldier.set_meta("bloodseeker_data", data)
		
		# Remove visualização
		_remove_bloodseeker_stack_visual()

# Remove a visualização de stacks do Bloodseeker
func _remove_bloodseeker_stack_visual() -> void:
	if not soldier or not is_instance_valid(soldier):
		return
		
	if soldier.has_meta("bloodseeker_visual"):
		var visual = soldier.get_meta("bloodseeker_visual")
		if visual and is_instance_valid(visual):
			visual.queue_free()
		soldier.remove_meta("bloodseeker_visual")

# Aplica hit do Bloodseeker
func apply_bloodseeker_hit(target: Node) -> void:
	# Verificações básicas
	if not soldier or not target or not is_instance_valid(target):
		return
	
	# Compila efeitos para obter configuração do Bloodseeker
	var effects = compile_archer_effects()
	
	# Verifica se Bloodseeker está ativo
	if not "bloodseeker_enabled" in effects or not effects.bloodseeker_enabled:
		return
	
	# Inicializa estrutura de dados se necessário
	if not soldier.has_meta("bloodseeker_data"):
		soldier.set_meta("bloodseeker_data", {
			"target": null,
			"stacks": 0,
			"last_hit_time": 0,
			"target_instance_id": -1
		})
	
	var data = soldier.get_meta("bloodseeker_data")
	var current_target = data["target"]
	var current_target_id = data["target_instance_id"]
	var target_id = target.get_instance_id()
	
	# Atualiza timestamp
	data["last_hit_time"] = Time.get_ticks_msec()
	
	# Verifica se é um novo alvo comparando IDs de instância
	if target_id != current_target_id:
		# Novo alvo, reseta stacks para 1
		data["target"] = target
		data["target_instance_id"] = target_id
		data["stacks"] = 1
	else:
		# Mesmo alvo, incrementa stacks até o máximo
		var stacks = data["stacks"]
		var max_stacks = effects.bloodseeker_max_stacks
		stacks = min(stacks + 1, max_stacks)
		data["stacks"] = stacks
	
	# Atualiza metadados
	soldier.set_meta("bloodseeker_data", data)
	
	# Cria indicador visual
	_create_bloodseeker_stack_visual(data["stacks"], effects.bloodseeker_max_stacks)

# Cria visual do Bloodseeker
func _create_bloodseeker_stack_visual(stacks: int, max_stacks: int) -> void:
	if not soldier or not is_instance_valid(soldier):
		return
		
	# Primeiro remove qualquer indicador existente
	_remove_bloodseeker_stack_visual()
	
	# Não mostra nada para 0 stacks
	if stacks <= 0:
		return
	
	# Cria container
	var container = Control.new()
	container.name = "BloodseekerStackDisplay"
	container.position = Vector2(-40, -40)
	container.z_index = 100
	
	# Largura para o indicador
	var total_width = 16 * min(stacks, max_stacks)
	container.custom_minimum_size = Vector2(total_width, 16)
	
	# Cria indicador com texto
	var label = Label.new()
	label.text = str(stacks) + "x"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size_flags_horizontal = Control.SIZE_FILL
	label.size_flags_vertical = Control.SIZE_FILL
	
	# Aplica cor
	var font_color = Color(1.0, 0.2, 0.2)
	label.add_theme_color_override("font_color", font_color)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	
	# Adiciona label ao container
	container.add_child(label)
	
	# Adiciona ao soldier
	soldier.add_child(container)
	
	# Armazena referência ao container
	soldier.set_meta("bloodseeker_visual", container)
	
	# Adiciona animação
	var tween = container.create_tween()
	tween.tween_property(container, "scale", Vector2(1.2, 1.2), 0.25)
	tween.tween_property(container, "scale", Vector2(1.0, 1.0), 0.25)
	
	# Animação especial para stacks máximos
	if stacks >= max_stacks:
		var max_tween = container.create_tween()
		max_tween.tween_property(container, "modulate", Color(1.0, 0.5, 0.0, 1.0), 0.3)
		max_tween.tween_property(container, "modulate", Color(1.0, 0.0, 0.0, 1.0), 0.3)
		max_tween.set_loops(2)
