extends BaseProjectileStrategy
class_name Talent_17_MarkedForDeathStrategy

# Marked for Death: Critical hits mark enemies for 4s. 
# Marked enemies take +100% bonus critical damage from all attacks.

# Parâmetros de configuração
var mark_duration: float = 4.0        # Duração do efeito de marcação em segundos
var crit_damage_bonus: float = 1.0    # 100% de dano crítico adicional

# Para integração com ConsolidatedTalentSystem
func get_strategy_name() -> String:
	return "MarkedForDeath"

# Aplicar estratégia ao projétil
func apply_upgrade(projectile: Node) -> void:
	print("Aplicando talento Marked for Death ao projétil")
	
	# A maioria da lógica agora será delegada aos sistemas existentes
	
	# Apenas adiciona os metadados necessários que serão usados pelo NewProjectileBase e ConsolidatedTalentSystem
	projectile.set_meta("has_mark_effect", true)
	projectile.set_meta("mark_duration", mark_duration) 
	projectile.set_meta("mark_crit_bonus", crit_damage_bonus)
	
	# Adiciona a tag para reconhecimento
	if projectile.has_method("add_tag"):
		projectile.add_tag("marked_for_death")
	elif "tags" in projectile:
		if not "marked_for_death" in projectile.tags:
			projectile.tags.append("marked_for_death")
