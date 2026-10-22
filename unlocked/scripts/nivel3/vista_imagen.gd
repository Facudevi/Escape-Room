extends CanvasLayer

# Vista ampliada genérica: muestra una imagen centrada con un botón para cerrarla.
# Con es_papel = true elige la imagen según los papeles del inventario (doble clic en el slot).

const PAPEL_COMPLETO := "res://assets/objetos/nivel3/papel_completo.png"
const PAPEL_A := "res://assets/objetos/nivel3/papel_roto_a.png"
const PAPEL_B := "res://assets/objetos/nivel3/papel_roto_b.png"
const AREA_MAXIMA := Vector2(1000, 560)

@export var textura: Texture2D
@export var es_papel: bool = false

@onready var imagen: TextureRect = $Imagen
@onready var boton_cerrar: Button = $BotonCerrar


func _ready() -> void:
	hide()
	boton_cerrar.pressed.connect(hide)


func abrir() -> void:
	_mostrar(textura)


# Lo llama inventario_ui.gd con el doble clic sobre un ítem de papel
func abrir_papel() -> void:
	var ruta := ""
	for item in Global.inventario:
		if PAPEL_COMPLETO.get_file() in str(item):
			ruta = PAPEL_COMPLETO
			break
		if PAPEL_A.get_file() in str(item):
			ruta = PAPEL_A
		elif PAPEL_B.get_file() in str(item) and ruta == "":
			ruta = PAPEL_B
	if ruta != "":
		_mostrar(load(ruta))


func _mostrar(tex: Texture2D) -> void:
	if tex == null:
		return
	imagen.texture = tex
	var factor: float = minf(AREA_MAXIMA.x / tex.get_width(), AREA_MAXIMA.y / tex.get_height())
	var tam: Vector2 = Vector2(tex.get_size()) * factor
	imagen.size = tam
	imagen.position = (get_viewport().get_visible_rect().size - tam) / 2.0
	show()
