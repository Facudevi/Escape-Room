extends CharacterBody2D

# Velocidad de movimiento (ajustable desde el Inspector)
@export var speed: float = 300.0

@onready var anim_player: AnimationPlayer = $AnimationPlayer

func _physics_process(delta: float) -> void:
	# Capturamos la dirección (-1 para izquierda, 1 para derecha, 0 si no hay teclas)
	var input_dir: float = Input.get_axis("ui_left", "ui_right")

	# Aplicamos la velocidad en el eje X
	velocity.x = input_dir * speed
	velocity.y = 0.0

	# Control de Animaciones
	if input_dir < 0:
		# Moviéndose a la izquierda
		anim_player.play("caminar_izquierda")
	elif input_dir > 0:
		# Moviéndose a la derecha (asegúrate de que este nombre sea igual al de tu AnimationPlayer)
		anim_player.play("caminar_derecha")
	else:
		# Reposo / Parado
		anim_player.play("animacion_idle")

	# Movemos al personaje
	move_and_slide()
