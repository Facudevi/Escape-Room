extends Node2D
@onready var Nivel1 = $"."
@onready var menu_pausa = $CanvasLayer2/MenuPausa
@export var vista_pizarra: CanvasLayer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	menu_pausa.visible = false


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_just_pressed("ui_cancel"):
		toggle_pause()


func toggle_pause():
	get_tree().paused = !get_tree().paused
	menu_pausa.visible = get_tree().paused
	
# Función conectada a la señal input_event de AreaPizarra
func _on_area_pizarra_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("¡Clic detectado en la pizarra!")
		if vista_pizarra != null:
			vista_pizarra.abrir_pizarra()
