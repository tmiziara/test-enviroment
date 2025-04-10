extends GenericTalentSystem
class_name ArcherTalentSystem

# Mapeamento de alvos para cada tipo de estratégia
var _strategy_targets = {
	"PreciseAim": "archer",           # Afeta apenas o arqueiro (dano)
	"EnhancedRange": "archer",        # Afeta apenas o arqueiro (alcance)
	"SharpArrows": "projectile",      # Afeta apenas o projétil
	"PiercingShot": "projectile",     # Afeta apenas o projétil
	"FlamingArrows": "projectile",    # Afeta apenas o projétil
	"DoubleShot": "both",             # Afeta ambos
	"ChainShot": "projectile",        # Afeta apenas o projétil
	"ArrowRain": "both",              # Afeta ambos
	"PressureWave": "both",           # Afeta ambos
	"FocusedShot": "projectile",      # Afeta apenas o projétil
	"MarkedForDeath": "projectile",   # Afeta apenas o projétil
	"Bloodseeker": "both",            # Afeta ambos
	"SerratedArrows": "projectile",   # Afeta apenas o projétil
	"ExplosiveArrows": "projectile",  # Afeta apenas o projétil
}

# Mapeamento por IDs para compatibilidade
var _talent_id_targets = {
	"Talent_1": "archer",     # PreciseAim
	"Talent_2": "archer",     # EnhancedRange
	"Talent_3": "projectile", # SharpArrows
	"Talent_4": "projectile", # PiercingShot
	"Talent_5": "projectile", # FocusedShot
	"Talent_6": "projectile", # FlamingArrows
	"Talent_11": "both",      # DoubleShot
	"Talent_12": "projectile", # ChainShot
	"Talent_13": "both",      # ArrowRain
	"Talent_14": "both",      # PressureWave
	"Talent_15": "projectile", # ArrowExplosion
	"Talent_16": "projectile", # SerratedArrows
	"Talent_17": "projectile", # MarkedForDeath
	"Talent_18": "projectile"  # Bloodseeker
}

# Flag de debug
var debug_mode: bool = false

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
	register_strategy_processor("FocusedShot", _process_focused_shot)
	register_strategy_processor("MarkedForDeath", _process_marked_for_death)
	register_strategy_processor("Bloodseeker", _process_bloodseeker)
	
	# Registra processadores por números de talento
	register_strategy_processor("Talent_1", _process_precise_aim)
	register_strategy_processor("Talent_2", _process_enhanced_range)
	register_strategy_processor("Talent_3", _process_sharp_arrows)
	register_strategy_processor("Talent_4", _process_piercing_shot)
	register_strategy_processor("Talent_5", _process_focused_shot)
	register_strategy_processor("Talent_6", _process_flaming_arrows)
	register_strategy_processor("Talent_11", _process_double_shot)
	register_strategy_processor("Talent_12", _process_chain_shot)
	register_strategy_processor("Talent_13", _process_arrow_rain)
	register_strategy_processor("Talent_14", _process_pressure_wave)
	register_strategy_processor("Talent_15", _process_explosion)
	register_strategy_processor("Talent_16", _process_serrated_arrows)
	register_strategy_processor("Talent_17", _process_marked_for_death)
	register_strategy_processor("Talent_18", _process_bloodseeker)

# Processadores específicos para cada tipo de estratégia
func _process_precise_aim(strategy, effects: ArcherEffects):
	var damage_bonus = strategy.get("damage_increase_percent")
	if damage_bonus != null:
		effects.damage_multiplier += damage_bonus / 100.0
		
		if debug_mode:
			print("Precise Aim: Added damage bonus ", damage_bonus, "%")

func _process_enhanced_range(strategy, effects: ArcherEffects):
	var range_bonus = strategy.get("range_increase_percentage")
	if range_bonus != null:
		effects.range_multiplier += range_bonus / 100.0
		
		if debug_mode:
			print("Enhanced Range: Added range bonus ", range_bonus, "%")

func _process_sharp_arrows(strategy, effects: ArcherEffects):
	var armor_pen = strategy.get("armor_penetration")
	if armor_pen != null:
		effects.armor_penetration += armor_pen
		
		if debug_mode:
			print("Sharp Arrows: Added armor penetration ", armor_pen)

func _process_piercing_shot(strategy, effects: ArcherEffects):
	var pierce_count = strategy.get("piercing_count")
	if pierce_count != null:
		effects.piercing_count += pierce_count
		
		if debug_mode:
			print("Piercing Shot: Added pierce count ", pierce_count)

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
		
	if debug_mode:
		print("Flaming Arrows: Fire damage ", fire_damage_percent, 
			  ", DoT damage ", dot_percent_per_tick, 
			  ", duration ", dot_duration)

func _process_double_shot(strategy, effects: ArcherEffects):
	var angle_spread = strategy.get("angle_spread")
	var damage_mod = strategy.get("second_arrow_damage_modifier")
	
	effects.double_shot_enabled = true
	
	if angle_spread != null:
		effects.double_shot_angle = angle_spread
	if damage_mod != null:
		effects.second_arrow_damage_modifier = damage_mod
		
	if debug_mode:
		print("Double Shot: Angle ", angle_spread, ", damage mod ", damage_mod)

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
		
	if debug_mode:
		print("Chain Shot: Chance ", chain_chance, ", range ", chain_range,
			  ", max chains ", max_chains)

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
		
	if debug_mode:
		print("Arrow Rain: Count ", arrow_count, ", damage ", damage_per_arrow,
			  ", radius ", radius, ", interval ", attacks_threshold)

func _process_focused_shot(strategy, effects: ArcherEffects):
	var bonus = strategy.get("damage_bonus")
	var threshold = strategy.get("health_threshold")
	
	effects.focused_shot_enabled = true
	
	if bonus != null:
		effects.focused_shot_bonus = bonus
	if threshold != null:
		effects.focused_shot_threshold = threshold
		
	if debug_mode:
		print("Focused Shot: Bonus ", bonus, ", threshold ", threshold)

func _process_marked_for_death(strategy, effects: ArcherEffects):
	var duration = strategy.get("mark_duration")
	var crit_bonus = strategy.get("crit_damage_bonus")
	
	effects.mark_enabled = true
	
	if duration != null:
		effects.mark_duration = duration
	if crit_bonus != null:
		effects.mark_crit_bonus = crit_bonus
		
	if debug_mode:
		print("Mark for Death: Duration ", duration, ", crit bonus ", crit_bonus)

func _process_bloodseeker(strategy, effects: ArcherEffects):
	var bonus_per_stack = strategy.get("damage_per_stack")
	var max_stacks = strategy.get("max_stacks")
	
	effects.bloodseeker_enabled = true
	
	if bonus_per_stack != null:
		effects.bloodseeker_bonus_per_stack = bonus_per_stack
	if max_stacks != null:
		effects.bloodseeker_max_stacks = max_stacks
		
	if debug_mode:
		print("Bloodseeker: Bonus per stack ", bonus_per_stack, ", max stacks ", max_stacks)

func _process_pressure_wave(strategy, effects: ArcherEffects):
	var knockback = strategy.get("knockback_force")
	var slow = strategy.get("slow_percent")
	var slow_duration = strategy.get("slow_duration")
	var ground_duration = strategy.get("ground_duration")
	
	effects.pressure_wave_enabled = true
	
	if knockback != null:
		effects.knockback_force = knockback
	if slow != null:
		effects.slow_percent = slow
	if slow_duration != null:
		effects.slow_duration = slow_duration
	if ground_duration != null:
		effects.ground_duration = ground_duration
		
	if debug_mode:
		print("Pressure Wave: Knockback ", knockback, ", slow ", slow,
			  ", slow duration ", slow_duration)

func _process_explosion(strategy, effects: ArcherEffects):
	var damage_percent = strategy.get("damage_percent")
	var radius = strategy.get("radius")
	
	effects.explosion_enabled = true
	
	if damage_percent != null:
		effects.explosion_damage_percent = damage_percent
	if radius != null:
		effects.explosion_radius = radius
		
	if debug_mode:
		print("Explosion: Damage ", damage_percent, ", radius ", radius)

func _process_serrated_arrows(strategy, effects: ArcherEffects):
	var bleed_chance = strategy.get("bleed_chance")
	var bleed_percent = strategy.get("bleed_damage_percent")
	var bleed_duration = strategy.get("bleed_duration")
	var bleed_interval = strategy.get("bleed_interval")
	
	effects.bleed_on_crit = true
	
	if bleed_percent != null:
		effects.bleed_damage_percent = bleed_percent
	if bleed_duration != null:
		effects.bleed_duration = bleed_duration
	if bleed_interval != null:
		effects.bleed_interval = bleed_interval
		
	if debug_mode:
		print("Serrated Arrows: Bleed damage ", bleed_percent, 
			  ", duration ", bleed_duration)

# Determina se um talent deve ser aplicado ao arqueiro, projétil ou ambos
func should_apply_to_target(strategy, target_type: String) -> bool:
	var strategy_name = _get_strategy_type(strategy)
	
	# Primeiro verifica no dicionário de estratégias
	if strategy_name in _strategy_targets:
		var strategy_target = _strategy_targets[strategy_name]
		return strategy_target == target_type or strategy_target == "both"
	
	# Depois verifica no dicionário de IDs (para compatibilidade)
	if strategy_name in _talent_id_targets:
		var talent_target = _talent_id_targets[strategy_name]
		return talent_target == target_type or talent_target == "both"
	
	# Se não encontrar, assume que é para ambos (comportamento conservador)
	return true

# Método para aplicar efeitos compilados a um projétil
func apply_effects_to_projectile(projectile: Node, effects: ArcherEffects) -> void:
	if not projectile:
		push_error("ArcherTalentSystem: Cannot apply effects to null projectile")
		return
	
	# Log start of talent application
	if debug_mode:
		print("Applying effects to projectile: ", projectile.name)
	
	# Apply base stats
	_apply_base_stats(projectile, effects)
	
	# Apply elemental effects
	_apply_elemental_effects(projectile, effects)
	
	# Apply movement effects (piercing, etc)
	_apply_movement_effects(projectile, effects)
	
	# Apply special abilities (Chain Shot, etc)
	_apply_special_abilities(projectile, effects)
	
	# Mark as processed by talent system
	projectile.set_meta("processed_by_talent_system", true)

# Improved base stats application
func _apply_base_stats(projectile: Node, effects: ArcherEffects) -> void:
	# Apply damage multiplier directly to projectile
	if "damage" in projectile:
		var original_damage = projectile.damage
		projectile.damage = int(original_damage * effects.damage_multiplier)
		
		if debug_mode:
			print("Applied damage multiplier: ", effects.damage_multiplier, 
				  " Original: ", original_damage, " New: ", projectile.damage)
	
	# Apply critical hit chance bonus
	if "crit_chance" in projectile and effects.crit_chance_bonus > 0:
		projectile.crit_chance = min(projectile.crit_chance + effects.crit_chance_bonus, 1.0)
	
	# Update DmgCalculatorComponent
	if projectile.has_node("DmgCalculatorComponent"):
		var dmg_calc = projectile.get_node("DmgCalculatorComponent")
		
		# Set base damage (if not already derived from projectile)
		if "base_damage" in dmg_calc:
			dmg_calc.base_damage = int(dmg_calc.base_damage * effects.damage_multiplier)
		
		# Set damage multiplier
		if "damage_multiplier" in dmg_calc:
			dmg_calc.damage_multiplier = effects.damage_multiplier
		
		# Set armor penetration
		if effects.armor_penetration > 0:
			dmg_calc.armor_penetration = effects.armor_penetration
			_ensure_tag(projectile, "armor_piercing")
			
			if debug_mode:
				print("Applied armor penetration: ", effects.armor_penetration)
func _ensure_tag(projectile: Node, tag_name: String) -> void:
	# If projectile doesn't have a 'tags' property, create one
	if not "tags" in projectile:
		projectile.tags = []
	
	# If projectile doesn't have an add_tag method, create a simple one
	if not projectile.has_method("add_tag"):
		projectile.add_tag = func(tag: String) -> void:
			if not tag in projectile.tags:
				projectile.tags.append(tag)
	
	# Add the tag using the add_tag method
	projectile.add_tag(tag_name)
	
# Improved elemental effects application
func _apply_elemental_effects(projectile: Node, effects: ArcherEffects) -> void:
	# Apply fire damage
	if effects.fire_damage_percent > 0:
		_ensure_tag(projectile, "fire")
		
		if projectile.has_node("DmgCalculatorComponent"):
			var dmg_calc = projectile.get_node("DmgCalculatorComponent")
			
			# Get total base damage
			var base_damage = dmg_calc.base_damage
			
			# Calculate fire damage
			var fire_damage = int(base_damage * effects.fire_damage_percent)
			
			# Add to elemental damage
			if "elemental_damage" in dmg_calc:
				if "fire" in dmg_calc.elemental_damage:
					dmg_calc.elemental_damage["fire"] += fire_damage
				else:
					dmg_calc.elemental_damage["fire"] = fire_damage
				
				if debug_mode:
					print("Applied fire damage: ", fire_damage)
			
			# Set up fire DoT if applicable
			if effects.fire_dot_damage_percent > 0:
				var dot_data = {
					"damage_per_tick": int(base_damage * effects.fire_dot_damage_percent),
					"duration": effects.fire_dot_duration,
					"interval": effects.fire_dot_interval,
					"chance": effects.fire_dot_chance,
					"type": "fire"
				}
				dmg_calc.set_meta("fire_dot_data", dot_data)
				
				if debug_mode:
					print("Applied fire DoT: ", dot_data["damage_per_tick"], " per ", 
						  effects.fire_dot_interval, "s for ", effects.fire_dot_duration, "s")

# Improved movement effects application
func _apply_movement_effects(projectile: Node, effects: ArcherEffects) -> void:
	# Apply piercing
	if effects.piercing_count > 0:
		projectile.piercing = true
		projectile.set_meta("piercing_count", effects.piercing_count)
		_ensure_tag(projectile, "piercing")
		
		# For projectiles that use physics, disable collision with enemies
		if projectile is CharacterBody2D:
			projectile.set_collision_mask_value(2, false)
			
		if debug_mode:
			print("Applied piercing: ", effects.piercing_count, " targets")

# Improved special abilities application
func _apply_special_abilities(projectile: Node, effects: ArcherEffects) -> void:
	# Double Shot - mostly handled at archer level
	if effects.double_shot_enabled:
		projectile.set_meta("double_shot_enabled", true)
		projectile.set_meta("double_shot_angle", effects.double_shot_angle)
		projectile.set_meta("second_arrow_damage_modifier", effects.second_arrow_damage_modifier)
		_ensure_tag(projectile, "double_shot")
		
		if debug_mode:
			print("Applied Double Shot: angle=", effects.double_shot_angle)
	
	# Chain Shot
	if effects.can_chain:
		# Direct settings for Arrow class
		if "chain_shot_enabled" in projectile:
			projectile.chain_shot_enabled = true
			projectile.chain_chance = effects.chain_chance
			projectile.chain_range = effects.chain_range
			projectile.chain_damage_decay = effects.chain_damage_decay
			projectile.max_chains = effects.max_chains
			projectile.current_chains = 0
			projectile.will_chain = false
			
			if "hit_targets" in projectile and projectile.hit_targets == null:
				projectile.hit_targets = []
		
		# Metadata for any projectile type
		projectile.set_meta("chain_shot_enabled", true)
		projectile.set_meta("chain_chance", effects.chain_chance)
		projectile.set_meta("chain_range", effects.chain_range)
		projectile.set_meta("chain_damage_decay", effects.chain_damage_decay)
		projectile.set_meta("max_chains", effects.max_chains)
		projectile.set_meta("current_chains", 0)
		projectile.set_meta("will_chain", null)
		
		_ensure_tag(projectile, "chain_shot")
		
		if debug_mode:
			print("Applied Chain Shot: chance=", effects.chain_chance, 
				  " range=", effects.chain_range, " max=", effects.max_chains)
	
	# Arrow Rain
	if effects.arrow_rain_enabled and not projectile.has_meta("is_rain_arrow"):
		projectile.set_meta("arrow_rain_enabled", true)
		projectile.set_meta("arrow_rain_count", effects.arrow_rain_count)
		projectile.set_meta("arrow_rain_damage_percent", effects.arrow_rain_damage_percent)
		projectile.set_meta("arrow_rain_radius", effects.arrow_rain_radius)
		projectile.set_meta("arrow_rain_interval", effects.arrow_rain_interval)
		_ensure_tag(projectile, "arrow_rain")
		
		if debug_mode:
			print("Applied Arrow Rain: count=", effects.arrow_rain_count, 
				  " radius=", effects.arrow_rain_radius)
	
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
		
		if debug_mode:
			print("Applied Pressure Wave: knockback=", effects.knockback_force,
				  " slow=", effects.slow_percent)
	
	# Explosion effect
	if effects.explosion_enabled:
		projectile.set_meta("has_explosion_effect", true)
		projectile.set_meta("explosion_damage_percent", effects.explosion_damage_percent)
		projectile.set_meta("explosion_radius", effects.explosion_radius)
		_ensure_tag(projectile, "explosion")
		
		if debug_mode:
			print("Applied Explosion: damage=", effects.explosion_damage_percent,
				  " radius=", effects.explosion_radius)
	
	# Bleeding/Serrated Arrows
	if effects.bleed_on_crit:
		projectile.set_meta("has_bleeding_effect", true)
		projectile.set_meta("bleeding_damage_percent", effects.bleed_damage_percent)
		projectile.set_meta("bleeding_duration", effects.bleed_duration)
		projectile.set_meta("bleeding_interval", effects.bleed_interval)
		_ensure_tag(projectile, "bleeding")
		
		if debug_mode:
			print("Applied Bleeding: damage=", effects.bleed_damage_percent,
				  " duration=", effects.bleed_duration)
