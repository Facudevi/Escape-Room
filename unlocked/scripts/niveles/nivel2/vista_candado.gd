extends CanvasLayer

signal candado_desbloqueado_exitosamente

const CODIGO_CORRECTO: Array[int] = [1, 9, 8, 4]
var digitos_actuales: Array[int] = [0, 0, 0, 0]

# Nodos hijos dentro de TextureRect (según la captura)
@onready var labels_digitos: Array[Label] = [
	$TextureRect/Digito1,
	$TextureRect/Digito2,
	$TextureRect/Digito3,
	$TextureRect/Digito4
]

@onready var boton_cerrar: Button = $BotonCerrar


func _ready() -> void:
	visible = false
	
	if boton_cerrar != null:
		if not boton_cerrar.pressed.is_connected(_on_boton_cerrar_pressed):
			boton_cerrar.pressed.connect(_on_boton_cerrar_pressed)
			
	# Conectamos dinámicamente los botones Arriba y Abajo dentro de TextureRect
	for i in range(4):
		var btn_arriba = get_node_or_null("TextureRect/Arriba" + str(i + 1))
		var btn_abajo = get_node_or_null("TextureRect/Abajo" + str(i + 1))
		
		if btn_arriba != null and not btn_arriba.pressed.is_connected(_cambiar_digito):
			btn_arriba.pressed.connect(_cambiar_digito.bind(i, 1))
			
		if btn_abajo != null and not btn_abajo.pressed.is_connected(_cambiar_digito):
			btn_abajo.pressed.connect(_cambiar_digito.bind(i, -1))
			
	_actualizar_pantalla()


func abrir_vista() -> void:
	visible = true


func _cambiar_digito(posicion: int, cambio: int) -> void:
	digitos_actuales[posicion] = (digitos_actuales[posicion] + cambio) % 10
	if digitos_actuales[posicion] < 0:
		digitos_actuales[posicion] = 9
		
	_actualizar_pantalla()
	_verificar_codigo()


func _actualizar_pantalla() -> void:
	for i in range(4):
		if i < labels_digitos.size() and labels_digitos[i] != null:
			labels_digitos[i].text = str(digitos_actuales[i])


func _verificar_codigo() -> void:
	if digitos_actuales == CODIGO_CORRECTO:
		print("¡CÓDIGO CORRECTO INGRESADO EN EL CANDADO!")
		candado_desbloqueado_exitosamente.emit()
		visible = false # Se cierra la vista del candado y queda en la VistaCubiculo de atrás


func _on_boton_cerrar_pressed() -> void:
	visible = false
