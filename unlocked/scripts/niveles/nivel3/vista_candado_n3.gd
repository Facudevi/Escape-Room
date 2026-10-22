extends CanvasLayer

# Candado del casillero: misma escena de zoom que el nivel 2, con su propio código (4 cifras)
signal candado_desbloqueado

const CODIGO_CORRECTO: Array[int] = [7, 3, 2, 5]
var digitos_actuales: Array[int] = [0, 0, 0, 0]

@onready var labels_digitos: Array[Label] = [
	$TextureRect/Digito1,
	$TextureRect/Digito2,
	$TextureRect/Digito3,
	$TextureRect/Digito4
]
@onready var boton_cerrar: Button = $BotonCerrar


func _ready() -> void:
	visible = false
	boton_cerrar.pressed.connect(func(): visible = false)
	for i in range(4):
		var btn_arriba: Button = get_node("TextureRect/Arriba" + str(i + 1))
		var btn_abajo: Button = get_node("TextureRect/Abajo" + str(i + 1))
		btn_arriba.pressed.connect(_cambiar_digito.bind(i, 1))
		btn_abajo.pressed.connect(_cambiar_digito.bind(i, -1))
	_actualizar_pantalla()


func abrir_vista() -> void:
	visible = true


func _cambiar_digito(posicion: int, cambio: int) -> void:
	digitos_actuales[posicion] = posmod(digitos_actuales[posicion] + cambio, 10)
	_actualizar_pantalla()
	if digitos_actuales == CODIGO_CORRECTO:
		visible = false
		candado_desbloqueado.emit()


func _actualizar_pantalla() -> void:
	for i in range(4):
		labels_digitos[i].text = str(digitos_actuales[i])
