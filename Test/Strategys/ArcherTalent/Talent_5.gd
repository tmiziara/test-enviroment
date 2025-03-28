extends BaseProjectileStrategy
class_name Talent_5

# Configurações
@export var damage_bonus_percent: float = 0.3  # 30% de dano adicional contra inimigos com vida alta
@export var health_threshold: float = 0.75     # Limiar de 75% da vida máxima
@export var talent_id: int = 5                 # ID do talento correspondente

# Nome amigável para o painel de debug
func get_strategy_name() -> String:
	return "FocusedShotStrategy"

func apply_upgrade(projectile: Node) -> void:
	print("Aplicando upgrade de Focused Shot - +", 
		  damage_bonus_percent * 100, "% de dano contra inimigos com mais de ", 
		  health_threshold * 100, "% de vida")
	
	# Adiciona tag para identificação
	if "tags" in projectile:
		if projectile.has_method("add_tag"):
			projectile.add_tag("focused_shot")
		elif not "focused_shot" in projectile.tags:
			projectile.tags.append("focused_shot")
	
	print("Focused Shot configurado com sucesso no projétil")
