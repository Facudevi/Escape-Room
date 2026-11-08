extends Control

@onready var botones: Array = [$VBoxContainer/Como_Jugar, $VBoxContainer/Volver]


func _ready() -> void:
	FX.entrada_escalonada(botones)


func _on_como_jugar_pressed() -> void:
	FX.cambiar_escena("res://escenas/menus/como_jugar.tscn")


func _on_volver_pressed() -> void:
	FX.cambiar_escena("res://escenas/menus/menu.tscn")
