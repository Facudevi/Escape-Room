extends CanvasLayer

# Papel de la lámpara con el texto de la pista. Misma escena que los niveles 1 y 2
# (vista_papel_lupa.tscn); este script solo apunta a las rutas correctas de esa escena.


func mostrar_pista(texto: String) -> void:
	var etiqueta := _buscar_label(self)
	if etiqueta != null:
		etiqueta.text = texto
	visible = true


func _buscar_label(nodo: Node) -> Label:
	if nodo is Label:
		return nodo
	for hijo in nodo.get_children():
		var encontrado := _buscar_label(hijo)
		if encontrado != null:
			return encontrado
	return null


# Conectada desde la escena al botón X
func _on_boton_cerrar_pressed() -> void:
	visible = false


func _ready() -> void:
	visible = false
