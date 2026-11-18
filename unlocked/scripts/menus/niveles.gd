extends Control

const COLOR_BLOQUEADO := Color("3A445E")
# Arco primero para que quede detrás del cuerpo del candado
const ICONOS_CANDADO: Array[String] = ["res://assets/ui/candado_arco.svg", "res://assets/ui/candado_cuerpo.svg"]

@onready var botones: Array = [$Volver, $Nivel1, $Nivel2, $Nivel3, $Nivel4]


func _ready() -> void:
	# Aseguramos que el juego no esté pausado al entrar a la selección de niveles
	get_tree().paused = false
	_aplicar_bloqueos()
	FX.entrada_escalonada(botones)


# Solo están habilitados los niveles que el jugador ya liberó; el resto se ve bloqueado.
# El nivel 4 todavía no existe: queda siempre bloqueado ("PRÓXIMAMENTE...")
func _aplicar_bloqueos() -> void:
	for n in range(1, 5):
		var boton: Button = get_node("Nivel%d" % n)
		var bloqueado: bool = n == 4 or not Global.esta_desbloqueado(n)
		boton.disabled = bloqueado
		if bloqueado:
			_mostrar_bloqueado(boton)


# Botón bloqueado: fondo gris oscuro (el texto crema se lee bien) y candado en lugar de la llave.
# El texto conserva todo su brillo: lo que indica el bloqueo es el candado y el fondo
func _mostrar_bloqueado(boton: Button) -> void:
	var estilo: StyleBoxFlat = boton.get_theme_stylebox("disabled").duplicate()
	estilo.bg_color = COLOR_BLOQUEADO
	boton.add_theme_stylebox_override("disabled", estilo)

	var icono: Control = boton.get_node_or_null("Contenido/Icono")
	if icono == null:
		return
	icono.modulate = Color(0.85, 0.85, 0.85)
	var llave: Control = icono.get_node_or_null("Llave")
	if llave != null:
		llave.visible = false
	for ruta in ICONOS_CANDADO:
		var parte := TextureRect.new()
		parte.texture = load(ruta)
		parte.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		parte.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		parte.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icono.add_child(parte)
		parte.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 7)


func _on_nivel_1_pressed() -> void:
	FX.cambiar_escena("res://escenas/niveles/nivel1/nivel1.tscn")


func _on_nivel_2_pressed() -> void:
	FX.cambiar_escena("res://escenas/niveles/nivel2/nivel2.tscn")


func _on_nivel_3_pressed() -> void:
	FX.cambiar_escena("res://escenas/niveles/nivel3/nivel3.tscn")


func _on_nivel_4_pressed() -> void:
	pass # Replace with function body.


func _on_volver_pressed() -> void:
	FX.cambiar_escena("res://escenas/menus/menu.tscn")
