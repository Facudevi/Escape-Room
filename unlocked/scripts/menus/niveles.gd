extends Control

@onready var botones: Array = [$Volver, $Nivel1, $Nivel2, $Nivel3, $Nivel4]


func _ready() -> void:
	# Aseguramos que el juego no esté pausado al entrar a la selección de niveles
	get_tree().paused = false
	FX.entrada_escalonada(botones)


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
