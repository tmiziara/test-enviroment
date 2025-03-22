extends ProjectileBase
class_name Arrow

# Defina um sinal para quando o projétil atingir um alvo
signal on_hit(target)

func _ready():
	super._ready()
	
func process_on_hit(target: Node) -> void:
	# Emite o sinal on_hit para que outros componentes possam reagir
	emit_signal("on_hit", target)
