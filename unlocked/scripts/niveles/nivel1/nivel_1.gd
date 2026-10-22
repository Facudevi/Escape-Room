extends Node2D

@onready var Nivel1 = $"."
@onready var menu_pausa = $CanvasLayer2/MenuPausa
@onready var vista_teclado: CanvasLayer = $VistaTeclado
@onready var fondo_nivel: TextureRect = $CanvasLayer/TextureRect 

# Textura de la puerta abierta para reemplazar la imagen del buffet
@export var imagen_buffet_abierto: Texture2D = preload("res://assets/fondos/buffet/buffet_fin.jpg")
@export var vista_pizarra: CanvasLayer
@export var icono_papel: String = "res://assets/objetos/nivel1/papel_nota.png"
@export var vista_papel_lupa: CanvasLayer
@export var lampara: Node2D # Referencia al nodo Lampara en la escena

# Control de estado de la puerta
var puerta_abierta: bool = false


func _ready() -> void:
	menu_pausa.visible = false
	if vista_teclado != null:
		vista_teclado.codigo_correcto_ingresado.connect(_on_codigo_correcto)
		
	# Conexión automática del botón de la lámpara para activar las pistas
	if lampara != null and lampara.has_node("botonLampara"):
		var btn_lampara = lampara.get_node("botonLampara")
		if not btn_lampara.pressed.is_connected(_on_lampara_pressed):
			btn_lampara.pressed.connect(_on_lampara_pressed)


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
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		await get_tree().process_frame
		if Global.item_seleccionado_idx != -1:
			Global.seleccionar_item(-1)


func _on_area_maquina_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if Global.item_seleccionado_idx != -1:
			var item_actual = Global.inventario[Global.item_seleccionado_idx]
			if "moneda" in item_actual:
				print("¡Moneda insertada en la máquina expendedora!")
				Global.eliminar_item_seleccionado()
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


# # --- LÓGICA DE PISTAS CON LA LÁMPARA (FLUJO ACTUALIZADO) ---

func _on_lampara_pressed() -> void:
	if vista_papel_lupa == null:
		print("Error: vista_papel_lupa no está asignada en el Inspector.")
		return
		
	var texto_pista: String = ""
	
	# Verificamos los estados actuales del jugador
	var tiene_moneda: bool = false
	var tiene_nota: bool = false
	
	# Revisamos el inventario global y los ítems recolectados
	for item in Global.inventario:
		if item != null:
			if "moneda" in item:
				tiene_moneda = true
			if "papel_nota" in item or "papel" in item:
				tiene_nota = true
				
	# Determinamos la pista exacta según el flujo del nivel:
	if puerta_abierta:
		texto_pista = "¡Lo lograste! Ahora escapa del buffet!."
	elif tiene_nota:
		texto_pista = "La nota tiene información importante, pero todavía te falta algo. Deberás utilizarla para obtener el código"
	elif tiene_moneda:
		texto_pista = "¡Encontraste algo útil! ¿Habrá alguna máquina o algún objeto que puedas activar con esa moneda?"
	else:
		texto_pista = "A veces, los objetos más pequeños esconden la clave para avanzar. ¡Revisá bien el entorno!"
		
	# Mostramos el texto en el papel lupa
	if vista_papel_lupa.has_method("mostrar_pista"):
		vista_papel_lupa.mostrar_pista(texto_pista)
	else:
		vista_papel_lupa.visible = true


# --- LÓGICA DE APERTURA Y SALIDA CONDICIONAL ---

func _on_codigo_correcto() -> void:
	puerta_abierta = true
	print("¡Código correcto! Cambiando imagen del fondo...")
	
	if fondo_nivel != null and imagen_buffet_abierto != null:
		fondo_nivel.texture = imagen_buffet_abierto


func _on_area_salida_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if puerta_abierta:
			completar_juego()
		else:
			print("La puerta sigue cerrada. Debes resolver el código primero.")


func completar_juego() -> void:
	print("¡HAS ESCAPADO CON ÉXITO! Fin del nivel.")
	Global.reiniciar_datos()
	get_tree().change_scene_to_file("res://escenas/menus/niveles.tscn")
