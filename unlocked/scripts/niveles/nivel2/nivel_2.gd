extends Node2D

@onready var Nivel2 = $"."
@onready var menu_pausa = $CanvasLayer2/MenuPausa
@onready var fondo_nivel: TextureRect = $CanvasLayer/TextureRect
@onready var sprite_candado: Sprite2D = $CanvasLayer/SpriteCandado
@onready var castelli: CharacterBody2D = $CanvasLayer/Castelli
@onready var mensaje: Label = $Aviso/Mensaje

# Rutas de ítems exportadas
@export var icono_toalla_seca: String = "res://assets/objetos/nivel2/toalla_seca.png"
@export var icono_toalla_mojada: String = "res://assets/objetos/nivel2/toalla_mojada.png"
@export var icono_llave: String = "res://assets/objetos/nivel2/llave.png"

# Vistas de Zoom
@export var vista_espejo: CanvasLayer
@export var vista_cubiculo: CanvasLayer
@export var vista_candado: CanvasLayer
@export var vista_papel_lupa: CanvasLayer
@export var lampara: Node2D # Referencia al nodo Lampara en la escena

# Carga de imágenes del fondo principal
var imagen_bano_inicial: Texture2D = preload("res://assets/fondos/bano/bano_inicial.png")
var imagen_bano_espejo_limpio: Texture2D = preload("res://assets/fondos/bano/bano_espejo_limpio.png")
var imagen_bano_cubiculo_abierto: Texture2D = preload("res://assets/fondos/bano/bano_cubiculo_abierto.png")
var imagen_bano_final: Texture2D = preload("res://assets/fondos/bano/bano_final.png")

# Estados del nivel
var dispensador_usado: bool = false
var intento_espejo: bool = false
var intento_candado: bool = false
var espejo_limpio: bool = false
var cubiculo_abierto: bool = false
var puerta_salida_abierta: bool = false
var completando: bool = false

# Avisos en pantalla
var tween_mensaje: Tween
var avisos_mostrados: int = 0
var hay_vista_previa: bool = false


func _ready() -> void:
	if menu_pausa != null:
		menu_pausa.visible = false
	mensaje.modulate.a = 0.0

	# Conexión Espejo
	if vista_espejo != null:
		if not vista_espejo.espejo_limpiado_exitosamente.is_connected(_on_espejo_limpiado):
			vista_espejo.espejo_limpiado_exitosamente.connect(_on_espejo_limpiado)
		if not vista_espejo.mancha_tocada.is_connected(_on_mancha_tocada):
			vista_espejo.mancha_tocada.connect(_on_mancha_tocada)

	# Conexión Cubículo -> Candado
	if vista_cubiculo != null:
		if not vista_cubiculo.abrir_zoom_candado.is_connected(_on_abrir_zoom_candado):
			vista_cubiculo.abrir_zoom_candado.connect(_on_abrir_zoom_candado)
		if not vista_cubiculo.aviso_solicitado.is_connected(mostrar_aviso):
			vista_cubiculo.aviso_solicitado.connect(mostrar_aviso)

	# Conexión Desbloqueo Candado
	if vista_candado != null:
		if not vista_candado.candado_desbloqueado_exitosamente.is_connected(_on_candado_desbloqueado):
			vista_candado.candado_desbloqueado_exitosamente.connect(_on_candado_desbloqueado)

	# Conexión de la señal solicitar_pista desde la lámpara
	if lampara != null:
		if not lampara.solicitar_pista.is_connected(_on_solicitar_pista):
			lampara.solicitar_pista.connect(_on_solicitar_pista)

	# Objetos sin zona conectada desde la escena
	_conectar_clic($CanvasLayer/AreaDispensador, _on_dispensador_clic)
	_conectar_clic($CanvasLayer/AreaJabon, _on_jabon_clic)
	_conectar_clic($CanvasLayer/AreaEstante, _on_estante_clic)
	_conectar_clic($CanvasLayer/AreaEscobilla, _on_escobilla_clic)

	# Cada vez que se abre o cierra una vista se reparte quién recibe los clics. Se difiere para
	# que las áreas de la vista recién abierta no reciban el mismo clic que la abrió
	for vista in [vista_espejo, vista_cubiculo, vista_candado, vista_papel_lupa]:
		if vista != null:
			vista.visibility_changed.connect(_al_cambiar_vista)
			vista.visibility_changed.connect(_actualizar_interactivos, CONNECT_DEFERRED)
	_actualizar_interactivos()

	_aviso_inicial()


func toggle_pause():
	get_tree().paused = !get_tree().paused
	if menu_pausa != null:
		menu_pausa.visible = get_tree().paused


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		toggle_pause()
		return

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if get_tree().paused or _hay_vista_abierta():
			return

		# Un clic sobre un objeto lo resuelve el propio objeto con el ítem seleccionado;
		# solo un clic en el vacío deselecciona
		if Global.item_seleccionado_idx != -1 and not _hay_objeto_en(make_input_local(event).position):
			Global.seleccionar_item(-1)


# Indica si hay una zona de interacción activa del fondo bajo el punto (sin esperar a la física)
func _hay_objeto_en(posicion: Vector2) -> bool:
	for area in $CanvasLayer.get_children():
		if area is Area2D and area.input_pickable:
			for forma in area.get_children():
				if forma is CollisionShape2D and forma.shape != null:
					var local: Vector2 = forma.get_global_transform().affine_inverse() * posicion
					if forma.shape.get_rect().has_point(local):
						return true
	return false


func _hay_vista_abierta() -> bool:
	return (vista_espejo != null and vista_espejo.visible) or \
		   (vista_cubiculo != null and vista_cubiculo.visible) or \
		   (vista_candado != null and vista_candado.visible) or \
		   (vista_papel_lupa != null and vista_papel_lupa.visible)


# --- CAPAS INTERACTIVAS (fondo y vistas de zoom) ---

# Al salir del fondo hacia un zoom se limpia el aviso del fondo para que no quede colgado
func _al_cambiar_vista() -> void:
	var hay_vista: bool = _hay_vista_abierta()
	if hay_vista and not hay_vista_previa:
		_ocultar_aviso()
	hay_vista_previa = hay_vista


# Solo la capa visible más alta recibe clics: las áreas de las demás se desactivan de verdad
func _actualizar_interactivos() -> void:
	var candado_abierto: bool = vista_candado != null and vista_candado.visible
	var zoom_cubiculo: bool = vista_cubiculo != null and vista_cubiculo.visible
	var zoom_espejo: bool = vista_espejo != null and vista_espejo.visible
	var papel_abierto: bool = vista_papel_lupa != null and vista_papel_lupa.visible
	var hay_vista: bool = candado_abierto or zoom_cubiculo or zoom_espejo or papel_abierto

	_activar_areas($CanvasLayer, not hay_vista)
	_activar_areas(vista_cubiculo, zoom_cubiculo and not candado_abierto and not papel_abierto)
	_activar_areas(vista_espejo, zoom_espejo and not zoom_cubiculo and not candado_abierto and not papel_abierto)
	castelli.process_mode = Node.PROCESS_MODE_DISABLED if hay_vista else Node.PROCESS_MODE_INHERIT


# Activa o desactiva los clics y la detección de las Area2D hijas; no toca ninguna colisión
func _activar_areas(raiz: Node, activo: bool) -> void:
	if raiz == null:
		return
	for hijo in raiz.get_children():
		if hijo is Area2D:
			hijo.input_pickable = activo
			hijo.set_deferred("monitoring", activo)
			hijo.set_deferred("monitorable", activo)


# --- AVISOS EN PANTALLA (mismo sistema que el Nivel 3) ---

func mostrar_aviso(texto: String, duracion: float = 2.5) -> void:
	avisos_mostrados += 1
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


# Guía de arranque: dice dónde está el jugador y señala el espejo como primer objetivo
func _aviso_inicial() -> void:
	mostrar_aviso("Estás encerrado en el baño. Hacé clic en los objetos para revisarlos.", 3.5)
	await get_tree().create_timer(4.0).timeout
	if avisos_mostrados == 1 and not hay_vista_previa:
		mostrar_aviso("Ese espejo está cubierto de mugre... ¿habrá algo escondido debajo?", 4.0)


# Conecta el clic izquierdo de un Area2D a una función sin argumentos
func _conectar_clic(area: Area2D, accion: Callable) -> void:
	area.input_event.connect(func(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			accion.call())


# --- INVENTARIO ---

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


# --- INTERACCIONES DEL BAÑO ---

func _on_dispensador_clic() -> void:
	if dispensador_usado:
		mostrar_aviso("El dispensador ya está vacío.")
	elif Global.agregar_objeto(icono_toalla_seca):
		dispensador_usado = true
		mostrar_aviso("Sacaste una toalla de papel. Hacé clic en ella en el inventario para seleccionarla.", 4.0)
	else:
		mostrar_aviso("El inventario está lleno.")


func _on_area_tacho_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		mostrar_aviso("Solo hay papeles usados. Nada útil.")


func _on_jabon_clic() -> void:
	mostrar_aviso("Un dispensador de jabón. No hay nada más.")


func _on_estante_clic() -> void:
	mostrar_aviso("Frascos vacíos. Nada útil.")


func _on_escobilla_clic() -> void:
	mostrar_aviso("Mejor no tocarla.")


func _on_area_canilla_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var item_actual: String = _item_seleccionado()
		if item_actual == "":
			mostrar_aviso("Sale agua. Quizás sirva para mojar algo.")
		elif item_actual == icono_toalla_seca:
			# La toalla mojada reemplaza a la seca en su mismo casillero
			Global.inventario[Global.item_seleccionado_idx] = icono_toalla_mojada
			Global.inventario_actualizado.emit()
			mostrar_aviso("Mojaste la toalla de papel. Ahora está empapada.", 3.5)
		elif item_actual == icono_toalla_mojada:
			mostrar_aviso("La toalla ya está mojada.")
		else:
			mostrar_aviso("Eso no se moja.")


func _on_area_espejo_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not espejo_limpio:
			intento_espejo = true

		if vista_espejo != null:
			vista_espejo.abrir_vista_espejo(espejo_limpio)
		if not espejo_limpio:
			mostrar_aviso("Está muy sucio. Necesitás algo para limpiarlo.")


# Clic sobre la mancha dentro del zoom del espejo
func _on_mancha_tocada() -> void:
	var item_actual: String = _item_seleccionado()
	if item_actual == "":
		mostrar_aviso("La mugre no sale con la mano. Seleccioná un objeto del inventario y probá.", 3.5)
	elif item_actual == icono_toalla_seca:
		mostrar_aviso("Seca solo corre la mugre. Necesita agua.")
	elif item_actual == icono_toalla_mojada:
		_consumir_item_seleccionado()
		vista_espejo.limpiar()
		mostrar_aviso("¡Limpiaste el espejo! Había algo escrito debajo de la mugre.", 3.5)
	else:
		mostrar_aviso("Eso no sirve para limpiar.")


func _on_espejo_limpiado() -> void:
	espejo_limpio = true
	_actualizar_fondo()


# El fondo se deduce siempre del estado, sin depender del orden en que ocurrieron los eventos
func _actualizar_fondo() -> void:
	if fondo_nivel == null:
		return
	if puerta_salida_abierta:
		fondo_nivel.texture = imagen_bano_final
	elif cubiculo_abierto:
		fondo_nivel.texture = imagen_bano_cubiculo_abierto
	elif espejo_limpio:
		fondo_nivel.texture = imagen_bano_espejo_limpio
	else:
		fondo_nivel.texture = imagen_bano_inicial


# --- FLUJO CUBÍCULO Y CANDADO ---

func _on_area_cubiculo_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if vista_cubiculo != null:
			vista_cubiculo.abrir_vista(cubiculo_abierto)
		if not cubiculo_abierto:
			intento_candado = true
			mostrar_aviso("Los cubículos están cerrados con un candado de 4 cifras.", 3.5)


func _on_abrir_zoom_candado() -> void:
	if not cubiculo_abierto and vista_candado != null:
		vista_candado.abrir_vista()


func _on_candado_desbloqueado() -> void:
	cubiculo_abierto = true
	# El fondo con el cubículo abierto ya muestra el espejo limpio: el zoom debe coincidir
	espejo_limpio = true
	mostrar_aviso("¡Clic! El candado se abre.")

	if sprite_candado != null:
		sprite_candado.visible = false
		sprite_candado.queue_free()

	if vista_cubiculo != null:
		vista_cubiculo.desbloquear_cubiculo_zoom()

	_actualizar_fondo()


# --- PASO FINAL: PUERTA DE SALIDA Y VICTORIA ---

func _on_area_salida_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if puerta_salida_abierta:
			completar_nivel_2()
			return

		var item_actual: String = _item_seleccionado()
		if item_actual == "":
			mostrar_aviso("Está cerrada con llave.")
		elif item_actual == icono_llave:
			_consumir_item_seleccionado()
			puerta_salida_abierta = true
			mostrar_aviso("¡Clac! La puerta se abre. Hacé clic de nuevo para salir.", 3.5)
			_actualizar_fondo()
		else:
			mostrar_aviso("Eso no abre la puerta.")


func completar_nivel_2() -> void:
	if completando:
		return
	completando = true
	castelli.process_mode = Node.PROCESS_MODE_DISABLED
	mostrar_aviso("¡NIVEL 2 COMPLETADO!", 2.0)
	await get_tree().create_timer(1.5).timeout
	Global.reiniciar_datos()
	get_tree().change_scene_to_file("res://escenas/menus/niveles.tscn")


# --- PISTAS DE LA LÁMPARA (según el progreso, de la última etapa a la primera) ---

func _on_solicitar_pista() -> void:
	if vista_papel_lupa == null:
		print("Error: vista_papel_lupa no está asignada en el Inspector.")
		return

	if vista_papel_lupa.has_method("mostrar_pista"):
		vista_papel_lupa.mostrar_pista(_texto_pista())
	else:
		vista_papel_lupa.visible = true


func _texto_pista() -> String:
	var tiene_seca: bool = Global.inventario.has(icono_toalla_seca)
	var tiene_mojada: bool = Global.inventario.has(icono_toalla_mojada)
	var tiene_llave: bool = Global.inventario.has(icono_llave)

	if puerta_salida_abierta:
		return "La puerta ya está abierta. ¡Salí!"
	if tiene_llave:
		return "Esa llave abre algo. Seleccionala en el inventario y probá en la puerta del cartel de SALIDA."
	if cubiculo_abierto:
		return "El candado ya no está. Revisá con atención el cubículo abierto."
	if espejo_limpio:
		if intento_candado:
			return "El candado pide cuatro cifras. ¿Dónde viste un número de cuatro cifras?"
		return "Mirá bien lo que había debajo de la mugre. Un número así debe servir para algo: revisá los cubículos."
	if tiene_mojada:
		return "La toalla ya está mojada. Probala sobre algo muy sucio."
	if tiene_seca:
		return "Una toalla de papel seca no limpia nada. ¿Qué hay en el baño que dé agua?"
	if intento_espejo:
		return "Para limpiarlo necesitás algo absorbente: buscalo junto al lavamanos."
	return "Ese espejo tan sucio no está así porque sí. Revisá los objetos junto al lavamanos."
