extends Node


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	

# Señal que avisa a la UI que el inventario se actualizó
signal inventario_actualizado

# Variables globales para guardar el avance
var pizarra_resuelta: bool = false
var codigo_ingresado: String = ""
# Guardamos la cantidad de monedas o lista de ítems recolectados
var monedas: int = 0
# Lista de objetos en el inventario (guardaremos rutas de textura o nombres)
var inventario: Array = []
# Guardamos el índice del ítem seleccionado actualmente (-1 significa ninguno)
var item_seleccionado_idx: int = -1


func agregar_objeto(icono_path: String) -> bool:
	# Limitamos a 8 objetos (según la cantidad de slots que creaste)
	if inventario.size() < 8:
		inventario.append(icono_path)
		inventario_actualizado.emit()
		return true
	return false


func seleccionar_item(index: int) -> void:
	if index < inventario.size():
		item_seleccionado_idx = index
		print("Ítem seleccionado en el slot: ", index)
	else:
		item_seleccionado_idx = -1
	
	# Notificamos a la UI para que ponga o quite el borde amarillo
	inventario_actualizado.emit()


func eliminar_item_seleccionado() -> void:
	if item_seleccionado_idx != -1 and item_seleccionado_idx < inventario.size():
		inventario.remove_at(item_seleccionado_idx)
		item_seleccionado_idx = -1
		inventario_actualizado.emit() # Actualiza los slots visuales
