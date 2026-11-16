extends Node

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

# Señal que avisa a la UI que el inventario se actualizó
signal inventario_actualizado

# Progreso de niveles: último nivel completado (0 = ninguno). Vive solo en memoria,
# así que arranca en 0 cada vez que se abre el juego. reiniciar_datos() NO lo toca.
var nivel_maximo_completado: int = 0

# El nivel 1 siempre está disponible; completar el nivel N libera el N+1
func esta_desbloqueado(nivel: int) -> bool:
	return nivel <= nivel_maximo_completado + 1

# Rejugar un nivel anterior nunca baja el progreso
func registrar_nivel_completado(nivel: int) -> void:
	nivel_maximo_completado = maxi(nivel_maximo_completado, nivel)

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
	# 1. Si el array tiene menos de 8 elementos, simplemente agregamos
	if inventario.size() < 8:
		inventario.append(icono_path)
		inventario_actualizado.emit()
		return true
	
	# 2. Si tiene 8 elementos pero alguno es un espacio vacío (""), ocupamos esa casilla
	for i in range(inventario.size()):
		if inventario[i] == "":
			inventario[i] = icono_path
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
		inventario[item_seleccionado_idx] = ""
		item_seleccionado_idx = -1
		inventario_actualizado.emit() # Actualiza los slots visuales

func reiniciar_datos() -> void:
	# Reiniciamos las variables a su estado inicial real
	monedas = 0
	pizarra_resuelta = false
	codigo_ingresado = ""
	
	# Vaciamos el array por completo (tamaño 0)
	inventario.clear()
	item_seleccionado_idx = -1
	
	inventario_actualizado.emit()
