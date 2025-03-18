extends Node
class_name HealthComponent

@export var max_health: int = 100  # Vida máxima
@export var crit_multiplier: float = 3.0  # Dano crítico multiplicado por 2

var current_health: int  # Vida atual
var active_debuffs = {}  # Dicionário para armazenar debuffs ativos
var active_dots = []  # Lista para armazenar DoTs ativos

signal health_changed(new_health, amount, is_crit)  # Atualiza a UI
signal died  # Evento de morte

func _ready():
	current_health = max_health

# Aplica dano (incluindo crítico e DoTs)
func take_damage(amount: int, hit_crit_chance: float, is_crit: bool = false, dot_damage: bool = false):
	var crit_chance = hit_crit_chance
	if is_crit:
		amount *= crit_multiplier  # Multiplica o dano se for crítico
	current_health -= int(amount)
	current_health = max(current_health, 0)
	health_changed.emit(current_health, amount, is_crit)
	if current_health == 0:
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

# Aplica dano ao longo do tempo (DoT)
func apply_dot(damage: int, duration: float, interval: float):
	var dot_timer = Timer.new()
	dot_timer.wait_time = interval
	dot_timer.one_shot = false
	add_child(dot_timer)
	
	dot_timer.timeout.connect(func():
		take_damage(damage, false, true)  # Aplica dano como DoT
	)
	dot_timer.start()
	await get_tree().create_timer(duration).timeout
	dot_timer.queue_free()  # Remove o DoT após o tempo acabar
