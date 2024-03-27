@tool
extends Command

## The Background image or scene to use. Note setting the BG to the same one
## will reset it!
var background:
	set(value):
		background = value
		emit_changed()
	get:
		return background

## The camera point to set the current background to. If background is not set
## it will swap the camera pos for the current bg
var campoint:
	set(value):
		campoint = value
		emit_changed()
	get:
		return campoint

## The time it takes for the camera to pan to the desired position
var pan_duration: float = 0.0:
	set(value):
		pan_duration = value
		emit_changed()
	get:
		return pan_duration

func _execution_steps() -> void:
	command_started.emit()
	if not target_node.has_method(&"background"):
		push_error("[Background Command]: target_node '%s' doesn't have 'background' method." % target_node)
		return
	# Pass over ourselves to let the target node handle everything else
	target_node.background(self)
	go_to_next_command()


func _get_name() -> StringName:
	return "Background"


func _get_hint() -> String:
	var hint = ""
	if background != null:
		hint += "set to '" + background.resource_path.get_file() + "'"
	if hint != "":
		hint += "\n"
	hint += "pan to campoint '" + str(campoint) + "'"
	if pan_duration > 0:
		hint += " over " + str(pan_duration) + " seconds"
	return hint


func _get_icon() -> Texture:
	return load("res://addons/textalog/commands/icons/background.svg")


func _get_category() -> StringName:
	return &"Textalog"


func _get_property_list() -> Array:
	var p := []
	p.append({
		"name": "background",
		"type": TYPE_OBJECT,
		"usage": PROPERTY_USAGE_DEFAULT,
		"hint": PROPERTY_HINT_RESOURCE_TYPE,
		"hint_string": "PackedScene,Texture2D"
		})
	p.append({
		"name": "campoint",
		"type": TYPE_INT,
		"usage": PROPERTY_USAGE_DEFAULT
		})
	p.append({
		"name": "pan_duration",
		"type": TYPE_FLOAT,
		"usage": PROPERTY_USAGE_DEFAULT
		})
	return p

func _property_can_revert(property: StringName) -> bool:
	if property == "background":
		return true
	return false

func _property_get_revert(property: StringName):
	if property == "background":
		return null
	return null
