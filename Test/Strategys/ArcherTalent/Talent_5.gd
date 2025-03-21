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
	
	# Adiciona metadados ao projétil
	projectile.set_meta("focused_shot_bonus", damage_bonus_percent)
	projectile.set_meta("focused_shot_threshold", health_threshold)
	
	# Adiciona uma tag para identificação
	if "tags" in projectile:
		if not "focused_shot" in projectile.tags:
			projectile.add_tag("focused_shot")
	
	# Modifica o método get_damage_package para incluir o check de vida
	if projectile.has_method("get_damage_package"):
		# Armazena a referência original do método
		var original_get_damage_package = projectile.get_damage_package
		
		# Substitui o método com nossa versão personalizada que verifica o corpo atingido
		projectile.get_damage_package = func(hit_body = null):
			# Chama o método original para obter o pacote de dano base
			var damage_package = original_get_damage_package.call()
			
			# Se recebemos uma referência ao corpo atingido, verificamos a vida
			if hit_body != null and hit_body.has_node("HealthComponent"):
				var health_component = hit_body.get_node("HealthComponent")
				
				# Verifica a porcentagem de vida do inimigo
				var health_percent = float(health_component.current_health) / health_component.max_health
				
				# Se a vida estiver acima do limiar, aplica o bônus
				if health_percent >= health_threshold:
					# Aplica o bônus ao dano físico
					if "physical_damage" in damage_package:
						var original_damage = damage_package.physical_damage
						var bonus_damage = int(original_damage * damage_bonus_percent)
						damage_package.physical_damage += bonus_damage
						print("Focused Shot ativado! +", bonus_damage, " dano (alvo com", health_percent * 100, "% de vida)")
					
					# Também aplica o bônus a danos elementais, se existirem
					if "elemental_damage" in damage_package:
						for element_type in damage_package.elemental_damage.keys():
							var original_damage = damage_package.elemental_damage[element_type]
							var bonus_damage = int(original_damage * damage_bonus_percent)
							damage_package.elemental_damage[element_type] += bonus_damage
			
			return damage_package
	else:
		print("ERRO: Projétil não possui método get_damage_package")
