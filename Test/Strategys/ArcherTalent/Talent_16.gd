extends BaseProjectileStrategy
class_name Talent_16

@export var bleeding_damage_percent: float = 0.3
@export var bleeding_duration: float = 4.0
@export var dot_interval: float = 0.5
@export var talent_id: int = 16

func get_strategy_name() -> String:
	return "Serrated Arrows"

func apply_upgrade(projectile: Node) -> void:
	print("Aplicando Serrated Arrows - Flechas serrilhadas que causam sangramento em acertos críticos")
	
	# Adiciona tag para identificação
	if "tags" in projectile and projectile.has_method("add_tag"):
		projectile.add_tag("bleeding")
	elif "tags" in projectile:
		if not "bleeding" in projectile.tags:
			projectile.tags.append("bleeding")
	
	# Adiciona metadados
	projectile.set_meta("has_bleeding_effect", true)
	
	# Verifica se os dados estão corretos
	print("Dados de Sangramento:")
	print("- Damage Percent: ", bleeding_damage_percent)
	print("- Duration: ", bleeding_duration)
	print("- Interval: ", dot_interval)
	
	# Adiciona metadados com valores
	projectile.set_meta("bleeding_damage_percent", bleeding_damage_percent)
	projectile.set_meta("bleeding_duration", bleeding_duration)
	projectile.set_meta("bleeding_interval", dot_interval)
	
	print("Configurando metadados para efeito de sangramento em acertos críticos")
	
