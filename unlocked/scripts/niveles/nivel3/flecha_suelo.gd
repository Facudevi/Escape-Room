extends Area2D

# Flecha pintada en el piso: se dibuja aplastada en Y para respetar la perspectiva
signal activada

@export var angulo_grados: float = 0.0
@export var tamano: float = 96.0
@export var escala_y: float = 0.5

@onready var pivote: Node2D = $Pivote
@onready var sprite: Sprite2D = $Pivote/Sprite2D
@onready var forma: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	pivote.scale = Vector2(1.0, escala_y)
	var lado: float = tamano / sprite.texture.get_width()
	sprite.scale = Vector2(lado, lado)
	sprite.rotation = deg_to_rad(angulo_grados)

	# Zona de clic: el rectángulo de la flecha rotada y aplastada, con un mínimo cómodo
	var c: float = absf(cos(sprite.rotation))
	var s: float = absf(sin(sprite.rotation))
	var ancho: float = c * tamano * 0.9 + s * tamano * 0.7
	var alto: float = (s * tamano * 0.9 + c * tamano * 0.7) * escala_y
	forma.shape = forma.shape.duplicate()  # evita que las instancias compartan el mismo tamaño
	(forma.shape as RectangleShape2D).size = Vector2(maxf(ancho, 40.0), maxf(alto, 40.0))
	input_event.connect(_on_input_event)


func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		activada.emit()
