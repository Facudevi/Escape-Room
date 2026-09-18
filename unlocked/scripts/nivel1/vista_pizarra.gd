extends CanvasLayer

@onready var boton_volver: Button = $Control/Panel/Volver


func _ready() -> void:
	# Ocultamos la vista ampliada al iniciar
	hide()
	
	# Verificamos si el acertijo ya fue resuelto previamente
	if Global.pizarra_resuelta:
		_mostrar_pizarra_completada()


func abrir_pizarra() -> void:
	show()
	# Pausamos el movimiento del personaje si es necesario
	get_tree().paused = true


func _on_volver_pressed() -> void:
	hide()
	get_tree().paused = false


func resolver_acertijo() -> void:
	# Cuando el jugador completa el acertijo dentro de la pizarra:
	Global.pizarra_resuelta = true
	_mostrar_pizarra_completada()


func _mostrar_pizarra_completada() -> void:
	# Cambia la interfaz para reflejar que el acertijo ya se resolvió
	print("El acertijo de la pizarra ya está resuelto.")
