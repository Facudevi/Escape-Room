extends Area2D

# Objeto apoyado en el piso: se dibuja aplastado en Y (perspectiva) y con sombra
signal activado

@export var textura: Texture2D
@export var tamano: float = 58.0
@export var angulo_grados: float = 0.0
@export var escala_y: float = 0.5

@onready var pivote: Node2D = $Pivote
@onready var sprite: Sprite2D = $Pivote/Sprite2D
@onready var sombra: Sprite2D = $Pivote/Sprite2D/Sombra
@onready var forma: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	sprite.texture = textura
	sombra.texture = textura
	var lado: float = tamano / textura.get_width()
	sprite.scale = Vector2(lado, lado)
	sprite.rotation = deg_to_rad(angulo_grados)
	sombra.position = Vector2(textura.get_width(), textura.get_height()) * Vector2(0.08, 0.14)
	pivote.scale = Vector2(1.0, escala_y)
	forma.shape = forma.shape.duplicate()
	(forma.shape as RectangleShape2D).size = Vector2(maxf(tamano, 44.0), maxf(tamano * escala_y, 36.0))
	input_event.connect(_on_input_event)


func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		activado.emit()
