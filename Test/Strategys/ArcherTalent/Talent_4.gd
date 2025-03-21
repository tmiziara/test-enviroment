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
	
	# Verifica se o projétil tem a propriedade 'piercing'
	if "piercing" in projectile:
		# Habilita o modo piercing
		projectile.piercing = true
		
		print("Flecha agora atravessa inimigos!")
	else:
		print("AVISO: Projétil não tem propriedade 'piercing'")
	
	# Verifica se já existe um contador de atravessamentos
	if not "piercing_count" in projectile:
		# Adiciona o contador como metadado se não existir
		projectile.set_meta("piercing_count", piercing_count)
		print("Contador de atravessamentos definido:", piercing_count)
	else:
		# Incrementa o contador existente
		projectile.piercing_count += piercing_count
		print("Contador de atravessamentos incrementado para:", projectile.piercing_count)
	
	# Adiciona uma tag para identificação
	if "tags" in projectile:
		if not "piercing" in projectile.tags:
			projectile.add_tag("piercing")
