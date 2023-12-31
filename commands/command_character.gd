@tool
extends Command

@export var character: PackedScene:
	set(value):
		character = value
		emit_changed()
	get:
		return character
@export var emote: String = "":
	set(value):
		emote = value
		emit_changed()
	get:
		return emote
@export var delete: bool = false:
	set(value):
		delete = value
		emit_changed()
	get:
		return delete
@export_category("Positioning")
@export var add_position: bool = true:
	set(value):
		add_position = value
		emit_changed()
	get:
		return add_position
@export var to_position: Vector2 = Vector2(0,0):
	set(value):
		to_position = value
		emit_changed()
	get:
		return to_position
@export_category("Animation")
@export var zoom_duration: float = 0:
	set(value):
		zoom_duration = value
		emit_changed()
	get:
		return zoom_duration
@export var flipped: bool = false:
	set(value):
		flipped = value
		emit_changed()
	get:
		return flipped
@export var flip_duration: float = 0.15:
	set(value):
		flip_duration = value
		emit_changed()
	get:
		return flip_duration
@export var shaking:bool = false:
	set(value):
		shaking = value
		emit_changed()
	get:
		return shaking
@export var set_z_index:int = 0:
	set(value):
		set_z_index = value
		emit_changed()
	get:
		return set_z_index
@export var wait_until_finished:bool = true:
	set(value):
		wait_until_finished = value
		emit_changed()
	get:
		return wait_until_finished
@export var fade_out:bool = false:
	set(value):
		fade_out = value
		emit_changed()
	get:
		return fade_out
@export var fade_duration: float = 0.0:
	set(value):
		fade_duration = value
		emit_changed()
	get:
		return fade_duration


func _execution_steps() -> void:
	command_started.emit()

	var target = target_node
	if character:
		target = get_character()
		if not target:
			target = target_node.add_character(character, to_position, flipped)

	if emote != "":
		target.set_emote(emote)
	if shaking:
		target.start_shaking()
	else:
		target.stop_shaking()
	if fade_out:
		target.fadeout(fade_duration)
	else:
		target.fadein(fade_duration)
	target.z_index = set_z_index
	target.flip_h(flipped, flip_duration)
	target.move_to(to_position, Vector2(1, 1), zoom_duration, add_position)
	if wait_until_finished and zoom_duration > 0:
		if target.is_connected("tween_finished", character_finished):
			target.tween_finished.disconnect(character_finished)
		target.tween_finished.connect(
			character_finished,
			CONNECT_ONE_SHOT
			)
	else:
		command_finished.emit()


func get_character():
	if not character:
		return null
	var charname = character.get_state().get_node_name(0)
	return target_node.get_character(charname)


func character_finished():
	var target = get_character()
	if delete and target:
		get_character().queue_free()
	command_finished.emit()


func _get_name() -> StringName:
	var state = character.get_state()
	return state.get_node_name(0) if character else "Character"


func _get_hint() -> String:
	var hint_str = ""
	if character:
		hint_str += "'" + character.resource_path.get_file() + "' "
		hint_str += ": "
	if emote:
		hint_str += "set emote to '" + emote + "' "
	if to_position != Vector2(0,0) || !add_position:
		if add_position:
			hint_str += "add "
		else:
			hint_str += "set "
		hint_str += "pos: " + str(to_position)
	if zoom_duration > 0:
		hint_str += " over " + String.num(zoom_duration, 4) + " seconds"
	if flipped:
		hint_str += ", flipped"
	if shaking:
		hint_str += ", shaking"
	if fade_duration != 0:
		hint_str += ", fading "
		if fade_out:
			hint_str += "out "
		else:
			hint_str += "in "
		hint_str += "over " + String.num(fade_duration, 4) + " seconds"
	if target != NodePath():
		hint_str += " on " + str(target)
	if wait_until_finished and zoom_duration > 0:
		hint_str += " and wait until finished"
	return hint_str


func _get_icon() -> Texture:
	if character:
		var _emote = emote
		if _emote == "":
			_emote = "idle"
		var path = character.resource_path.get_basename() + "/icons/" + _emote + ".png"
		if ResourceLoader.exists(path):
			return load(path)
	return load("res://addons/textalog/commands/icons/character.svg")

