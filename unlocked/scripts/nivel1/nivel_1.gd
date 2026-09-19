extends Node2D
@onready var Nivel1 = $"."
@onready var menu_pausa = $CanvasLayer2/MenuPausa
@onready var vista_teclado: CanvasLayer = $VistaTeclado
# Nodo del fondo principal donde se muestra la imagen del nivel
@onready var fondo_nivel: TextureRect = $CanvasLayer/TextureRect 

# Textura de la puerta abierta para reemplazar la imagen del buffet
@export var imagen_buffet_abierto: Texture2D = preload("res://assets/imagen/buffet/buffet_fin.jpg")
@export var vista_pizarra: CanvasLayer
@export var icono_papel: String = "res://assets/objetos/papel_nota.png"
@export var vista_papel: CanvasLayer

# Control de estado de la puerta
var puerta_abierta: bool = false


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	menu_pausa.visible = false
	if vista_teclado != null:
		vista_teclado.codigo_correcto_ingresado.connect(_on_codigo_correcto)


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



func _on_area_teclado_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if vista_teclado != null:
			vista_teclado.abrir_teclado()


# --- LÓGICA DE APERTURA Y SALIDA CONDICIONAL ---

# 1. Se activa únicamente cuando se ingresa el código correcto en el teclado
func _on_codigo_correcto() -> void:
	puerta_abierta = true
	print("¡Código correcto! Cambiando imagen del fondo...")
	
	if fondo_nivel != null and imagen_buffet_abierto != null:
		fondo_nivel.texture = imagen_buffet_abierto


# 2. Solo responde al CLIC sobre el AreaSalida si la puerta ya fue desbloqueada
func _on_area_salida_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if puerta_abierta:
			completar_juego()
		else:
			print("La puerta sigue cerrada. Debes resolver el código primero.")


# 3. Finaliza el juego
func completar_juego() -> void:
	print("¡HAS ESCAPADO CON ÉXITO! Fin del nivel.")
	# Cambia a la pantalla de victoria o niveles
	get_tree().change_scene_to_file("res://escenas/settings/niveles.tscn")
