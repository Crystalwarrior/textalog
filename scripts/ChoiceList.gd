extends Control

@onready var container: Container = $VBoxContainer

signal choice_selected(index)

func get_choice_by_index(index):
	return container.get_child(index) if (index >= 0 && index < container.get_child_count()) else null

func get_choice_by_name(choice_name):
	for child in container.get_children():
		if child.name == choice_name:
			return child
	return null

func get_choice_by_title(title):
	for child in container.get_children():
		if child.text == title:
			return child
	return null

func add_choice(title, disabled = false):
	var button := Button.new()
	button.text = title
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	button.disabled = disabled
	button.set_visible(not disabled)
	button.pressed.connect(_on_option_pressed.bind(button))
	container.add_child(button)
	return button

func remove_choice(index):
	var button = get_choice_by_index(index)
	if not button:
		return false
	button.queue_free()
	return true

func clear_choices():
	for child in container.get_children():
		child.queue_free()

func disable_choice(index, tog = true):
	var button = get_choice_by_index(index)
	if not button:
		return false
	button.set_disabled(tog)

func _on_option_pressed(button):
	var index = button.get_index()
	choice_selected.emit(index)
