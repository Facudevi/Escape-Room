extends Node
# Animaciones y transiciones de interfaz compartidas por todo el juego.
# Es solo presentación: no cambia estados, inventario ni lógica de los niveles.

const TINTA := Color("1B2540")
const MADERA := Color("8A5A33")
const MADERA_CLARA := Color("A06E42")
const SOL := Color("FFD23F")

# --- Transición de puertas ---
var _raiz: Control
var _hoja_izq: Panel
var _hoja_der: Panel
var _progreso: float = 0.0
var _cambiando: bool = false

# --- Cursor sobre objetos clicables ---
var _area_activa: Area2D = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_crear_puertas()
	get_tree().node_added.connect(_al_agregar_nodo)
	# La escena inicial ya puede estar en el árbol antes de que este autoload escuche node_added,
	# así que se recorre una vez lo que ya existe (solo conecta nodos que aún no están conectados)
	_conectar_existentes.call_deferred(get_tree().root)


func _conectar_existentes(nodo: Node) -> void:
	_al_agregar_nodo(nodo)
	for hijo in nodo.get_children():
		_conectar_existentes(hijo)


func _process(_delta: float) -> void:
	# Si el área deja de ser clicable (se abrió una vista o se pausó) se restablece el cursor
	if _area_activa != null:
		if not is_instance_valid(_area_activa) or not _area_activa.input_pickable \
				or get_tree().paused or not _area_activa.is_visible_in_tree():
			_area_sale(_area_activa)


func _al_agregar_nodo(nodo: Node) -> void:
	if nodo is Button:
		_conectar_boton(nodo)
	elif nodo is Area2D:
		_conectar_area(nodo)


# ---------------------------------------------------------------------------
# TRANSICIÓN ENTRE PANTALLAS (puertas de colegio)
# ---------------------------------------------------------------------------

func cambiar_escena(ruta: String) -> void:
	if _cambiando:
		return
	_cambiando = true
	_raiz.visible = true
	_raiz.mouse_filter = Control.MOUSE_FILTER_STOP
	await _mover_puertas(1.0, 0.42)
	await get_tree().create_timer(0.1, true, false, true).timeout
	get_tree().change_scene_to_file(ruta)
	await get_tree().process_frame
	await get_tree().process_frame
	await _mover_puertas(0.0, 0.5)
	_raiz.visible = false
	_raiz.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cambiando = false


func _mover_puertas(destino: float, duracion: float) -> void:
	var t := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	t.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	t.tween_method(_poner_puertas, _progreso, destino, duracion)
	await t.finished


func _poner_puertas(p: float) -> void:
	if _hoja_izq == null or _hoja_der == null:
		return
	_progreso = p
	var ancho: float = _raiz.size.x * 0.505
	_hoja_izq.size = Vector2(ancho, _raiz.size.y)
	_hoja_der.size = Vector2(ancho, _raiz.size.y)
	_hoja_izq.position = Vector2(-ancho * (1.0 - p), 0)
	_hoja_der.position = Vector2(_raiz.size.x - ancho * p, 0)


func _crear_puertas() -> void:
	var capa := CanvasLayer.new()
	capa.layer = 100
	capa.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(capa)
	_raiz = Control.new()
	_raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	_raiz.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_raiz.visible = false
	_raiz.resized.connect(func() -> void: _poner_puertas(_progreso))
	capa.add_child(_raiz)
	_hoja_izq = _crear_hoja(false)
	_hoja_der = _crear_hoja(true)


func _crear_hoja(derecha: bool) -> Panel:
	var hoja := Panel.new()
	hoja.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hoja.add_theme_stylebox_override("panel", _estilo(MADERA, TINTA, 6, 0))
	_raiz.add_child(hoja)
	var interior := Panel.new()
	interior.mouse_filter = Control.MOUSE_FILTER_IGNORE
	interior.set_anchors_preset(Control.PRESET_FULL_RECT)
	interior.offset_left = 22
	interior.offset_top = 22
	interior.offset_right = -22
	interior.offset_bottom = -22
	interior.add_theme_stylebox_override("panel", _estilo(MADERA_CLARA, TINTA, 4, 4))
	hoja.add_child(interior)
	var manija := Panel.new()
	manija.mouse_filter = Control.MOUSE_FILTER_IGNORE
	manija.anchor_top = 0.5
	manija.anchor_bottom = 0.5
	manija.anchor_left = 0.0 if derecha else 1.0
	manija.anchor_right = manija.anchor_left
	var x: float = 40.0 if derecha else -58.0
	manija.offset_left = x
	manija.offset_right = x + 18.0
	manija.offset_top = -26.0
	manija.offset_bottom = 26.0
	manija.add_theme_stylebox_override("panel", _estilo(SOL, TINTA, 4, 8))
	hoja.add_child(manija)
	return hoja


func _estilo(color: Color, borde: Color, ancho: int, radio: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.border_color = borde
	s.set_border_width_all(ancho)
	s.set_corner_radius_all(radio)
	return s


# ---------------------------------------------------------------------------
# BOTONES: se inclinan al pasar el mouse y se hunden al hacer clic
# ---------------------------------------------------------------------------

func _conectar_boton(boton: Button) -> void:
	if boton.has_meta("fx_conectado"):
		return
	boton.set_meta("fx_conectado", true)
	boton.mouse_entered.connect(_boton_entra.bind(boton))
	boton.mouse_exited.connect(_boton_sale.bind(boton))
	boton.button_down.connect(_boton_baja.bind(boton))
	boton.button_up.connect(_boton_sube.bind(boton))
	boton.visibility_changed.connect(func() -> void:
		if not boton.is_visible_in_tree():
			_reposo(boton))


func _es_cerrar(boton: Button) -> bool:
	return boton.theme_type_variation == &"BotonCerrar" or boton.theme_type_variation == &"BotonCerrarMini"


func _boton_entra(boton: Button) -> void:
	if boton.disabled:
		return
	if _es_cerrar(boton):
		_animar(boton, 1.1, PI / 2.0, 0.22)
	else:
		_animar(boton, 1.04, -0.014, 0.14)


func _boton_sale(boton: Button) -> void:
	_animar(boton, 1.0, 0.0, 0.14)
	_mover_contenido(boton, 0.0)


func _boton_baja(boton: Button) -> void:
	if boton.disabled:
		return
	_animar(boton, 0.96, boton.rotation, 0.06, Tween.TRANS_QUAD)
	_mover_contenido(boton, 5.0)


func _boton_sube(boton: Button) -> void:
	_mover_contenido(boton, 0.0)
	if boton.is_hovered() and not boton.disabled:
		_boton_entra(boton)
	else:
		_animar(boton, 1.0, 0.0, 0.14)


func _reposo(boton: Button) -> void:
	_matar_tween(boton, "fx_tween")
	boton.scale = Vector2.ONE
	boton.rotation = 0.0
	_mover_contenido(boton, 0.0, true)


func _animar(control: Control, escala: float, giro: float, dur: float, trans: Tween.TransitionType = Tween.TRANS_BACK) -> void:
	_matar_tween(control, "fx_tween")
	control.pivot_offset = control.size / 2.0
	var t := control.create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	t.set_trans(trans).set_ease(Tween.EASE_OUT).set_parallel(true)
	t.tween_property(control, "scale", Vector2(escala, escala), dur)
	t.tween_property(control, "rotation", giro, dur)
	control.set_meta("fx_tween", t)


# Los botones con ícono y subtítulo guardan sus textos en un nodo "Contenido" que acompaña el hundimiento
func _mover_contenido(boton: Button, y: float, instantaneo: bool = false) -> void:
	var contenido: Control = boton.get_node_or_null("Contenido")
	if contenido == null:
		return
	_matar_tween(contenido, "fx_tween")
	if instantaneo:
		contenido.position.y = y
		return
	var t := contenido.create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	t.tween_property(contenido, "position:y", y, 0.06)
	contenido.set_meta("fx_tween", t)


func _matar_tween(nodo: Node, clave: String) -> void:
	if nodo.has_meta(clave):
		var viejo: Tween = nodo.get_meta(clave)
		if viejo != null and viejo.is_valid():
			viejo.kill()


# ---------------------------------------------------------------------------
# ENTRADA ESCALONADA: los controles caen uno tras otro con un rebote suave
# ---------------------------------------------------------------------------

func entrada_escalonada(controles: Array) -> void:
	for c in controles:
		(c as Control).modulate.a = 0.0
	# Se espera a que el contenedor acomode a los hijos antes de leer su posición
	await get_tree().process_frame
	await get_tree().process_frame
	var i: int = 0
	for c in controles:
		var control: Control = c
		if not is_instance_valid(control):
			continue
		var destino: float = control.position.y
		control.position.y = destino - 260.0
		var t := control.create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		t.tween_interval(0.09 * i)
		t.tween_callback(func() -> void: control.modulate.a = 1.0)
		t.tween_property(control, "position:y", destino, 0.55).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		i += 1


# ---------------------------------------------------------------------------
# OBJETOS CLICABLES: cursor de mano al pasar el mouse
# ---------------------------------------------------------------------------

func _conectar_area(area: Area2D) -> void:
	if area.has_meta("fx_conectado"):
		return
	area.set_meta("fx_conectado", true)
	area.mouse_entered.connect(_area_entra.bind(area))
	area.mouse_exited.connect(_area_sale.bind(area))


func _area_entra(area: Area2D) -> void:
	if not area.input_pickable or get_tree().paused:
		return
	if _area_activa != null and _area_activa != area:
		_area_sale(_area_activa)
	_area_activa = area
	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)


func _area_sale(area: Area2D) -> void:
	if area == _area_activa:
		_area_activa = null
		Input.set_default_cursor_shape(Input.CURSOR_ARROW)
