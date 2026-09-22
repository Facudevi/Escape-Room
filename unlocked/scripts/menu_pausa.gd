extends Control

func _on_reanudar_pressed() -> void:
	get_tree().paused = false
	visible = false

func _on_salir_pressed() -> void:
	get_tree().paused = false
	# Reiniciamos el inventario y datos globales antes de cambiar de escena
	Global.reiniciar_datos()
	get_tree().change_scene_to_file("res://escenas/settings/menu.tscn")
