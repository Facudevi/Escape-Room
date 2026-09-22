extends CanvasLayer

# Referencias a los TextureRect (Slots) que creaste
@onready var slots: Array = [
	$PanelInventario/ContenedorSlots/Slot1,
	$PanelInventario/ContenedorSlots/Slot2,
	$PanelInventario/ContenedorSlots/Slot3,
	$PanelInventario/ContenedorSlots/Slot4,
	$PanelInventario/ContenedorSlots/Slot5,
	$PanelInventario/ContenedorSlots/Slot6,
	$PanelInventario/ContenedorSlots/Slot7,
	$PanelInventario/ContenedorSlots/Slot8
]

func _ready() -> void:
	# Nos conectamos a la señal global
	Global.inventario_actualizado.connect(actualizar_interfaz)
	# Conectamos la señal gui_input de cada slot para detectar el clic
	for i in range(slots.size()):
		var slot = slots[i]
		slot.gui_input.connect(_on_slot_gui_input.bind(i))
	actualizar_interfaz()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_slot_gui_input(event: InputEvent, index: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# 1. Comprobamos si fue un DOBLE CLIC
		if event.double_click:
			if index < Global.inventario.size():
				var item_actual = Global.inventario[index]
				# Verificamos si el objeto en el slot es el papel/nota
				if "papel" in item_actual or "nota" in item_actual:
					var vista = get_tree().current_scene.get_node_or_null("VistaPapel")
					if vista != null:
						vista.abrir_papel()
		else:
			# 2. Si fue un CLIC SIMPLE, mantiene la lógica de selección que ya tenías
			if Global.item_seleccionado_idx == index:
				Global.seleccionar_item(-1)
			else:
				Global.seleccionar_item(index)
			actualizar_interfaz()

func actualizar_interfaz() -> void:
	for i in range(slots.size()):
		var slot_panel = slots[i]
		var icono = slot_panel.get_node("Icono")
		
		# Restablecemos la modulación a blanco
		slot_panel.self_modulate = Color(1, 1, 1)
		
		# 1. Borde amarillo de selección
		if i == Global.item_seleccionado_idx and Global.item_seleccionado_idx != -1:
			var estilo_seleccionado = StyleBoxFlat.new()
			estilo_seleccionado.bg_color = Color(0, 0, 0, 0.4) 
			estilo_seleccionado.border_width_left = 3
			estilo_seleccionado.border_width_top = 3
			estilo_seleccionado.border_width_right = 3
			estilo_seleccionado.border_width_bottom = 3
			estilo_seleccionado.border_color = Color(1, 1, 0, 1) 
			slot_panel.add_theme_stylebox_override("panel", estilo_seleccionado)
		else:
			slot_panel.remove_theme_stylebox_override("panel")
			
		# 2. Carga y visualización de la textura
		if i < Global.inventario.size() and Global.inventario[i] != "":
			var ruta_item = Global.inventario[i]
			if ResourceLoader.exists(ruta_item):
				icono.texture = load(ruta_item)
				icono.visible = true
			else:
				icono.texture = null
				icono.visible = false
		else:
			icono.texture = null
			icono.visible = false
