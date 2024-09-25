@tool
extends Resource
class_name Evidence

@export var image: Texture = null:
	set(value):
		image = value
		emit_changed()
	get:
		return image
@export var name: String = "Generic Object":
	set(value):
		name = value
		emit_changed()
	get:
		return name
@export_multiline var short_desc: String = "Short Description Here":
	set(value):
		short_desc = value
		emit_changed()
	get:
		return short_desc
@export_multiline var long_desc: String = "Long Description Here":
	set(value):
		long_desc = value
		emit_changed()
	get:
		return long_desc
