extends Control

@onready var botones: Array = [$VBoxContainer/Jugar, $VBoxContainer/Opciones, $VBoxContainer/Salir]


func _ready() -> void:
	FX.entrada_escalonada(botones)


func _on_jugar_pressed() -> void:
	FX.cambiar_escena("res://escenas/menus/niveles.tscn")


func _on_opciones_pressed() -> void:
	FX.cambiar_escena("res://escenas/menus/opciones.tscn")


func _on_salir_pressed() -> void:
	get_tree().quit()
