extends Area2D


# Ruta de la imagen de la moneda (ajusta la ruta según tu carpeta de assets)
@export var icono_moneda: String = "res://assets/objetos/moneda_expendedora.png"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	# Verificamos que el evento sea un clic del botón izquierdo del ratón
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		recolectar_moneda()
		
		
func recolectar_moneda() -> void:
	# Intentamos agregar la moneda al inventario
	var exito: bool = Global.agregar_objeto(icono_moneda)
	if exito:
		Global.monedas += 1
		queue_free()
