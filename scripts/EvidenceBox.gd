extends Control

@onready var title = $MarginContainer/HBoxContainer/VBoxContainer/Label
@onready var desc = $MarginContainer/HBoxContainer/VBoxContainer/MarginContainer/RichTextLabel
@onready var icon = $MarginContainer/HBoxContainer/Icon


func set_evidence(evidence: Evidence):
	title.text = evidence.name
	desc.text = evidence.long_desc
	icon.texture = evidence.image
