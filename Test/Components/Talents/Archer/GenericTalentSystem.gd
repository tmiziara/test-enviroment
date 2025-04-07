extends Node
class_name GenericTalentSystem

# Referência ao soldado
var soldier: SoldierBase

# Interface para efeitos compilados - classe base abstrata
class CompiledEffects:
	# Implementação base, será estendida pelas classes específicas
	func _init():
		pass
		
	# Método para criar uma cópia desta instância
	func copy():
		push_error("copy() deve ser implementado pelas subclasses!")
		return null

# Registro de processadores de talento - onde armazenamos os adaptadores para cada tipo de estratégia
var _strategy_processors = {}

# Inicializa o sistema para um soldado específico
func _init(soldier_ref: SoldierBase):
	soldier = soldier_ref

# Método para registrar um processador de estratégia para um tipo específico
func register_strategy_processor(strategy_type: String, processor: Callable):
	_strategy_processors[strategy_type] = processor

# Método genérico para compilar efeitos
# Cada tipo de soldado deve fornecer sua própria classe de CompiledEffects
func compile_effects(effects_class) -> CompiledEffects:
	# Verificar soldado
	if not soldier:
		push_error("GenericTalentSystem: Nenhuma referência de soldado")
		return null
		
	# Criar instância de efeitos
	var effects = effects_class.new()
	
	# Processa cada estratégia de talento
	for strategy in soldier.attack_upgrades:
		if strategy:
			# Determina o tipo da estratégia
			var strategy_type = _get_strategy_type(strategy)
			
			# Busca o processador registrado para este tipo
			if strategy_type in _strategy_processors:
				var processor = _strategy_processors[strategy_type]
				processor.call(strategy, effects)
			else:
				# Fallback para processamento genérico
				_process_generic_strategy(strategy, effects)
	
	return effects

# Determina o tipo de uma estratégia
func _get_strategy_type(strategy) -> String:
	# Tenta obter o nome da classe
	var script_path = strategy.get_script().get_path()
	var file_name = script_path.get_file().get_basename()
	
	# Tenta obter um nome amigável se disponível
	if strategy.has_method("get_strategy_name"):
		return strategy.call("get_strategy_name")
	elif strategy.has_method("get_strategy_type"):
		return strategy.call("get_strategy_type")
	
	# Extrai o número do talento usando regex
	var regex = RegEx.new()
	regex.compile("Talent_(\\d+)")
	var result = regex.search(file_name)
	
	if result:
		return "Talent_" + result.get_string(1)
	
	# Retorna o nome do arquivo como fallback
	return file_name

# Processamento genérico para estratégias não registradas
func _process_generic_strategy(strategy, effects: CompiledEffects):
	# Implementação básica - procura por propriedades comuns
	
	# Exemplos de propriedades comuns
	var common_properties = [
		"damage_increase_percent", 
		"range_increase_percentage",
		"attack_speed_multiplier",
		"crit_chance_bonus",
		"crit_damage_multiplier"
	]
	
	# Tenta aplicar propriedades comuns
	for prop in common_properties:
		if prop in strategy:
			var value = strategy.get(prop)
			# Tenta encontrar a propriedade correspondente no effects
			if prop in effects:
				match prop:
					"damage_increase_percent":
						effects.damage_multiplier += value / 100.0
					"range_increase_percentage":
						effects.range_multiplier += value / 100.0
					_:
						# Tenta aplicar diretamente
						if effects.get(prop) != null:
							effects[prop] += value

# Método genérico para aplicar efeitos compilados
# Cada tipo de soldado fornece sua implementação de aplicação
func apply_effects(target: Node, effects: CompiledEffects, apply_method: Callable) -> void:
	if not effects:
		push_error("GenericTalentSystem: Efeitos nulos, não foi possível aplicar")
		return
	
	# Chama o método de aplicação específico fornecido
	apply_method.call(target, effects)
