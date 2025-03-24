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
	print("Aplicando upgrade de Focused Shot - +", damage_bonus_percent * 100, "% de dano contra inimigos com mais de", health_threshold * 100, "% de vida")
	
	# Verifica se o projétil é uma flecha que suporta Focused Shot
	if projectile is Arrow:
		# Configura os parâmetros do Focused Shot diretamente
		projectile.focused_shot_enabled = true
		projectile.focused_shot_bonus = damage_bonus_percent
		projectile.focused_shot_threshold = health_threshold
		
		print("Focused Shot configurado com sucesso na flecha")
	else:
		print("AVISO: Projétil não é do tipo Arrow, Focused Shot pode não funcionar corretamente")
	
	# Adiciona uma tag para identificação (funcionalidade genérica)
	if "tags" in projectile and projectile.has_method("add_tag"):
		if not "focused_shot" in projectile.tags:
			projectile.add_tag("focused_shot")
