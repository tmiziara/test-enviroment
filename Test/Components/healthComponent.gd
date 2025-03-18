extends Node
class_name HealthComponent

@export var max_health: int = 100  # Vida máxima
@export var crit_multiplier: float = 3.0  # Dano crítico multiplicado por 2

var current_health: int  # Vida atual
var active_debuffs = {}  # Dicionário para armazenar debuffs ativos
var active_dots = {}   # Lista para armazenar DoTs ativos


# No HealthComponent
signal health_changed(new_health, amount, is_crit, damage_type)
signal died  # Evento de morte

func _ready():
	current_health = max_health

# Função básica que aplica dano direto à vida
# No HealthComponent
func take_damage(amount: int, is_crit: bool = false, damage_type: String = ""):
	print("HealthComponent: Recebendo dano de", amount, ", Crítico:", is_crit, ", Tipo:", damage_type)
	
	# Aplica dano diretamente
	current_health -= int(amount)
	current_health = max(current_health, 0)
	
	# Emite sinal com informações do dano
	health_changed.emit(current_health, amount, is_crit, damage_type)
	
	# Verifica se o personagem morreu
	if current_health <= 0:
		died.emit()
# Aplica um debuff no personagem
func apply_debuff(debuff_name: String, duration: float, effect_func: Callable):
	if debuff_name in active_debuffs:
		return  # Evita reaplicar um debuff já ativo

	active_debuffs[debuff_name] = get_tree().create_timer(duration)
	active_debuffs[debuff_name].timeout.connect(func():
		active_debuffs.erase(debuff_name)  # Remove o debuff após o tempo
	)
	effect_func.call()  # Aplica o efeito imediato

# Versão melhorada do método apply_dot
func apply_dot(damage: int, duration: float, interval: float, dot_type: String = "generic"):
	print("Aplicando DoT de tipo ", dot_type, " com dano ", damage, "/", interval, "s por ", duration, "s")
	
	# Verifica se já existe um DoT desse tipo
	if dot_type in active_dots:
		print("DoT de ", dot_type, " já existe, renovando duração")
		
		# Atualiza o dano se o novo for maior
		if damage > active_dots[dot_type].damage:
			active_dots[dot_type].damage = damage
			print("Atualizando dano para", damage)
		
		# Renova o timer de duração
		if active_dots[dot_type].duration_timer and is_instance_valid(active_dots[dot_type].duration_timer):
			active_dots[dot_type].duration_timer.stop()
			active_dots[dot_type].duration_timer.wait_time = duration
			active_dots[dot_type].duration_timer.start()
			print("Duração renovada para", duration, "segundos")
		
		# Não cria um novo DoT, apenas retorna
		return
	
	# Se não existe um DoT desse tipo, cria um novo
	
	# Cria um timer para aplicar o dano periodicamente
	var dot_timer = Timer.new()
	dot_timer.wait_time = interval
	dot_timer.one_shot = false
	add_child(dot_timer)
	
	# Cria um timer para controlar a duração total
	var duration_timer = Timer.new()
	duration_timer.wait_time = duration
	duration_timer.one_shot = true
	add_child(duration_timer)
	
	# Armazena informações do DoT
	active_dots[dot_type] = {
		"damage": damage,
		"interval": interval,
		"duration": duration,
		"dot_timer": dot_timer,
		"duration_timer": duration_timer
	}
	
	# Conecta os sinais dos timers
	dot_timer.timeout.connect(func():
		take_damage(damage, false, dot_type)
		if dot_type == "fire":
			# Aqui você poderia adicionar efeitos visuais específicos para fogo
			print("Dano de fogo aplicado: ", damage)
	)
	
	duration_timer.timeout.connect(func():
		# Remove o DoT após o término da duração
		dot_timer.stop()
		dot_timer.queue_free()
		duration_timer.queue_free()
		active_dots.erase(dot_type)
		print("DoT de ", dot_type, " terminou")
	)
	
	# Inicia os timers
	dot_timer.start()
	duration_timer.start()
# Processa um pacote completo de dano
func take_complex_damage(damage_package: Dictionary):
	# Processa o dano básico...
	var physical_damage = damage_package.get("physical_damage", 0)
	var is_critical = damage_package.get("is_critical", false)
	var elemental_damage = damage_package.get("elemental_damage", {})
	
	# Calcula dano total
	var total_damage = physical_damage
	
	# Soma dano elemental (se houver)
	for element in elemental_damage:
		total_damage += elemental_damage[element]
	
	# Aplica o dano básico
	take_damage(total_damage, is_critical)
	
	# Processa efeitos DoT
	var dot_effects = damage_package.get("dot_effects", [])
	for dot in dot_effects:
		apply_dot(
			dot.damage,
			dot.duration,
			dot.interval,
			dot.type
		)
