extends Control


func _ready() -> void:
	# Aseguramos que el juego no esté pausado al entrar a la selección de niveles
	get_tree().paused = false


func _on_nivel_1_pressed() -> void:
	get_tree().change_scene_to_file("res://escenas/niveles/nivel1/nivel1.tscn")


func _on_nivel_2_pressed() -> void:
	pass # Replace with function body.


func _on_nivel_3_pressed() -> void:
	pass # Replace with function body.


func _on_nivel_4_pressed() -> void:
	pass # Replace with function body.


func _on_volver_pressed() -> void:
	get_tree().change_scene_to_file("res://escenas/settings/menu.tscn")
