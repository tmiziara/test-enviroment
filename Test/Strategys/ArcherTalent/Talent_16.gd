extends BaseProjectileStrategy
class_name Talent_16

@export var bleeding_damage_percent: float = 0.3
@export var bleeding_duration: float = 4.0
@export var dot_interval: float = 0.5
@export var talent_id: int = 16

func get_strategy_name() -> String:
	return "Serrated Arrows"

func apply_upgrade(projectile: Node) -> void:
	print("Aplicando Serrated Arrows - Flechas serrilhadas causam sangramento em acertos críticos")
	
	# Adiciona tag para identificação
	if "tags" in projectile:
		if projectile.has_method("add_tag"):
			projectile.add_tag("bleeding")
		elif not "bleeding" in projectile.tags:
			projectile.tags.append("bleeding")
	
	# NOVIDADE: Definindo metadados explicitamente
	projectile.set_meta("has_bleeding_effect", true)
	projectile.set_meta("bleeding_damage_percent", bleeding_damage_percent)
	projectile.set_meta("bleeding_duration", bleeding_duration)
	projectile.set_meta("bleeding_interval", dot_interval)
	
	print("Configurando metadados para efeito de sangramento em acertos críticos")
