extends BaseProjectileStrategy
class_name Talent_6

# Configurações de dano de fogo
@export var fire_damage_percent: float = 0.20  # 20% de dano adicional de fogo
@export var dot_percent_per_tick: float = 0.05 # 5% do dano base por tick de DoT
@export var dot_duration: float = 3.0          # Duração do efeito de fogo em segundos
@export var dot_interval: float = 0.5          # Intervalo entre ticks de DoT
@export var dot_chance: float = 1           # 30% de chance de aplicar DoT
@export var talent_id: int = 6                 # ID para árvore de talentos

# Nome amigável para painel de debug
func get_strategy_name() -> String:
	return "Flaming Arrows"

func apply_upgrade(projectile: Node) -> void:
	# Adiciona tag de fogo para identificação
	if "tags" in projectile:
		if projectile.has_method("add_tag"):
			projectile.add_tag("fire")
		elif not "fire" in projectile.tags:
			projectile.tags.append("fire")
