extends Node2D

@export var object_list:Node

signal object_clicked(obj, timeline: CommandCollection)

var current_hovered = -1

func _ready():
	for child in object_list.get_children():
		child.clicked.connect(on_object_clicked)
		child.hovered.connect(on_object_hovered)
	var camera = get_node_or_null("Camera2D")
	if camera:
		camera.make_current()


func _unhandled_input(event):
	if event.is_action_pressed("highlight"):
		for child in object_list.get_children():
			child.outline(true)
	elif event.is_action_released("highlight"):
		for child in object_list.get_children():
			if child.get_index() == current_hovered:
				continue
			child.outline(false)


func on_object_hovered(obj, toggle):
	var is_highlighting = Input.is_action_pressed("highlight")
	var index = obj.get_index()
	if index < current_hovered:
		if not is_highlighting:
			obj.outline(false)
		return
	if toggle:
		current_hovered = obj.get_index()
		if not is_highlighting:
			obj.outline(true)
	else:
		current_hovered = -1
		if not is_highlighting:
			obj.outline(false)


func on_object_clicked(obj, target_timeline: CommandCollection):
	if current_hovered >= 0 and obj.get_index() != current_hovered:
		return
	obj.activate()
	object_clicked.emit(obj, target_timeline)
	get_window().gui_release_focus()
	get_viewport().set_input_as_handled()
