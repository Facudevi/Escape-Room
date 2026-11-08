extends Node2D

# "Cómo jugar": patio de práctica con una guía paso a paso. Usa la escena 1 del nivel 3, con las
# mismas colisiones, la misma escala por perspectiva y las mismas animaciones de Castelli.
# No toca el avance de ningún nivel: al entrar y al salir se reinicia el inventario.

const ICONO_LLAVE := "res://assets/objetos/nivel2/llave.png"
const ICONO_NOTA := "res://assets/objetos/nivel1/papel_nota.png"
const ESCENA_OPCIONES := "res://escenas/menus/opciones.tscn"
const ESCENA_NIVELES := "res://escenas/menus/niveles.tscn"

# Mismo punto de aparición que el nivel 3 en este fondo
const INICIO := Vector2(560, 570)

const PASOS: Array[Dictionary] = [
	{"titulo": "Caminá", "texto": "Usá las teclas para llegar a la baldosa amarilla.", "teclas": ["W", "A", "S", "D"]},
	{"titulo": "Revisá", "texto": "Hacé clic en la mesa de ping-pong. Casi todo se puede revisar.", "teclas": []},
	{"titulo": "Recogé", "texto": "Hay una llave en el piso. Hacé clic para guardarla.", "teclas": []},
	{"titulo": "Usá", "texto": "Elegí la llave en tu inventario, abajo. Después hacé clic en el armario gris.", "teclas": []},
	{"titulo": "Leé", "texto": "Hacé doble clic en la nota de tu inventario.", "teclas": []},
	{"titulo": "Pedí ayuda", "texto": "Tocá la bombilla de arriba a la derecha.", "teclas": []},
	{"titulo": "Pausá", "texto": "Apretá la tecla ESC para pausar. Con ESC otra vez seguís.", "teclas": ["ESC"]},
]

# Dónde apunta la flecha guía en cada paso (null = oculta)
const PUNTA_FLECHA: Dictionary = {
	1: Vector2(150, 478),
	3: Vector2(183, 292),
}

@onready var mundo: CanvasLayer = $Mundo
@onready var castelli: CharacterBody2D = $Mundo/Castelli
@onready var baldosa: Area2D = $Mundo/Baldosa
@onready var area_mesa: Area2D = $Mundo/AreaMesa
@onready var area_armario: Area2D = $Mundo/AreaArmario
@onready var llave: Area2D = $Mundo/Llave
@onready var lampara: Node2D = $Mundo/Lampara
@onready var flecha: Node2D = $Mundo/FlechaGuia
@onready var vista_nota: CanvasLayer = $VistaPapel
@onready var vista_pista: CanvasLayer = $VistaPista
@onready var mensaje: Label = $Aviso/Mensaje
@onready var menu_pausa: Control = $Menu_Pausa/MenuPausa
@onready var titulo: Label = %GuiaTitulo
@onready var numero: Label = %GuiaNumero
@onready var texto: Label = %GuiaTexto
@onready var teclas: HBoxContainer = %Teclas
@onready var puntos: HBoxContainer = %Puntos
@onready var sello: Control = %Sello
@onready var tarjeta: Control = %Tarjeta
@onready var fin: CanvasLayer = $Fin

var paso: int = 0
var terminado: bool = false
var armario_abierto: bool = false
var tween_mensaje: Tween
var tween_sello: Tween
var tween_lampara: Tween
var _fichas: Dictionary = {}


func _ready() -> void:
	Global.reiniciar_datos()
	menu_pausa.visible = false
	mensaje.modulate.a = 0.0
	fin.visible = false
	castelli.global_position = INICIO
	sello.modulate.a = 0.0

	baldosa.body_entered.connect(_on_baldosa_entrada)
	_conectar_clic(area_mesa, _on_mesa_clic)
	_conectar_clic(area_armario, _on_armario_clic)
	llave.activado.connect(_on_llave_clic)
	lampara.solicitar_pista.connect(_on_solicitar_pista)

	# Cuando se cierra la nota, la pista o la pausa se completa el paso correspondiente
	vista_nota.visibility_changed.connect(_al_cambiar_nota, CONNECT_DEFERRED)
	vista_pista.visibility_changed.connect(_al_cambiar_pista, CONNECT_DEFERRED)
	for vista in [vista_nota, vista_pista]:
		vista.visibility_changed.connect(_actualizar_interactivos, CONNECT_DEFERRED)
	menu_pausa.visibility_changed.connect(_al_cambiar_pausa)

	%BotonSaltar.pressed.connect(_saltar)
	%BotonVolver.pressed.connect(_salir.bind(ESCENA_OPCIONES))
	%BotonRepetir.pressed.connect(_repetir)
	%BotonJugar.pressed.connect(_salir.bind(ESCENA_NIVELES))

	_mostrar_paso(false)
	_actualizar_interactivos()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not terminado:
		_encender_ficha("ESC")
		toggle_pause()


func toggle_pause() -> void:
	get_tree().paused = !get_tree().paused
	menu_pausa.visible = get_tree().paused


func _process(_delta: float) -> void:
	# Las teclas de la guía se hunden mientras se las aprieta
	if _fichas.has("W"):
		_marcar_ficha("W", Input.is_action_pressed("ui_up"))
		_marcar_ficha("A", Input.is_action_pressed("ui_left"))
		_marcar_ficha("S", Input.is_action_pressed("ui_down"))
		_marcar_ficha("D", Input.is_action_pressed("ui_right"))


# ---------------------------------------------------------------------------
# GUÍA
# ---------------------------------------------------------------------------

func _mostrar_paso(animar: bool) -> void:
	var p: Dictionary = PASOS[paso]
	titulo.text = p["titulo"]
	texto.text = p["texto"]
	numero.text = "%d/%d" % [paso + 1, PASOS.size()]
	_armar_fichas(p["teclas"])
	_pintar_puntos()
	if animar:
		for c in [titulo, texto]:
			c.modulate.a = 0.0
			var t := create_tween()
			t.tween_property(c, "modulate:a", 1.0, 0.3)

	baldosa.visible = (paso == 0)
	baldosa.set_deferred("monitoring", paso == 0)
	llave.visible = (paso == 2)
	if PUNTA_FLECHA.has(paso):
		flecha.call("apuntar", PUNTA_FLECHA[paso])
	elif paso == 2:
		flecha.call("apuntar", llave.global_position + Vector2(0, -34))
	else:
		flecha.call("ocultar")
	_resplandor_lampara(paso == 5)
	_actualizar_interactivos()


func _pintar_puntos() -> void:
	for i in range(puntos.get_child_count()):
		var punto: Control = puntos.get_child(i)
		if terminado or i < paso:
			punto.theme_type_variation = &"PuntoOk"
		elif i == paso:
			punto.theme_type_variation = &"PuntoAhora"
		else:
			punto.theme_type_variation = &"Punto"


func _armar_fichas(lista: Array) -> void:
	for hijo in teclas.get_children():
		hijo.queue_free()
	_fichas.clear()
	for nombre in lista:
		var ficha := PanelContainer.new()
		ficha.theme_type_variation = &"PanelTecla"
		ficha.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var etiqueta := Label.new()
		etiqueta.theme_type_variation = &"TeclaTexto"
		etiqueta.text = nombre
		etiqueta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		etiqueta.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ficha.add_child(etiqueta)
		teclas.add_child(ficha)
		_fichas[nombre] = ficha


func _marcar_ficha(nombre: String, encendida: bool) -> void:
	var ficha: Control = _fichas.get(nombre)
	if ficha != null:
		ficha.theme_type_variation = &"PanelTeclaOn" if encendida else &"PanelTecla"


func _encender_ficha(nombre: String) -> void:
	_marcar_ficha(nombre, true)
	await get_tree().create_timer(0.25, true, false, true).timeout
	_marcar_ficha(nombre, false)


func _completar() -> void:
	_estampar_sello()
	paso += 1
	if paso >= PASOS.size():
		paso = PASOS.size() - 1
		_terminar()
		return
	_mostrar_paso(true)


func _estampar_sello() -> void:
	if tween_sello != null:
		tween_sello.kill()
	sello.pivot_offset = sello.size / 2.0
	sello.modulate.a = 1.0
	sello.scale = Vector2(2.2, 2.2)
	tween_sello = create_tween()
	tween_sello.tween_property(sello, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween_sello.tween_interval(0.6)
	tween_sello.tween_property(sello, "modulate:a", 0.0, 0.3)


func _terminar() -> void:
	terminado = true
	_pintar_puntos()
	flecha.call("ocultar")
	_resplandor_lampara(false)
	castelli.process_mode = Node.PROCESS_MODE_DISABLED
	tarjeta.visible = false
	fin.visible = true
	var estrellas: Array = %Estrellas.get_children()
	for i in range(estrellas.size()):
		var e: Control = estrellas[i]
		e.pivot_offset = e.size / 2.0
		e.scale = Vector2.ZERO
		var t := create_tween()
		t.tween_interval(0.25 + 0.14 * i)
		t.tween_property(e, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


# "Saltar paso" deja todo como si el paso se hubiera hecho
func _saltar() -> void:
	if terminado:
		return
	match paso:
		2:
			llave.visible = false
			if not Global.inventario.has(ICONO_LLAVE):
				Global.agregar_objeto(ICONO_LLAVE)
		3:
			var i: int = Global.inventario.find(ICONO_LLAVE)
			if i >= 0:
				Global.seleccionar_item(-1)
				Global.inventario.remove_at(i)
				Global.inventario_actualizado.emit()
			armario_abierto = true
			if not Global.inventario.has(ICONO_NOTA):
				Global.agregar_objeto(ICONO_NOTA)
	_completar()


func _repetir() -> void:
	Global.reiniciar_datos()
	get_tree().paused = false
	get_tree().reload_current_scene()


func _salir(escena: String) -> void:
	Global.reiniciar_datos()
	get_tree().paused = false
	FX.cambiar_escena(escena)


func _resplandor_lampara(activo: bool) -> void:
	if tween_lampara != null:
		tween_lampara.kill()
	var sprite: Sprite2D = lampara.get_node("Sprite2D")
	if not activo:
		sprite.modulate = Color.WHITE
		return
	tween_lampara = create_tween().set_loops()
	tween_lampara.tween_property(sprite, "modulate", Color(1.0, 0.85, 0.3), 0.5)
	tween_lampara.tween_property(sprite, "modulate", Color.WHITE, 0.5)


# ---------------------------------------------------------------------------
# INTERACCIONES (mismo esquema que los niveles)
# ---------------------------------------------------------------------------

func _bloqueado() -> bool:
	return terminado or get_tree().paused or _hay_vista_abierta()


func _hay_vista_abierta() -> bool:
	return vista_nota.visible or vista_pista.visible


# Con una vista abierta no se mueve Castelli ni se pueden pulsar los objetos ni la lámpara
func _actualizar_interactivos() -> void:
	var hay: bool = _hay_vista_abierta()
	for area in [area_mesa, area_armario]:
		area.input_pickable = not hay
	llave.input_pickable = (paso == 2) and not hay
	lampara.get_node("botonLampara").disabled = hay
	if not terminado:
		castelli.process_mode = Node.PROCESS_MODE_DISABLED if hay else Node.PROCESS_MODE_INHERIT


func _conectar_clic(area: Area2D, accion: Callable) -> void:
	area.input_event.connect(func(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			accion.call())


func _on_baldosa_entrada(cuerpo: Node) -> void:
	if cuerpo == castelli and paso == 0 and not terminado:
		_completar()


func _on_mesa_clic() -> void:
	if _bloqueado():
		return
	mostrar_aviso("Una mesa de ping-pong. Nada útil, pero revisar no cuesta nada.", 3.0)
	if paso == 1:
		_completar()


func _on_llave_clic() -> void:
	if _bloqueado() or paso != 2:
		return
	llave.visible = false
	llave.input_pickable = false
	Global.agregar_objeto(ICONO_LLAVE)
	mostrar_aviso("Guardaste una llave. Aparece en tu inventario.", 3.0)
	_completar()


func _on_armario_clic() -> void:
	if _bloqueado():
		return
	if armario_abierto:
		mostrar_aviso("El armario ya está abierto y vacío.")
		return
	var item: String = _item_seleccionado()
	if item == "":
		mostrar_aviso("Está cerrado con llave. Probá usar algo de tu inventario.", 3.0)
	elif "llave" in item:
		_consumir_item_seleccionado()
		armario_abierto = true
		mostrar_aviso("¡Clic! El armario se abre y encontrás una nota.", 3.0)
		_completar_si(3)
		await get_tree().create_timer(0.35).timeout
		Global.agregar_objeto(ICONO_NOTA)
	else:
		mostrar_aviso("Eso no sirve acá.")


func _completar_si(n: int) -> void:
	if paso == n and not terminado:
		_completar()


func _al_cambiar_nota() -> void:
	if not vista_nota.visible:
		_completar_si(4)


func _on_solicitar_pista() -> void:
	if _bloqueado():
		return
	vista_pista.mostrar_pista("Si te trabás, tocá la bombilla. La pista cambia según lo que ya hiciste.")


func _al_cambiar_pista() -> void:
	if not vista_pista.visible:
		_completar_si(5)


func _al_cambiar_pausa() -> void:
	if not menu_pausa.visible:
		_completar_si(6)


# Ruta del ítem seleccionado en el inventario ("" si no hay ninguno)
func _item_seleccionado() -> String:
	var idx: int = Global.item_seleccionado_idx
	if idx < 0 or idx >= Global.inventario.size():
		return ""
	return str(Global.inventario[idx])


func _consumir_item_seleccionado() -> void:
	var idx: int = Global.item_seleccionado_idx
	if idx < 0 or idx >= Global.inventario.size():
		return
	Global.seleccionar_item(-1)
	Global.inventario.remove_at(idx)
	Global.inventario_actualizado.emit()


func mostrar_aviso(texto_aviso: String, duracion: float = 2.5) -> void:
	mensaje.text = texto_aviso
	if tween_mensaje != null:
		tween_mensaje.kill()
	mensaje.modulate.a = 1.0
	tween_mensaje = create_tween()
	tween_mensaje.tween_interval(duracion)
	tween_mensaje.tween_property(mensaje, "modulate:a", 0.0, 0.5)
