extends Area2D
class_name Hurtbox

# Novo sinal para estratégia de perfuração
signal hit_target(target)

@onready var owner_entity: ProjectileBase = get_owner()  

func _ready():
	connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body):
	print("Hurtbox: Colisão detectada com ", body)
	
	if body.is_in_group("enemies") and is_instance_valid(body):
		# Emite o sinal de alvo atingido
		emit_signal("hit_target", body)
		
		# DEBUGGING: Verificar informações do projétil
		if owner_entity:
			print("Projétil tem dano base:", owner_entity.damage)
			print("Projétil tem critical chance:", owner_entity.crit_chance)
			print("Projétil é crítico:", owner_entity.is_crit)
			
			if owner_entity.has_node("DamageInfo"):
				var damage_info = owner_entity.get_node("DamageInfo")
				var damage_types = damage_info.get_meta("damage_types")
				print("Tipos de dano do projétil:", damage_types)
			else:
				print("AVISO: Projétil não tem nó DamageInfo!")
		
		# Checa se o inimigo tem o componente de recepção de dano
		if body.has_node("DamageReceiverComponent"):
			var damage_receiver = body.get_node("DamageReceiverComponent")
			
			# Se o projétil tem informações de tipo de dano
			if owner_entity.has_node("DamageInfo"):
				var damage_info = owner_entity.get_node("DamageInfo")
				var damage_types = damage_info.get_meta("damage_types")
				
				# Cria um pacote de dano
				var damage_packet = DamageCalculator.DamagePacket.new()
				damage_packet.is_critical = owner_entity.is_crit
				
				# Se não houver tipos específicos, usa o dano físico padrão
				if damage_types.is_empty():
					print("Usando dano físico padrão:", owner_entity.damage)
					damage_packet.add_damage(DamageCalculator.DamageType.PHYSICAL, owner_entity.damage)
				else:
					# Adiciona cada tipo de dano ao pacote
					for damage_type in damage_types:
						print("Adicionando dano tipo", damage_type, ":", damage_types[damage_type])
						damage_packet.add_damage(damage_type, damage_types[damage_type])
				
				# Aplica o dano usando o receptor
				print("Aplicando pacote de dano ao alvo")
				var final_damage = damage_receiver.receive_damage(damage_packet)
				print("Dano final aplicado:", final_damage.get_total_damage())
				
				# Efeito visual de impacto
				var strongest_type = get_strongest_type(damage_types)
				DamageVisuals.create_impact_effect(strongest_type, global_position)
				
				# Aplica efeitos de DoT se configurados
				if damage_info.has_meta("dot_duration"):
					print("Aplicando efeitos de DoT")
					handle_dot_effects(body, damage_info, damage_types)
			else:
				# Fallback para o sistema antigo se não houver informações de tipo
				if body.has_node("HealthComponent"):
					print("Caindo para o sistema antigo de dano")
					var health_component = body.get_node("HealthComponent")
					health_component.take_damage(owner_entity.damage, owner_entity.crit_chance, owner_entity.is_crit)
					
					# Efeito visual básico
					DamageVisuals.create_impact_effect(DamageCalculator.DamageType.PHYSICAL, global_position)
		elif body.has_node("HealthComponent"):
			# Suporte para inimigos sem o DamageReceiverComponent
			print("Inimigo tem apenas HealthComponent, sem sistema de tipos de dano")
			var health_component = body.get_node("HealthComponent")
			health_component.take_damage(owner_entity.damage, owner_entity.crit_chance, owner_entity.is_crit)
		else:
			print("ERRO: Inimigo não tem HealthComponent nem DamageReceiverComponent!")
		
		# Garante que o projétil seja destruído corretamente
		if owner_entity and owner_entity is ProjectileBase:
			if not owner_entity.piercing:
				owner_entity.queue_free()
			elif owner_entity.has_meta("pierce_count"):
				# Decrementa o contador de perfuração
				var count = owner_entity.get_meta("pierce_count")
				count -= 1
				owner_entity.set_meta("pierce_count", count)
				
				# Se atingiu o limite, destrói o projétil
				if count <= 0:
					owner_entity.queue_free()

# Obtém o tipo de dano com maior valor
func get_strongest_type(damage_types: Dictionary) -> int:
	var strongest_type = DamageCalculator.DamageType.PHYSICAL
	var strongest_value = 0
	
	for damage_type in damage_types:
		if damage_types[damage_type] > strongest_value:
			strongest_value = damage_types[damage_type]
			strongest_type = damage_type
	
	return strongest_type

# Manipula a aplicação de efeitos de dano ao longo do tempo
func handle_dot_effects(body: Node, damage_info: Node, damage_types: Dictionary):
	var dot_duration = damage_info.get_meta("dot_duration")
	var dot_interval = damage_info.get_meta("dot_interval")
	
	print("Configurando DoT - Duração:", dot_duration, "Intervalo:", dot_interval)
	
	# Verifica se o alvo tem o componente de efeitos de status
	if body.has_node("StatusEffectComponent"):
		var status_effect = body.get_node("StatusEffectComponent")
		
		# Determina qual tipo de DoT aplicar baseado no dano predominante
		if damage_types.has(DamageCalculator.DamageType.POISON) and damage_types[DamageCalculator.DamageType.POISON] > 0:
			var dot_damage = int(damage_types[DamageCalculator.DamageType.POISON] * 0.25)
			print("Aplicando status POISONED - Dano:", dot_damage)
			status_effect.apply_status(StatusEffectComponent.EffectType.POISONED, dot_duration, 
									  {"damage": dot_damage, "tick_interval": dot_interval})
									  
		elif damage_types.has(DamageCalculator.DamageType.BLEED) and damage_types[DamageCalculator.DamageType.BLEED] > 0:
			var dot_damage = int(damage_types[DamageCalculator.DamageType.BLEED] * 0.3)
			print("Aplicando status BLEEDING - Dano:", dot_damage)
			status_effect.apply_status(StatusEffectComponent.EffectType.BLEEDING, dot_duration, 
									  {"damage": dot_damage, "tick_interval": dot_interval})
									  
		elif damage_types.has(DamageCalculator.DamageType.FIRE) and damage_types[DamageCalculator.DamageType.FIRE] > 0:
			var dot_damage = int(damage_types[DamageCalculator.DamageType.FIRE] * 0.2)
			print("Aplicando status BURNING - Dano:", dot_damage)
			status_effect.apply_status(StatusEffectComponent.EffectType.BURNING, dot_duration, 
									  {"damage": dot_damage, "tick_interval": dot_interval})
									  
		elif damage_types.has(DamageCalculator.DamageType.ICE) and damage_types[DamageCalculator.DamageType.ICE] > 0:
			print("Aplicando status FROZEN")
			status_effect.apply_status(StatusEffectComponent.EffectType.FROZEN, dot_duration, {})
									  
		elif damage_types.has(DamageCalculator.DamageType.ELECTRIC) and damage_types[DamageCalculator.DamageType.ELECTRIC] > 0:
			print("Aplicando status SHOCKED")
			status_effect.apply_status(StatusEffectComponent.EffectType.SHOCKED, min(1.0, dot_duration), {})
	
	# Fallback se não tiver o StatusEffectComponent mas tiver HealthComponent
	elif body.has_node("HealthComponent"):
		var health_component = body.get_node("HealthComponent")
		
		# Obtém o tipo de dano com maior valor para DoT
		var strongest_type = get_strongest_type(damage_types)
		var damage_value = damage_types[strongest_type]
		
		# Aplica um DoT genérico se o componente de saúde tiver o método
		if health_component.has_method("apply_dot") and dot_duration > 0:
			var dot_damage = int(damage_value * 0.2)
			print("Aplicando DoT genérico - Dano:", dot_damage)
			health_component.apply_dot(dot_damage, dot_duration, dot_interval)
