extends CanvasLayer

signal abrir_zoom_candado
signal aviso_solicitado(texto: String)

@onready var imagen_cubiculo: TextureRect = $ImagenCubiculo
@onready var sprite_candado: Sprite2D = $SpriteCandado
@onready var area_candado: Area2D = $AreaCandado
@onready var area_llave: Area2D = $AreaLlave
@onready var boton_cerrar: Button = $BotonCerrar

# Carga de imagen para el fondo en zoom cuando está abierto
var imagen_cubiculo_zoom_abierto: Texture2D = preload("res://assets/fondos/bano/cubiculo_abierto.png")

# Ruta de la imagen de la llave para el inventario
@export var icono_llave: String = "res://assets/objetos/nivel2/llave.png"

var llave_tomada: bool = false


func _ready() -> void:
	visible = false
	
	# La interacción con la llave empieza oculta
	if area_llave != null:
		area_llave.visible = false
		if not area_llave.input_event.is_connected(_on_area_llave_input_event):
			area_llave.input_event.connect(_on_area_llave_input_event)
			
	if boton_cerrar != null:
		if not boton_cerrar.pressed.is_connected(_on_boton_cerrar_pressed):
			boton_cerrar.pressed.connect(_on_boton_cerrar_pressed)
			
	if area_candado != null:
		if not area_candado.input_event.is_connected(_on_area_candado_input_event):
			area_candado.input_event.connect(_on_area_candado_input_event)


func abrir_vista(ya_esta_abierto: bool) -> void:
	visible = true
	if ya_esta_abierto:
		_aplicar_estado_abierto()


func desbloquear_cubiculo_zoom() -> void:
	_aplicar_estado_abierto()


func _aplicar_estado_abierto() -> void:
	# 1. Mantenemos esta vista visible y cambiamos la textura al cubículo abierto
	visible = true
	if imagen_cubiculo != null and imagen_cubiculo_zoom_abierto != null:
		imagen_cubiculo.texture = imagen_cubiculo_zoom_abierto
		
	# 2. Ocultamos y desactivamos el candado
	if sprite_candado != null:
		sprite_candado.visible = false
	if area_candado != null:
		area_candado.visible = false
		
	# 3. Activamos la zona interactiva de la llave si no fue recolectada
	if area_llave != null and not llave_tomada:
		area_llave.visible = true


func _on_area_candado_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		abrir_zoom_candado.emit()


# --- INTERACCIÓN CON LA LLAVE ---
func _on_area_llave_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not llave_tomada:
			var exito: bool = Global.agregar_objeto(icono_llave)
			if exito:
				llave_tomada = true
				if area_llave != null:
					area_llave.visible = false
				aviso_solicitado.emit("Encontraste una llave. ¿Qué podrá abrir?")
			else:
				aviso_solicitado.emit("El inventario está lleno.")


func _on_boton_cerrar_pressed() -> void:
	visible = false
