extends Node2D

@onready var Nivel2 = $"."
@onready var menu_pausa = $Menu_Pausa/MenuPausa
@onready var fondo_nivel: TextureRect = $CanvasLayer/TextureRect
@onready var sprite_candado: Sprite2D = $CanvasLayer/SpriteCandado

# Rutas de ítems exportadas
@export var icono_trapo_seco: String = "res://assets/objetos/nivel2/trapo_seco.png"
@export var icono_trapo_humedo: String = "res://assets/objetos/nivel2/trapo_humedo.png"
@export var icono_llave: String = "res://assets/objetos/nivel2/llave.png"

# Vistas de Zoom
@export var vista_espejo: CanvasLayer
@export var vista_cubiculo: CanvasLayer
@export var vista_candado: CanvasLayer

# Carga de imágenes del fondo principal (Asegúrate de que las rutas sean las correctas)
var imagen_bano_espejo_limpio: Texture2D = preload("res://assets/imagen/baño/baño_espejo_limpio.png")
var imagen_bano_cubiculo_abierto: Texture2D = preload("res://assets/imagen/baño/baño_cubiculo_abierto.png")
var imagen_bano_final: Texture2D = preload("res://assets/imagen/baño/baño_final.png")

# Estados del nivel
var tacho_recolectado: bool = false
var espejo_limpio: bool = false
var cubiculo_abierto: bool = false
var puerta_salida_abierta: bool = false


func _ready() -> void:
	if menu_pausa != null:
		menu_pausa.visible = false
		
	# Conexión Espejo
	if vista_espejo != null:
		if not vista_espejo.espejo_limpiado_exitosamente.is_connected(_on_espejo_limpiado):
			vista_espejo.espejo_limpiado_exitosamente.connect(_on_espejo_limpiado)

	# Conexión Cubículo -> Candado
	if vista_cubiculo != null:
		if not vista_cubiculo.abrir_zoom_candado.is_connected(_on_abrir_zoom_candado):
			vista_cubiculo.abrir_zoom_candado.connect(_on_abrir_zoom_candado)

	# Conexión Desbloqueo Candado
	if vista_candado != null:
		if not vista_candado.candado_desbloqueado_exitosamente.is_connected(_on_candado_desbloqueado):
			vista_candado.candado_desbloqueado_exitosamente.connect(_on_candado_desbloqueado)


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		toggle_pause()


func toggle_pause():
	get_tree().paused = !get_tree().paused
	if menu_pausa != null:
		menu_pausa.visible = get_tree().paused


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if (vista_espejo != null and vista_espejo.visible) or \
		   (vista_cubiculo != null and vista_cubiculo.visible) or \
		   (vista_candado != null and vista_candado.visible):
			return
			
		await get_tree().process_frame
		if Global.item_seleccionado_idx != -1:
			Global.seleccionar_item(-1)


# --- INTERACCIONES DEL BAÑO ---

func _on_area_tacho_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not tacho_recolectado:
			var exito: bool = Global.agregar_objeto(icono_trapo_seco)
			if exito:
				tacho_recolectado = true
				print("¡Has juntado un trapo seco del tacho!")


func _on_area_canilla_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if Global.item_seleccionado_idx != -1:
			var item_actual = Global.inventario[Global.item_seleccionado_idx]
			if "trapo_seco" in item_actual:
				print("¡Has mojado el trapo en la canilla!")
				Global.eliminar_item_seleccionado()
				Global.agregar_objeto(icono_trapo_humedo)


func _on_area_espejo_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if vista_espejo != null:
			vista_espejo.abrir_vista_espejo(espejo_limpio)


func _on_espejo_limpiado() -> void:
	espejo_limpio = true
	if fondo_nivel != null and imagen_bano_espejo_limpio != null:
		fondo_nivel.texture = imagen_bano_espejo_limpio


# --- FLUJO CUBÍCULO Y CANDADO ---

func _on_area_cubiculo_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if vista_cubiculo != null:
			vista_cubiculo.abrir_vista(cubiculo_abierto)


func _on_abrir_zoom_candado() -> void:
	if not cubiculo_abierto and vista_candado != null:
		vista_candado.abrir_vista()


func _on_candado_desbloqueado() -> void:
	cubiculo_abierto = true
	
	# 1. Eliminamos por completo el sprite del candado independiente del mapa principal
	if sprite_candado != null:
		sprite_candado.visible = false
		sprite_candado.queue_free()
		
	# 2. Actualizamos la VistaCubiculo en zoom (se mantiene abierta con la llave)
	if vista_cubiculo != null:
		vista_cubiculo.desbloquear_cubiculo_zoom()
		
	# 3. Cambiamos la textura del fondo principal a la versión sin candado
	if fondo_nivel != null:
		if imagen_bano_cubiculo_abierto != null:
			fondo_nivel.texture = imagen_bano_cubiculo_abierto
		print("¡Cubículo abierto y candado desvinculado del fondo principal!")


# --- PASO FINAL: PUERTA DE SALIDA Y VICTORIA ---

func _on_area_salida_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if puerta_salida_abierta:
			completar_nivel_2()
		else:
			if Global.item_seleccionado_idx != -1:
				var item_actual = Global.inventario[Global.item_seleccionado_idx]
				if "llave" in item_actual:
					print("¡Puerta de salida abierta con la llave!")
					Global.eliminar_item_seleccionado()
					puerta_salida_abierta = true
					
					if fondo_nivel != null and imagen_bano_final != null:
						fondo_nivel.texture = imagen_bano_final
				else:
					print("Este objeto no abre la puerta de salida.")
			else:
				print("La puerta está cerrada. Necesitás la llave.")


func completar_nivel_2() -> void:
	print("¡NIVEL 2 COMPLETADO CON ÉXITO!")
	Global.reiniciar_datos()
	get_tree().change_scene_to_file("res://escenas/settings/niveles.tscn")
