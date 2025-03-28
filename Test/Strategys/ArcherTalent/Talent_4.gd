extends BaseProjectileStrategy
class_name Talent_4

# Propriedades
@export var piercing_count: int = 1  # Número de inimigos adicionais que a flecha pode atravessar
@export var talent_id: int = 4       # ID do talento correspondente

# Nome amigável para o painel de debug
func get_strategy_name() -> String:
	return "PiercingShotStrategy"

func apply_upgrade(projectile: Node) -> void:
	print("Aplicando upgrade de Piercing Shot - atravessa ", piercing_count, " inimigo(s) adicional(is)")
	
	# Adiciona tag de piercing para identificação
	if "tags" in projectile:
		if projectile.has_method("add_tag"):
			projectile.add_tag("piercing")
		elif not "piercing" in projectile.tags:
			projectile.tags.append("piercing")
	
	# Com o ConsolidatedTalentSystem, as configurações de piercing 
	# serão processadas no método compile_effects() do sistema de talentos
	# Adiciona metadados para referência futura
	projectile.set_meta("piercing_count", piercing_count)
	
	# Os efeitos de colisão serão tratados no nível do projétil ou no componente de hurtbox
	# O sistema de talentos consolidado vai configurar as propriedades necessárias
