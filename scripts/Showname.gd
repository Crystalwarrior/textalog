@tool
extends PanelContainer

@export var showname_label: RichTextLabel

@export var showname: String = "":
	get:
		if showname_label:
			showname = showname_label.text
			return showname_label.text
		return showname
	set(value):
		showname = value
		if showname_label:
			showname_label.text = value


func _ready():
	showname_label.finished.connect(_on_rich_text_label_finished)


func _on_rich_text_label_finished():
	await get_tree().process_frame
	reset_size()
