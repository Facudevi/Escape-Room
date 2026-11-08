extends Control
# Logo UNLOCKED: el candado se mece y se abre al pasar el mouse.

@onready var candado: Control = $Fila/Candado
@onready var arco: TextureRect = $Fila/Candado/Arco

var _tween_arco: Tween


func _ready() -> void:
	resized.connect(_centrar_pivote)
	candado.resized.connect(_ajustar_pivotes)
	_centrar_pivote()
	_ajustar_pivotes()
	candado.mouse_filter = Control.MOUSE_FILTER_STOP
	candado.mouse_entered.connect(_abrir.bind(true))
	candado.mouse_exited.connect(_abrir.bind(false))
	candado.gui_input.connect(_clic_candado)
	_mecer()


func _centrar_pivote() -> void:
	pivot_offset = size / 2.0
	rotation = deg_to_rad(-2.0)


# El candado cuelga de arriba; el arco gira desde su pata derecha al abrirse
func _ajustar_pivotes() -> void:
	candado.pivot_offset = Vector2(candado.size.x / 2.0, 0.0)
	arco.pivot_offset = Vector2(candado.size.x * 0.73, candado.size.y * 0.48)


func _mecer() -> void:
	var t := candado.create_tween().set_loops()
	t.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(candado, "rotation", deg_to_rad(4.0), 1.7).from(deg_to_rad(-4.0))
	t.tween_property(candado, "rotation", deg_to_rad(-4.0), 1.7)


func _abrir(abierto: bool) -> void:
	if _tween_arco != null and _tween_arco.is_valid():
		_tween_arco.kill()
	_tween_arco = arco.create_tween().set_parallel(true)
	_tween_arco.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween_arco.tween_property(arco, "position:y", -11.0 if abierto else 0.0, 0.3)
	_tween_arco.tween_property(arco, "rotation", deg_to_rad(24.0) if abierto else 0.0, 0.3)


func _clic_candado(evento: InputEvent) -> void:
	if evento is InputEventMouseButton and evento.pressed and evento.button_index == MOUSE_BUTTON_LEFT:
		_abrir(true)
		await get_tree().create_timer(0.5).timeout
		if not candado.get_global_rect().has_point(get_global_mouse_position()):
			_abrir(false)
