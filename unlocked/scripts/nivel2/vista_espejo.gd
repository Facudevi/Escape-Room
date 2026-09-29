extends CanvasLayer


signal espejo_limpiado_exitosamente

@onready var imagen_espejo: TextureRect = $ImagenEspejo
@onready var area_mancha: Area2D = $AreaMancha
@onready var boton_cerrar: Button = $BotonCerrar

# Texturas del espejo en Zoom (Asigna las rutas reales de tus assets)
@export var imagen_espejo_sucio: Texture2D = preload("res://assets/imagen/baño/espejo_sucio.jpg")
@export var imagen_espejo_limpio: Texture2D = preload("res://assets/imagen/baño/espejo_limpio.jpg")


func _ready() -> void:
	visible = false
	
	# Verificamos que no esté conectada antes de conectar el botón
	if boton_cerrar != null and not boton_cerrar.pressed.is_connected(_on_boton_cerrar_pressed):
		boton_cerrar.pressed.connect(_on_boton_cerrar_pressed)
	
	# Verificamos que no esté conectada antes de conectar el área de la mancha
	if area_mancha != null and not area_mancha.input_event.is_connected(_on_area_mancha_input_event):
		area_mancha.input_event.connect(_on_area_mancha_input_event)


func abrir_vista_espejo(ya_esta_limpio: bool) -> void:
	visible = true
	
	if ya_esta_limpio:
		imagen_espejo.texture = imagen_espejo_limpio
		if area_mancha != null:
			area_mancha.visible = false # Desactivamos la colisión de la mancha porque ya no existe
	else:
		imagen_espejo.texture = imagen_espejo_sucio
		if area_mancha != null:
			area_mancha.visible = true


func _on_area_mancha_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if Global.item_seleccionado_idx != -1:
			var item_actual = Global.inventario[Global.item_seleccionado_idx]
			
			if "trapo_humedo" in item_actual or "trapo_mojado" in item_actual:
				print("¡Limpiaste el espejo con el trapo húmedo!")
				Global.eliminar_item_seleccionado()
				
				imagen_espejo.texture = imagen_espejo_limpio
				if area_mancha != null:
					area_mancha.visible = false
				
				# Emitimos la señal para que nivel_2.gd cambie el fondo
				espejo_limpiado_exitosamente.emit()


func _on_boton_cerrar_pressed() -> void:
	visible = false
