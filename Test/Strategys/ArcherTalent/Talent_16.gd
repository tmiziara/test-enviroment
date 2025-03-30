extends BaseProjectileStrategy
class_name Talent_16

# Configurações de sangramento em crítico
@export var bleeding_damage_percent: float = 0.30 # 30% do dano base por tick de DoT
@export var bleeding_duration: float = 4.0        # Duração do sangramento em segundos
@export var dot_interval: float = 0.5             # Intervalo entre ticks de DoT
@export var talent_id: int = 16                   # ID para árvore de talentos

# Nome amigável para painel de debug
func get_strategy_name() -> String:
	return "Serrated Arrows"

func apply_upgrade(projectile: Node) -> void:
	print("Applying Talent_16 (Serrated Arrows) - Bleeding on Critical Hit")
	
	# Configure os metadados no projétil para o sistema de DoT
	projectile.set_meta("has_bleeding_effect", true)
	projectile.set_meta("bleeding_damage_percent", bleeding_damage_percent)
	projectile.set_meta("bleeding_duration", bleeding_duration)
	projectile.set_meta("bleeding_interval", dot_interval)
	
	# Adicione tag de sangramento para reconhecimento visual e processamento
	if projectile.has_method("add_tag"):
		projectile.add_tag("bleeding")
	elif "tags" in projectile and not "bleeding" in projectile.tags:
		projectile.tags.append("bleeding")
	
	print("Serrated Arrows: Configuração de sangramento aplicada ao projétil")
	print("- Damage Percent: ", bleeding_damage_percent)
	print("- Duration: ", bleeding_duration)
	print("- Interval: ", dot_interval)
	
	# Não implementamos a lógica de DoT aqui - isso é responsabilidade do DoTManager
	# Não criamos hooks de evento - o sistema existente deve processar o efeito de sangramento
