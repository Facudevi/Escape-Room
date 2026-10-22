extends Node2D

signal solicitar_pista

@onready var boton_lampara: TextureButton = $botonLampara # Ajusta si es Button o TextureButton según tu nodo

func _ready() -> void:
	if boton_lampara != null:
		if not boton_lampara.pressed.is_connected(_on_boton_lampara_pressed):
			boton_lampara.pressed.connect(_on_boton_lampara_pressed)

func _on_boton_lampara_pressed() -> void:
	solicitar_pista.emit()
