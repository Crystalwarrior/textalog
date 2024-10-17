extends Control

@onready var title = %Label
@onready var desc = %RichTextLabel
@onready var icon = %Icon

signal show_pressed

func set_data(evidence: Evidence):
	title.text = evidence.name
	desc.text = evidence.short_desc
	icon.texture = evidence.image


func _on_show_button_pressed():
	show_pressed.emit()
