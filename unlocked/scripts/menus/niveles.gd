extends Control

@onready var botones: Array = [$Volver, $Nivel1, $Nivel2, $Nivel3, $Nivel4]


func _ready() -> void:
	# Aseguramos que el juego no esté pausado al entrar a la selección de niveles
	get_tree().paused = false
	_aplicar_bloqueos()
	FX.entrada_escalonada(botones)


# Solo están habilitados los niveles que el jugador ya liberó; el resto se ve atenuado
func _aplicar_bloqueos() -> void:
	for n in range(1, 5):
		var boton: Button = get_node("Nivel%d" % n)
		var bloqueado: bool = not Global.esta_desbloqueado(n)
		boton.disabled = bloqueado
		var contenido: Control = boton.get_node_or_null("Contenido")
		if contenido != null:
			contenido.modulate = Color(0.55, 0.55, 0.55) if bloqueado else Color.WHITE


func _on_nivel_1_pressed() -> void:
	FX.cambiar_escena("res://escenas/niveles/nivel1/nivel1.tscn")


func _on_nivel_2_pressed() -> void:
	FX.cambiar_escena("res://escenas/niveles/nivel2/nivel2.tscn")


func _on_nivel_3_pressed() -> void:
	FX.cambiar_escena("res://escenas/niveles/nivel3/nivel3.tscn")


func _on_nivel_4_pressed() -> void:
	pass # Replace with function body.


func _on_volver_pressed() -> void:
	FX.cambiar_escena("res://escenas/menus/menu.tscn")
