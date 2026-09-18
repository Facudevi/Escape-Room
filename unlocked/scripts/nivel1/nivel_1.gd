extends Node2D
@onready var Nivel1 = $"."
@onready var menu_pausa = $CanvasLayer2/MenuPausa
@export var vista_pizarra: CanvasLayer
# Ajusta la ruta a la imagen que usaras para el papel/nota en el inventario
@export var icono_papel: String = "res://assets/objetos/papel_nota.png"
@export var vista_papel: CanvasLayer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	menu_pausa.visible = false


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_just_pressed("ui_cancel"):
		toggle_pause()


func toggle_pause():
	get_tree().paused = !get_tree().paused
	menu_pausa.visible = get_tree().paused
	
# Función conectada a la señal input_event de AreaPizarra
func _on_area_pizarra_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("¡Clic detectado en la pizarra!")
		if vista_pizarra != null:
			vista_pizarra.abrir_pizarra()
		else:
			print("Error: La variable vista_pizarra no está asignada en el Inspector")
			
			
func _unhandled_input(event: InputEvent) -> void:
	# Si se hace clic izquierdo fuera de la UI (en el fondo o mundo 2D)
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		
		# Hacemos que espere un fotograma para que las Áreas 2D tengan prioridad
		await get_tree().process_frame
		
		if Global.item_seleccionado_idx != -1:
			Global.seleccionar_item(-1)


func _on_area_maquina_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# 1. Comprobamos si hay algún slot seleccionado
		if Global.item_seleccionado_idx != -1:
			var item_actual = Global.inventario[Global.item_seleccionado_idx]
			# 2. Verificamos si el objeto seleccionado es la moneda
			if "moneda" in item_actual:
				print("¡Moneda insertada en la máquina expendedora!")
				# 3. La moneda desaparece del inventario
				Global.eliminar_item_seleccionado()
				# 4. Agregamos el papel/nota al inventario
				var exito: bool = Global.agregar_objeto(icono_papel)
				if exito:
					print("¡Has recibido un papel con una nota!")
				else:
					print("El inventario está lleno para recibir la nota.")
			else:
				print("Ese objeto no cabe en la ranura de la máquina.")
		else:
			print("Necesitas seleccionar la moneda del inventario para usarla aquí.")
