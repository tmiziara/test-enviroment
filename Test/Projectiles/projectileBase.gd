extends CharacterBody2D
class_name ProjectileBase

@export var damage: int = 10
@export var crit_chance: float = 0.1
@export var speed: float = 400.0
@export var piercing: bool = false

var is_crit: bool = false  # O projétil calcula isso ao ser instanciado
var direction: Vector2 = Vector2.ZERO
var shooter = null  # Referência ao atirador (arqueiro)
var dmg_calculator: DmgCalculatorComponent
var tags: Array = []  # Array para armazenar tags como "fire", "ice", etc.

func _ready():
	is_crit = is_critical_hit(crit_chance)
	
	# Obtém ou cria o calculador de dano
	dmg_calculator = $DmgCalculatorComponent
	if not dmg_calculator:
		dmg_calculator = DmgCalculatorComponent.new()
		add_child(dmg_calculator)
	
	# Inicializa calculadora de dano
	dmg_calculator.base_damage = damage  # Define o dano base
	
	# Inicializa com o atirador se estiver disponível
	if shooter:
		dmg_calculator.initialize_from_shooter(shooter)

func _physics_process(delta):
	velocity = direction * speed
	move_and_slide()

# Função que verifica se o ataque será crítico
func is_critical_hit(crit_chance: float) -> bool:
	var roll = randf()
	var result = roll < crit_chance
	return result
	
# Retorna o pacote de dano calculado
func get_damage_package() -> Dictionary:
	if not dmg_calculator:
		print("ERRO: Tentando calcular dano sem DmgCalculatorComponent!")
		return {
			"physical_damage": damage,
			"is_critical": is_crit,
			"tags": tags
		}
	
	var damage_package = dmg_calculator.calculate_damage()
	
	# Aplica crítico se necessário
	if is_crit:
		damage_package["physical_damage"] = int(damage_package["physical_damage"] * 2)
		damage_package["is_critical"] = true
	else:
		damage_package["is_critical"] = false
	
	# Adiciona as tags do projétil ao pacote de dano
	damage_package["tags"] = tags
		
	return damage_package

# Adiciona uma tag ao projétil se ela ainda não existir
func add_tag(tag_name: String) -> void:
	if not tag_name in tags:
		tags.append(tag_name)
