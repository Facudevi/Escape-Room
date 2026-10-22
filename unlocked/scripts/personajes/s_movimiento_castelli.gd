extends CharacterBody2D

@export var speed: float = 300.0

@onready var anim_player: AnimationPlayer = $AnimationPlayer

func _physics_process(delta: float) -> void:
	# Capturamos entrada en 4 direcciones (WASD / Flechas)
	var input_dir: Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

	# Aplicamos velocidad
	velocity = input_dir * speed

	# Reproducción de animaciones según la dirección dominante
	if input_dir.x < 0:
		anim_player.play("caminar_izquierda")
	elif input_dir.x > 0:
		anim_player.play("caminar_derecha")
	elif input_dir.y < 0:
		if anim_player.has_animation("caminar_arriba"):
			anim_player.play("caminar_arriba")
		else:
			anim_player.play("caminar_izquierda") # Alternativa si no hay animación de espalda
	elif input_dir.y > 0:
		if anim_player.has_animation("caminar_abajo"):
			anim_player.play("caminar_abajo")
		else:
			anim_player.play("caminar_derecha") # Alternativa si no hay animación de frente
	else:
		anim_player.play("animacion_idle")

	# MoveAndSlide gestionará el choque contra las colisiones del StaticBody2D
	move_and_slide()
