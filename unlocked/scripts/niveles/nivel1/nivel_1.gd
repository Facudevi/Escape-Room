extends Node2D

@onready var Nivel1 = $"."
@onready var menu_pausa = $CanvasLayer2/MenuPausa
@onready var vista_teclado: CanvasLayer = $VistaTeclado
@onready var fondo_nivel: TextureRect = $CanvasLayer/TextureRect
@onready var vista_papel: CanvasLayer = $VistaPapel
@onready var mensaje: Label = $Aviso/Mensaje
@onready var castelli: CharacterBody2D = $CanvasLayer/Castelli

# Objetos decorativos: solo responden con un aviso breve
const DECORATIVOS: Dictionary = {
	"AreaHeladera": "Solo hay jugos y lácteos. Nada útil por ahora.",
	"AreaMicroondas": "Los microondas están apagados y vacíos.",
	"AreaGondola": "Hay snacks de todo tipo, pero ninguno ayuda a salir.",
	"AreaCafetera": "La cafetera está fría y vacía.",
	"AreaTermotanque": "Un termotanque. No hay nada que hacer con él.",
	"AreaTacho": "Un tacho de basura. Solo hay desechos.",
}

# Textura de la puerta abierta para reemplazar la imagen del buffet
@export var imagen_buffet_abierto: Texture2D = preload("res://assets/fondos/buffet/buffet_fin.jpg")
@export var vista_pizarra: CanvasLayer
@export var icono_papel: String = "res://assets/objetos/nivel1/papel_nota.png"
@export var vista_papel_lupa: CanvasLayer
@export var lampara: Node2D # Referencia al nodo Lampara en la escena

# Control de estado de la puerta
var puerta_abierta: bool = false
var aviso_puerta_dado: bool = false
var caja_usada: bool = false
var completando: bool = false

# Avisos en pantalla: si hay una vista abierta el aviso espera a que se cierre
var tween_mensaje: Tween
var aviso_pendiente: String = ""
var duracion_pendiente: float = 2.5


func _ready() -> void:
	menu_pausa.visible = false
	mensaje.modulate.a = 0.0

	# Cada vez que se abre o cierra una vista se reparte quién recibe los clics. Se difiere para
	# que las áreas del mundo no reciban el mismo clic que cerró la vista
	for vista in [vista_pizarra, vista_teclado, vista_papel, vista_papel_lupa]:
		if vista != null:
			vista.visibility_changed.connect(_al_cambiar_vista, CONNECT_DEFERRED)
			vista.visibility_changed.connect(_actualizar_interactivos, CONNECT_DEFERRED)
	_actualizar_interactivos()

	if vista_teclado != null:
		vista_teclado.codigo_correcto_ingresado.connect(_on_codigo_correcto)
		vista_teclado.visibility_changed.connect(_on_teclado_visibilidad, CONNECT_DEFERRED)
	if vista_pizarra != null:
		vista_pizarra.visibility_changed.connect(_on_pizarra_visibilidad, CONNECT_DEFERRED)
		
	# Conexión automática del botón de la lámpara para activar las pistas
	if lampara != null and lampara.has_node("botonLampara"):
		var btn_lampara = lampara.get_node("botonLampara")
		if not btn_lampara.pressed.is_connected(_on_lampara_pressed):
			btn_lampara.pressed.connect(_on_lampara_pressed)

	$CanvasLayer/Moneda.aviso_solicitado.connect(mostrar_aviso)
	for nombre in DECORATIVOS:
		_conectar_clic(get_node("CanvasLayer/" + nombre), _on_decorativo_clic.bind(DECORATIVOS[nombre]))

	mostrar_aviso("Estás encerrado en el buffet. Hacé clic en los objetos para revisarlos.", 3.5)


func _process(delta):
	if Input.is_action_just_pressed("ui_cancel"):
		toggle_pause()


func toggle_pause():
	if completando:
		return
	get_tree().paused = !get_tree().paused
	menu_pausa.visible = get_tree().paused
	# El aviso no debe quedar colgado detrás del menú de pausa
	if get_tree().paused:
		_ocultar_aviso()
		aviso_pendiente = ""


# --- AVISOS EN PANTALLA (mismo sistema que los niveles 2 y 3) ---

func mostrar_aviso(texto: String, duracion: float = 2.5) -> void:
	if get_tree().paused:
		return
	if _hay_vista_abierta():
		aviso_pendiente = texto
		duracion_pendiente = duracion
		return
	mensaje.text = texto
	if tween_mensaje != null:
		tween_mensaje.kill()
	mensaje.modulate.a = 1.0
	tween_mensaje = create_tween()
	tween_mensaje.tween_interval(duracion)
	tween_mensaje.tween_property(mensaje, "modulate:a", 0.0, 0.5)


func _ocultar_aviso() -> void:
	if tween_mensaje != null:
		tween_mensaje.kill()
	mensaje.modulate.a = 0.0


func _hay_vista_abierta() -> bool:
	return (vista_pizarra != null and vista_pizarra.visible) or \
		   (vista_teclado != null and vista_teclado.visible) or \
		   (vista_papel != null and vista_papel.visible) or \
		   (vista_papel_lupa != null and vista_papel_lupa.visible)


# --- CAPAS INTERACTIVAS (mundo y vistas de zoom) ---

# Con una vista abierta las áreas del mundo se desactivan de verdad (sin detección ni clics),
# la lámpara no se puede pulsar y Castelli no se mueve. Al cerrar la vista todo vuelve
func _actualizar_interactivos() -> void:
	var hay_vista: bool = _hay_vista_abierta()
	_activar_areas($CanvasLayer, not hay_vista)
	if lampara != null and lampara.has_node("botonLampara"):
		lampara.get_node("botonLampara").disabled = hay_vista
	if not completando:
		castelli.process_mode = Node.PROCESS_MODE_DISABLED if hay_vista else Node.PROCESS_MODE_INHERIT


# Activa o desactiva los clics y la detección de las Area2D hijas; no toca ninguna colisión
func _activar_areas(raiz: Node, activo: bool) -> void:
	for hijo in raiz.get_children():
		if hijo is Area2D:
			hijo.input_pickable = activo
			hijo.set_deferred("monitoring", activo)
			hijo.set_deferred("monitorable", activo)


# Indica si hay una zona de interacción activa del mundo bajo el punto (sin esperar a la física)
func _hay_objeto_en(posicion: Vector2) -> bool:
	for area in $CanvasLayer.get_children():
		if area is Area2D and area.input_pickable:
			for forma in area.get_children():
				if forma is CollisionShape2D and forma.shape != null:
					var local: Vector2 = forma.get_global_transform().affine_inverse() * posicion
					if forma.shape.get_rect().has_point(local):
						return true
	return false


# Al abrir una vista se limpia el aviso del mundo; al cerrarla sale el que quedó esperando
func _al_cambiar_vista() -> void:
	if _hay_vista_abierta():
		_ocultar_aviso()
	elif aviso_pendiente != "":
		var texto: String = aviso_pendiente
		aviso_pendiente = ""
		mostrar_aviso(texto, duracion_pendiente)


# Función conectada a la señal input_event de AreaPizarra
func _on_area_pizarra_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if vista_pizarra != null:
			# Se abre primero la vista para que el aviso espere a que se cierre
			vista_pizarra.abrir_pizarra()
		else:
			print("Error: La variable vista_pizarra no está asignada en el Inspector")
			
			
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if get_tree().paused or _hay_vista_abierta():
			return
		# Un clic sobre un objeto lo resuelve el propio objeto con el ítem seleccionado;
		# solo un clic en el vacío deselecciona
		if Global.item_seleccionado_idx != -1 and not _hay_objeto_en(make_input_local(event).position):
			Global.seleccionar_item(-1)


func _on_area_maquina_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if caja_usada:
			mostrar_aviso("La caja ya no tiene nada más para darte.")
			return
		var item_actual: String = _item_seleccionado()
		if item_actual == "":
			mostrar_aviso("La caja registradora tiene una ranura. Necesitás algo para usarla.", 3.5)
		elif "moneda" in item_actual:
			_consumir_item_seleccionado()
			caja_usada = true
			Global.agregar_objeto(icono_papel)
			mostrar_aviso("La moneda cae y la caja suelta un papel. Hacé doble clic en él para leerlo.", 4.0)
		else:
			mostrar_aviso("Eso no entra en la ranura.")


func _on_area_teclado_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if vista_teclado != null:
			vista_teclado.abrir_teclado()


# Al cerrar la pizarra o el teclado sale el aviso del objeto (ver mostrar_aviso)
func _on_pizarra_visibilidad() -> void:
	if vista_pizarra.visible:
		return
	mostrar_aviso("Anotaste los precios del cartel. Pueden servirte más adelante.", 3.5)


func _on_teclado_visibilidad() -> void:
	if vista_teclado.visible:
		return
	if not puerta_abierta:
		mostrar_aviso("La puerta pide un código de 3 cifras. Seguí buscando pistas.", 3.5)
	elif not aviso_puerta_dado:
		aviso_puerta_dado = true
		mostrar_aviso("¡Código correcto! Se oyó un clic en la puerta.", 3.5)
	else:
		mostrar_aviso("El teclado ya está desbloqueado. Ya podés salir.", 3.5)


# --- INVENTARIO Y OBJETOS DECORATIVOS ---

# Ruta del ítem seleccionado en el inventario ("" si no hay ninguno)
func _item_seleccionado() -> String:
	var idx: int = Global.item_seleccionado_idx
	if idx < 0 or idx >= Global.inventario.size():
		return ""
	return str(Global.inventario[idx])


# Quita el ítem seleccionado sin dejar un hueco vacío en el inventario
func _consumir_item_seleccionado() -> void:
	var idx: int = Global.item_seleccionado_idx
	if idx < 0 or idx >= Global.inventario.size():
		return
	Global.seleccionar_item(-1)
	Global.inventario.remove_at(idx)
	Global.inventario_actualizado.emit()


# Conecta el clic izquierdo de un Area2D a una función sin argumentos
func _conectar_clic(area: Area2D, accion: Callable) -> void:
	area.input_event.connect(func(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			accion.call())


func _on_decorativo_clic(texto: String) -> void:
	if _item_seleccionado() != "":
		mostrar_aviso("Eso no sirve acá.")
	else:
		mostrar_aviso(texto)


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
			mostrar_aviso("La puerta está cerrada. El teclado de al lado pide un código.", 3.5)


func completar_juego() -> void:
	if completando:
		return
	completando = true
	castelli.process_mode = Node.PROCESS_MODE_DISABLED
	mostrar_aviso("¡NIVEL 1 COMPLETADO!", 2.0)
	await get_tree().create_timer(1.5).timeout
	Global.reiniciar_datos()
	get_tree().change_scene_to_file("res://escenas/menus/niveles.tscn")
