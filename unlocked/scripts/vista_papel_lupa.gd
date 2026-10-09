extends CanvasLayer

@onready var boton_cerrar: Button = $PanelPapel/BotonCerrar # Ajusta si tu botón se llama distinto o está en otra ruta

func _ready() -> void:
	visible = false
	if boton_cerrar != null:
		if not boton_cerrar.pressed.is_connected(_on_boton_cerrar_pressed):
			boton_cerrar.pressed.connect(_on_boton_cerrar_pressed)

func mostrar_pista(texto: String) -> void:
	# Busca automáticamente cualquier Label dentro de esta escena para evitar errores de ruta
	var label_encontrado = _buscar_label(self)
	if label_encontrado != null:
		label_encontrado.text = texto
	else:
		print("Advertencia: No se encontró ningún nodo Labe´l en vista_papel_lupa")
	visible = true

func _buscar_label(nodo: Node) -> Label:
	if nodo is Label:
		return nodo
	for hijo in nodo.get_children():
		var encontrado = _buscar_label(hijo)
		if encontrado != null:
			return encontrado
	return null

func _on_boton_cerrar_pressed() -> void:
	visible = false
