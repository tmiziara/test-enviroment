extends BaseProjectileStrategy
class_name Talent_4

# Propriedades
@export var piercing_count: int = 1  # Número de inimigos adicionais que a flecha pode atravessar
@export var talent_id: int = 4       # ID do talento correspondente

# Nome amigável para o painel de debug
func get_strategy_name() -> String:
	return "PiercingShotStrategy"

func apply_upgrade(projectile: Node) -> void:
	print("Aplicando upgrade de Piercing Shot - atravessa", piercing_count, "inimigo(s) adicional(is)")
	
	# Habilita o modo piercing na flecha
	if "piercing" in projectile:
		projectile.piercing = true
		print("Flecha agora atravessa inimigos!")
	else:
		print("AVISO: Projétil não tem propriedade 'piercing'")
	
	# Define o contador de piercing
	if "piercing_count" in projectile:
		# Incrementa o contador existente
		projectile.piercing_count += piercing_count
		print("Contador de atravessamentos incrementado para:", projectile.piercing_count)
	else:
		# Adiciona o contador como metadado se não existir
		projectile.set_meta("piercing_count", piercing_count)
		print("Contador de atravessamentos definido:", piercing_count)
	
	# Inicializa o array para rastrear alvos já atingidos
	if not projectile.has_meta("hit_targets"):
		projectile.set_meta("hit_targets", [])
	
	# Adiciona uma tag para identificação
	if "tags" in projectile:
		if projectile.has_method("add_tag"):
			projectile.add_tag("piercing")
		elif not "piercing" in projectile.tags:
			projectile.tags.append("piercing")
	
	# MUITO IMPORTANTE: Modifica as configurações de colisão física da flecha
	if projectile is CharacterBody2D:
		# Configuração para evitar que a flecha seja interrompida por colisões físicas
		projectile.set_collision_mask_value(2, false)  # Desativa colisão física com inimigos (layer 2)
