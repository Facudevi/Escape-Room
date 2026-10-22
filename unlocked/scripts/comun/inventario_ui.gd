extends CanvasLayer

# Referencias a los 8 Slots del Panel
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
	# Nos desconectamos si la señal ya estaba vinculada para evitar conexiones duplicadas
	if Global.inventario_actualizado.is_connected(actualizar_interfaz):
		Global.inventario_actualizado.disconnect(actualizar_interfaz)
		
	# Conectamos la señal de actualización global
	Global.inventario_actualizado.connect(actualizar_interfaz)
	
	# Conectamos la señal gui_input a cada slot para capturar el clic con el mouse
	for i in range(slots.size()):
		var slot = slots[i]
		if not slot.gui_input.is_connected(_on_slot_gui_input):
			slot.gui_input.connect(_on_slot_gui_input.bind(i))
			
	# Forzamos una actualización inicial al entrar a cualquier escena
	actualizar_interfaz()


# --- MANEJO DE CLICS EN LOS SLOTS DEL INVENTARIO ---
func _on_slot_gui_input(event: InputEvent, index: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		
		# 1. DOBLE CLIC (Solo se ejecuta en el Nivel 1 si existe el papel/nota y la vista)
		if event.double_click:
			if index < Global.inventario.size() and Global.inventario[index] != "":
				var item_actual = Global.inventario[index]
				if "papel" in item_actual or "nota" in item_actual:
					var vista = get_tree().current_scene.get_node_or_null("VistaPapel")
					if vista != null and vista.has_method("abrir_papel"):
						vista.abrir_papel()
		
		# 2. CLIC SIMPLE (Selección/Deselección con marco amarillo para Nivel 1 y Nivel 2)
		else:
			if Global.item_seleccionado_idx == index:
				Global.seleccionar_item(-1) # Deseleccionar si se toca el mismo slot
			else:
				Global.seleccionar_item(index) # Seleccionar el slot actual


# --- DIBUJADO DE TEXTURAS Y BORDES SELECCIONADOS ---
func actualizar_interfaz() -> void:
	for i in range(slots.size()):
		var slot_panel = slots[i]
		
		# Búsqueda defensiva del nodo icono dentro del slot
		var icono = slot_panel.get_node_or_null("Icono")
		if icono == null:
			icono = slot_panel.get_node_or_null("TextureRect")
			
		if icono == null:
			continue
		
		# Restablecemos la modulación normal del panel
		slot_panel.self_modulate = Color(1, 1, 1)
		
		# A) Aplicación del marco amarillo si está seleccionado
		if i == Global.item_seleccionado_idx and Global.item_seleccionado_idx != -1:
			var estilo_seleccionado = StyleBoxFlat.new()
			estilo_seleccionado.bg_color = Color(0, 0, 0, 0.4) 
			estilo_seleccionado.border_width_left = 3
			estilo_seleccionado.border_width_top = 3
			estilo_seleccionado.border_width_right = 3
			estilo_seleccionado.border_width_bottom = 3
			estilo_seleccionado.border_color = Color(1, 1, 0, 1) # Amarillo
			slot_panel.add_theme_stylebox_override("panel", estilo_seleccionado)
		else:
			slot_panel.remove_theme_stylebox_override("panel")
			
		# B) Carga y visualización de la imagen
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
