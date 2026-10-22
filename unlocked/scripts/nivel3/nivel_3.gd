extends Node2D

# Nivel 3 "El Patio": tres fondos con grupos de objetos independientes.
# Solo el grupo del fondo actual está visible, con colisiones y áreas activas.

const TEX_FONDOS: Array[Texture2D] = [
	preload("res://assets/imagen/patio/patio_techado1.jpeg"),
	preload("res://assets/imagen/patio/patio_techado2.jpeg"),
	preload("res://assets/imagen/patio/patio_techado3_cerrada.png"),
]
const TEX_FONDO_3_ABIERTO: Texture2D = preload("res://assets/imagen/patio/patio_techado3_editado.png")

const PAPEL_SUELO := preload("res://escenas/niveles/nivel3/PapelSuelo.tscn")
const ICONO_PAPEL_A := "res://assets/objetos/nivel3/papel_roto_a.png"
const ICONO_PAPEL_B := "res://assets/objetos/nivel3/papel_roto_b.png"
const ICONO_PAPEL_COMPLETO := "res://assets/objetos/nivel3/papel_completo.png"
const TEX_PAPEL_B: Texture2D = preload("res://assets/objetos/nivel3/papel_roto_b.png")

# Puntos de aparición de Castelli al llegar a cada fondo
const INICIO_FONDO_1 := Vector2(560, 570)
const DESDE_FONDO_2 := Vector2(1010, 570)
const DESDE_FONDO_3 := Vector2(576, 560)
const LLEGADA_FONDO_2 := Vector2(240, 610)
const LLEGADA_FONDO_3 := Vector2(660, 560)

# Escala del personaje por fondo: [y_lejos, escala_lejos, y_cerca, escala_cerca, velocidad_lejos]
const ESCALA_FONDOS: Array = [
	[470.0, 0.6, 640.0, 1.1, 0.75],
	[470.0, 0.6, 640.0, 1.1, 0.75],
	[470.0, 0.5, 640.0, 1.0, 0.75],
]

@onready var menu_pausa: Control = $Menu_Pausa/MenuPausa
@onready var fondo: TextureRect = $Mundo/Fondo
@onready var castelli: CharacterBody2D = $Mundo/Castelli
@onready var escala: Node = $Mundo/EscalaProfundidad
@onready var fundido: ColorRect = $Aviso/Fundido
@onready var mensaje: Label = $Aviso/Mensaje
@onready var vista_cartelera: CanvasLayer = $VistaCartelera
@onready var vista_metegol: CanvasLayer = $VistaMetegol
@onready var vista_candado: CanvasLayer = $VistaCandadoCasillero
@onready var vista_panel: CanvasLayer = $VistaPanel
@onready var lampara: Node2D = $Mundo/Lampara
@onready var vista_pista: CanvasLayer = $VistaPista

@onready var grupos: Array[Node2D] = [$Mundo/Fondo1, $Mundo/Fondo2, $Mundo/Fondo3]

var fondo_actual: int = 0
var cambiando: bool = false
var puerta_abierta: bool = false
var casillero_abierto: bool = false
var panel_resuelto: bool = false

# Progreso del jugador, usado para elegir la pista de la lámpara
var leyo_cartelera: bool = false
var leyo_metegol: bool = false
var intento_casillero: bool = false
var abrio_panel: bool = false
var tween_mensaje: Tween


func _ready() -> void:
	menu_pausa.visible = false
	mensaje.modulate.a = 0.0
	fundido.color.a = 0.0

	# Todos los grupos apagados; luego se enciende solo el fondo inicial
	for g in grupos:
		_activar_grupo(g, false)
	_mostrar_fondo(0)
	castelli.global_position = INICIO_FONDO_1

	$Mundo/Fondo1/FlechaDerecha.activada.connect(ir_a.bind(1, LLEGADA_FONDO_2))
	$Mundo/Fondo1/FlechaAbajo.activada.connect(ir_a.bind(2, LLEGADA_FONDO_3))
	$Mundo/Fondo2/FlechaIzquierda.activada.connect(ir_a.bind(0, DESDE_FONDO_2))
	$Mundo/Fondo3/FlechaVolver.activada.connect(ir_a.bind(0, DESDE_FONDO_3))

	$Mundo/Fondo1/PapelA.activado.connect(_on_papel_a_clic)
	_conectar_clic($Mundo/Fondo2/AreaMetegol, _on_metegol_clic)
	_conectar_clic($Mundo/Fondo2/AreaCasillero, _on_casillero_clic)
	_conectar_clic($Mundo/Fondo3/AreaCartelera, _on_cartelera_clic)
	vista_candado.candado_desbloqueado.connect(_on_candado_desbloqueado)
	_conectar_clic($Mundo/Fondo3/AreaPanel, _on_panel_clic)
	_conectar_clic($Mundo/Fondo3/AreaPuerta, _on_puerta_clic)
	vista_panel.secuencia_correcta.connect(_on_panel_resuelto)
	vista_panel.secuencia_incorrecta.connect(_on_secuencia_incorrecta)
	lampara.solicitar_pista.connect(_on_solicitar_pista)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		toggle_pause()


func toggle_pause() -> void:
	get_tree().paused = !get_tree().paused
	menu_pausa.visible = get_tree().paused


# --- Cambio de fondo ---

func ir_a(destino: int, aparicion: Vector2) -> void:
	if cambiando or destino == fondo_actual:
		return
	cambiando = true
	castelli.process_mode = Node.PROCESS_MODE_DISABLED
	await _animar_fundido(1.0)
	_mostrar_fondo(destino)
	castelli.velocity = Vector2.ZERO
	castelli.global_position = aparicion
	escala.aplicar()
	await _animar_fundido(0.0)
	castelli.process_mode = Node.PROCESS_MODE_INHERIT
	cambiando = false


func _animar_fundido(alfa: float) -> void:
	var t := create_tween()
	t.tween_property(fundido, "color:a", alfa, 0.2)
	await t.finished


func _mostrar_fondo(indice: int) -> void:
	_activar_grupo(grupos[fondo_actual], false)
	fondo_actual = indice
	fondo.texture = _textura_fondo(indice)
	var e: Array = ESCALA_FONDOS[indice]
	escala.configurar(e[0], e[1], e[2], e[3], e[4])
	_activar_grupo(grupos[indice], true)


func _textura_fondo(indice: int) -> Texture2D:
	if indice == 2 and puerta_abierta:
		return TEX_FONDO_3_ABIERTO
	return TEX_FONDOS[indice]


# La puerta de salida pasa a mostrarse abierta (estado permanente mientras dure el nivel)
func abrir_puerta() -> void:
	puerta_abierta = true
	if fondo_actual == 2:
		fondo.texture = TEX_FONDO_3_ABIERTO


# Oculta/muestra un grupo y activa/desactiva de verdad sus colisiones y áreas
func _activar_grupo(grupo: Node2D, activo: bool) -> void:
	grupo.visible = activo
	grupo.process_mode = Node.PROCESS_MODE_INHERIT if activo else Node.PROCESS_MODE_DISABLED
	_activar_fisica(grupo, activo)


func _activar_fisica(nodo: Node, activo: bool) -> void:
	for hijo in nodo.get_children():
		if hijo is CollisionShape2D or hijo is CollisionPolygon2D:
			hijo.set_deferred("disabled", not activo)
		elif hijo is Area2D:
			hijo.input_pickable = activo
			hijo.set_deferred("monitorable", activo)
			hijo.set_deferred("monitoring", activo)
		_activar_fisica(hijo, activo)


# --- Mensajes breves en pantalla ---

func mostrar_aviso(texto: String, duracion: float = 2.5) -> void:
	mensaje.text = texto
	if tween_mensaje != null:
		tween_mensaje.kill()
	mensaje.modulate.a = 1.0
	tween_mensaje = create_tween()
	tween_mensaje.tween_interval(duracion)
	tween_mensaje.tween_property(mensaje, "modulate:a", 0.0, 0.5)


# --- Objetos y pistas ---

# Conecta el clic izquierdo de un Area2D a una función sin argumentos
func _conectar_clic(area: Area2D, accion: Callable) -> void:
	area.input_event.connect(func(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			accion.call())


func _on_papel_a_clic() -> void:
	if Global.agregar_objeto(ICONO_PAPEL_A):
		$Mundo/Fondo1/PapelA.queue_free()
		mostrar_aviso("Debajo de la mesa había un trozo de papel roto.")
		_revisar_papeles()
	else:
		mostrar_aviso("El inventario está lleno.")


func _on_papel_b_clic(papel: Node) -> void:
	if Global.agregar_objeto(ICONO_PAPEL_B):
		papel.queue_free()
		mostrar_aviso("Recogiste la otra mitad del papel.")
		_revisar_papeles()
	else:
		mostrar_aviso("El inventario está lleno.")


func _on_metegol_clic() -> void:
	leyo_metegol = true
	vista_metegol.abrir()


func _on_cartelera_clic() -> void:
	leyo_cartelera = true
	vista_cartelera.abrir()


func _on_casillero_clic() -> void:
	intento_casillero = true
	if casillero_abierto:
		mostrar_aviso("El casillero ya está abierto y vacío.")
	else:
		vista_candado.abrir_vista()


func _on_candado_desbloqueado() -> void:
	casillero_abierto = true
	$Mundo/Fondo2/SpriteCandado.queue_free()
	mostrar_aviso("¡Clic! El casillero se abre y cae un papel al piso.")
	var papel: Area2D = PAPEL_SUELO.instantiate()
	papel.textura = TEX_PAPEL_B
	papel.position = Vector2(1010, 566)
	papel.angulo_grados = 20.0
	$Mundo/Fondo2.add_child(papel)
	papel.activado.connect(_on_papel_b_clic.bind(papel))


# Si tenés las dos mitades, se unen en un solo papel
func _revisar_papeles() -> void:
	var ia: int = _indice_en_inventario("papel_roto_a")
	var ib: int = _indice_en_inventario("papel_roto_b")
	if ia == -1 or ib == -1:
		return
	Global.seleccionar_item(-1)
	Global.inventario.remove_at(maxi(ia, ib))
	Global.inventario.remove_at(mini(ia, ib))
	Global.agregar_objeto(ICONO_PAPEL_COMPLETO)
	mostrar_aviso("¡Las dos mitades encajan! Hacé doble clic en el papel para leerlo.", 4.0)


func _indice_en_inventario(fragmento: String) -> int:
	for i in range(Global.inventario.size()):
		if fragmento in str(Global.inventario[i]):
			return i
	return -1


# --- Panel de botones y puerta de salida ---

func _on_panel_clic() -> void:
	abrio_panel = true
	if panel_resuelto:
		mostrar_aviso("El panel ya está desbloqueado.")
	else:
		vista_panel.abrir()


func _on_secuencia_incorrecta() -> void:
	mostrar_aviso("Secuencia incorrecta. El panel se reinicia.")


func _on_panel_resuelto() -> void:
	panel_resuelto = true
	abrir_puerta()
	mostrar_aviso("¡Click! La puerta de salida se abrió.", 3.0)


func _on_puerta_clic() -> void:
	if puerta_abierta:
		completar_nivel()
	else:
		mostrar_aviso("La puerta está trabada. El panel de al lado pide una secuencia de colores.", 3.5)


# Igual que en los niveles 1 y 2: se limpian los datos globales y se vuelve a la selección de niveles
func completar_nivel() -> void:
	if cambiando:
		return
	cambiando = true
	castelli.process_mode = Node.PROCESS_MODE_DISABLED
	mostrar_aviso("¡NIVEL 3 COMPLETADO!", 2.0)
	await _animar_fundido(1.0)
	await get_tree().create_timer(1.5).timeout
	Global.reiniciar_datos()
	get_tree().change_scene_to_file("res://escenas/settings/niveles.tscn")


# --- Pistas de la lámpara (según el progreso, de la última etapa a la primera) ---

func _on_solicitar_pista() -> void:
	vista_pista.mostrar_pista(_texto_pista())


func _texto_pista() -> String:
	if puerta_abierta:
		return "¡Lo lograste! La puerta de salida está abierta. Hacé clic en ella para escapar del patio."
	if _indice_en_inventario("papel_completo") != -1:
		if not abrio_panel:
			return "Con las dos mitades unidas el papel ya tiene sentido. Hacé doble clic sobre él para leerlo y buscá un panel de botones junto a la puerta de salida."
		return "Cada pregunta del papel nombra algo del patio: buscá cada cosa y fijate de qué color es. El panel espera los cuatro colores en ese orden."
	if casillero_abierto:
		return "Algo cayó del casillero. Mirá el piso, cerca de los casilleros azules."
	if intento_casillero:
		if not leyo_cartelera:
			return "El candado pide cuatro cifras. En algún tablero de avisos pueden estar las reglas para armar la clave."
		if not leyo_metegol:
			return "El aviso habla de goles del ROJO y del AZUL. ¿Dónde se llevan las cuentas de un partido de metegol?"
		return "Ya tenés todos los datos: goles del rojo, goles del azul, la mesa de la final y el día. Recordá que el lunes es el día 1."
	if _indice_en_inventario("papel_roto_a") != -1:
		return "Una mitad de papel no alcanza: falta la otra. Probá con los casilleros azules y recorré las otras zonas con las flechas del piso."
	return "Los objetos pequeños suelen esconder la clave. Revisá bien el piso del patio, sobre todo debajo de las mesas."
