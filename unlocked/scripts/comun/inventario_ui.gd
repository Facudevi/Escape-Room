extends CanvasLayer

const SOL := Color("FFD23F")

# Referencias a los 8 Slots del Panel
@onready var slots: Array = [
	$PanelInventario/ContenedorSlots/Slot1,
	$PanelInventario/ContenedorSlots/Slot2,
	$PanelInventario/ContenedorSlots/Slot3,
	$PanelInventario/ContenedorSlots/Slot4,
	$PanelInventario/ContenedorSlots/Slot5,
	$PanelInventario/ContenedorSlots/Slot6,
	$PanelInventario/ContenedorSlots/Slot7,
	$PanelInventario/ContenedorSlots/Slot8
]

# Para animar solo los objetos que se agregan después de que la escena ya cargó
var _conteo_previo: Dictionary = {}
var _primera_actualizacion: bool = true
var _tween_seleccion: Tween
var _seleccion_previa: int = -1


func _ready() -> void:
	# Nos desconectamos si la señal ya estaba vinculada para evitar conexiones duplicadas
	if Global.inventario_actualizado.is_connected(actualizar_interfaz):
		Global.inventario_actualizado.disconnect(actualizar_interfaz)

	# Conectamos la señal de actualización global
	Global.inventario_actualizado.connect(actualizar_interfaz)

	# Conectamos la señal gui_input a cada slot para capturar el clic con el mouse
	for i in range(slots.size()):
		var slot = slots[i]
		if not slot.gui_input.is_connected(_on_slot_gui_input):
			slot.gui_input.connect(_on_slot_gui_input.bind(i))

	# Forzamos una actualización inicial al entrar a cualquier escena
	actualizar_interfaz()


# --- MANEJO DE CLICS EN LOS SLOTS DEL INVENTARIO ---
func _on_slot_gui_input(event: InputEvent, index: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:

		# 1. DOBLE CLIC (Solo se ejecuta en el Nivel 1 si existe el papel/nota y la vista)
		if event.double_click:
			if index < Global.inventario.size() and Global.inventario[index] != "":
				var item_actual = Global.inventario[index]
				if "papel" in item_actual or "nota" in item_actual:
					var vista = get_tree().current_scene.get_node_or_null("VistaPapel")
					if vista != null and vista.has_method("abrir_papel"):
						vista.abrir_papel()

		# 2. CLIC SIMPLE (Selección/Deselección con marco amarillo para Nivel 1 y Nivel 2)
		else:
			if Global.item_seleccionado_idx == index:
				Global.seleccionar_item(-1) # Deseleccionar si se toca el mismo slot
			else:
				Global.seleccionar_item(index) # Seleccionar el slot actual


# --- DIBUJADO DE TEXTURAS Y BORDES SELECCIONADOS ---
func actualizar_interfaz() -> void:
	for i in range(slots.size()):
		var slot_panel = slots[i]

		# Búsqueda defensiva del nodo icono dentro del slot
		var icono = slot_panel.get_node_or_null("Icono")
		if icono == null:
			icono = slot_panel.get_node_or_null("TextureRect")

		if icono == null:
			continue

		# Restablecemos la modulación normal del panel
		slot_panel.self_modulate = Color(1, 1, 1)

		# A) Aplicación del marco amarillo si está seleccionado
		if i == Global.item_seleccionado_idx and Global.item_seleccionado_idx != -1:
			var estilo_seleccionado = StyleBoxFlat.new()
			estilo_seleccionado.bg_color = Color("2A4272")
			estilo_seleccionado.set_border_width_all(3)
			estilo_seleccionado.set_corner_radius_all(7)
			estilo_seleccionado.border_color = SOL # Amarillo
			slot_panel.add_theme_stylebox_override("panel", estilo_seleccionado)
		else:
			slot_panel.remove_theme_stylebox_override("panel")

		# B) Carga y visualización de la imagen
		if i < Global.inventario.size() and Global.inventario[i] != "":
			var ruta_item = Global.inventario[i]
			if ResourceLoader.exists(ruta_item):
				icono.texture = load(ruta_item)
				icono.visible = true
			else:
				icono.texture = null
				icono.visible = false
		else:
			icono.texture = null
			icono.visible = false

	_animar_seleccion()
	_animar_objetos_nuevos()


# --- ANIMACIONES (solo presentación) ---

# La casilla elegida late suavemente mientras siga seleccionada
func _animar_seleccion() -> void:
	var elegida: int = Global.item_seleccionado_idx
	if elegida == _seleccion_previa:
		return
	_seleccion_previa = elegida
	if _tween_seleccion != null and _tween_seleccion.is_valid():
		_tween_seleccion.kill()
	for s in slots:
		s.scale = Vector2.ONE
	if elegida < 0 or elegida >= slots.size():
		return
	var slot: Control = slots[elegida]
	slot.pivot_offset = slot.size / 2.0
	_tween_seleccion = slot.create_tween().set_loops()
	_tween_seleccion.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tween_seleccion.tween_property(slot, "scale", Vector2(1.08, 1.08), 0.55)
	_tween_seleccion.tween_property(slot, "scale", Vector2.ONE, 0.55)


# Cuando aparece un objeto nuevo, su propio sprite viaja desde donde hizo clic el jugador hasta su casilla
func _animar_objetos_nuevos() -> void:
	var conteo: Dictionary = {}
	for ruta in Global.inventario:
		if ruta != "":
			conteo[ruta] = int(conteo.get(ruta, 0)) + 1
	if not _primera_actualizacion:
		for ruta in conteo:
			if conteo[ruta] > int(_conteo_previo.get(ruta, 0)):
				_volar_objeto(ruta)
	_conteo_previo = conteo
	_primera_actualizacion = false


func _volar_objeto(ruta: String) -> void:
	if not ResourceLoader.exists(ruta):
		return
	var indice: int = Global.inventario.rfind(ruta)
	if indice < 0 or indice >= slots.size():
		return
	var slot: Control = slots[indice]
	var icono: Control = slot.get_node_or_null("Icono")
	if icono == null:
		return
	icono.modulate.a = 0.0

	var vuelo := TextureRect.new()
	vuelo.texture = load(ruta)
	vuelo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	vuelo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	vuelo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vuelo.custom_minimum_size = Vector2(44, 44)
	vuelo.size = Vector2(44, 44)
	vuelo.pivot_offset = Vector2(22, 22)
	add_child(vuelo)

	var inicio: Vector2 = slot.get_global_mouse_position() - vuelo.size / 2.0
	var fin: Vector2 = slot.global_position + (slot.size - vuelo.size) / 2.0
	var control: Vector2 = (inicio + fin) / 2.0 + Vector2(0, -90)
	vuelo.position = inicio

	var t := vuelo.create_tween()
	t.tween_method(func(p: float) -> void:
		# Curva de Bézier para el arco y un pequeño "salto" de tamaño a mitad de camino
		var a: Vector2 = inicio.lerp(control, p)
		var b: Vector2 = control.lerp(fin, p)
		vuelo.position = a.lerp(b, p)
		vuelo.scale = Vector2.ONE * (lerpf(0.6, 1.0, p) + 0.3 * sin(p * PI)), 0.0, 1.0, 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_callback(func() -> void:
		vuelo.queue_free()
		icono.modulate.a = 1.0
		slot.pivot_offset = slot.size / 2.0
		var pop := slot.create_tween()
		pop.tween_property(slot, "scale", Vector2(1.35, 1.35), 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		pop.tween_property(slot, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT))
