extends CanvasLayer

# Declaramos la señal de clave correcta
signal codigo_correcto_ingresado

# Cambia este código de 3 dígitos por el que quieras usar en tu juego
@export var codigo_correcto: String = "198"

@onready var pantalla: Label = $Label

var codigo_ingresado: String = ""
var bloqueado: bool = false # Evita escribir mientras se muestra CORRECTO / INCORRECTO

func _ready() -> void:
	hide()
	limpiar_pantalla()

func abrir_teclado() -> void:
	limpiar_pantalla()
	show()

func _on_boton_cerrar_pressed() -> void:
	hide()

# --- LÓGICA DE TECLAS NUMÉRICAS ---

func presionar_numero(digito: String) -> void:
	if bloqueado:
		return
		
	# Regla: Máximo 3 dígitos
	if codigo_ingresado.length() < 3:
		codigo_ingresado += digito
		pantalla.text = codigo_ingresado


# --- LÓGICA DE BOTÓN ROJO Y VERDE ---


func _on_boton_rojo_pressed() -> void:
	if bloqueado:
		return
	limpiar_pantalla()

func _on_boton_verde_pressed() -> void:
	if bloqueado:
		return
		
	if codigo_ingresado == codigo_correcto:
		pantalla.text = "CORRECTO"
		bloqueado = true
		# Emitimos la señal
		codigo_correcto_ingresado.emit()
	else:
		pantalla.text = "INCORRECTO"
		bloqueado = true
		await get_tree().create_timer(1.0).timeout
		limpiar_pantalla()

func limpiar_pantalla() -> void:
	codigo_ingresado = ""
	pantalla.text = ""
	bloqueado = false

func _on_boton_0_pressed() -> void:
	presionar_numero("0")

func _on_boton_1_pressed() -> void:
	presionar_numero("1")

func _on_boton_2_pressed() -> void:
	presionar_numero("2")

func _on_boton_3_pressed() -> void:
	presionar_numero("3")

func _on_boton_4_pressed() -> void:
	presionar_numero("4")

func _on_boton_5_pressed() -> void:
	presionar_numero("5")

func _on_boton_6_pressed() -> void:
	presionar_numero("6")

func _on_boton_7_pressed() -> void:
	presionar_numero("7")

func _on_boton_8_pressed() -> void:
	presionar_numero("8")

func _on_boton_9_pressed() -> void:
	presionar_numero("9")
