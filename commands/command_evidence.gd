@tool
extends Command

enum Action {
	ADD_EVIDENCE,
	ERASE_EVIDENCE,
	INSERT_AT_INDEX,
	REMOVE_AT_INDEX
}

## Add Evidence means we add the [member evidence]
## Remove Evidence means we remove the [member evidence] if found
@export var do_what:Action = Action.ADD_EVIDENCE:
	set(value):
		do_what = value
		emit_changed()
		notify_property_list_changed()
	get: return do_what


## The Evidence resource to reference
var evidence:Evidence:
	set(value):
		if value and value.changed.is_connected(emit_changed):
			value.changed.disconnect(emit_changed)
		evidence = value
		if evidence and not evidence.changed.is_connected(emit_changed):
			evidence.changed.connect(emit_changed)
		emit_changed()
	get:
		return evidence


## The index to modify.
var at_index:int = 0:
	set(value):
		at_index = value
		emit_changed()
	get:
		return at_index

func _execution_steps() -> void:
	command_started.emit()
	if not target_node.has_method(&"evidence"):
		push_error("[Evidence Command]: target_node '%s' doesn't have 'evidence' method." % target_node)
		return
	# Pass over ourselves to let the target node handle everything else
	target_node.evidence(self)
	go_to_next_command()


func _get_name() -> StringName:
	if not get_command_owner():
		return "Evidence"
	match do_what:
		Action.ADD_EVIDENCE:
			return "Add Evidence"
		Action.ERASE_EVIDENCE:
			return "Erase Evidence"
		Action.INSERT_AT_INDEX:
			return "Insert Evidence"
		Action.REMOVE_AT_INDEX:
			return "Remove Evidence"
	return "Evidence"


func _get_hint() -> String:
	if evidence == null:
		return ""
	match do_what:
		Action.REMOVE_AT_INDEX:
			return "Remove at Index " + str(at_index)
		Action.INSERT_AT_INDEX:
			return "'" + evidence.name + "' at index " + str(at_index) + "\n" + evidence.short_desc
	return "'" + evidence.name + "'\n" + evidence.short_desc


func _get_icon() -> Texture:
	if evidence == null or evidence.image == null:
		return load("res://addons/textalog/commands/icons/evidence.svg")
	return evidence.image


func _get_property_list() -> Array:
	var p := []
	if do_what == Action.ADD_EVIDENCE or do_what == Action.ERASE_EVIDENCE or do_what == Action.INSERT_AT_INDEX:
		p.append({
			"name": "evidence",
			"type": TYPE_OBJECT,
			"class_name": "Evidence",
			"usage": PROPERTY_USAGE_DEFAULT,
			"hint": PROPERTY_HINT_RESOURCE_TYPE,
			"hint_string": "Evidence"
			})
	if do_what == Action.REMOVE_AT_INDEX or do_what == Action.INSERT_AT_INDEX:
		p.append({
			"name":"at_index",
			"type":TYPE_INT,
			"usage":PROPERTY_USAGE_DEFAULT
			})
	return p


func _get_category() -> StringName:
	return &"Textalog"
