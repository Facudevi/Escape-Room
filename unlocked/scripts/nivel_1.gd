extends Node2D
@onready var Nivel1 = $"."
@onready var menu_pausa = $CanvasLayer2/MenuPausa

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
