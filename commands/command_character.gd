@tool
extends Command

## The character scene to instantiate.
@export var character: PackedScene:
	set(value):
		character = value
		emit_changed()
	get:
		return character
## The emote to play on the EmoteSwitcher [AnimationPlayer] in the [param character] scene.
@export var emote: String = "":
	set(value):
		emote = value
		emit_changed()
	get:
		return emote
## If we want to [method Node.queue_free] the character instead.
@export var delete: bool = false:
	set(value):
		delete = value
		emit_changed()
	get:
		return delete
## How you'd like to position your character in the scene
@export_category("Positioning")
## If we want to add the position, instead of set it.
@export var add_position: bool = true:
	set(value):
		add_position = value
		emit_changed()
	get:
		return add_position
## Set to position, or add to position if [param add_position] is true.
## With adding position, use negative values to subtract the position.
@export var to_position: Vector2 = Vector2(0,0):
	set(value):
		to_position = value
		emit_changed()
	get:
		return to_position
## How does the character animate in the scene
@export_category("Animation")
## How long it takes for the character to travel [param to_position]
@export var zoom_duration: float = 0:
	set(value):
		zoom_duration = value
		emit_changed()
	get:
		return zoom_duration
## If we want to flip the character sprite horizontally or not
@export var flipped: bool = false:
	set(value):
		flipped = value
		emit_changed()
	get:
		return flipped
## How long it takes for the flip bounce animation to play
@export var flip_duration: float = 0.15:
	set(value):
		flip_duration = value
		emit_changed()
	get:
		return flip_duration
## If our character is going to be shaking or not (looped).
@export var shaking:bool = false:
	set(value):
		shaking = value
		emit_changed()
	get:
		return shaking
## Set the [member CanvasItem.z_index] of the character scene.
## Useful for showing a character in front of or behind other characters.
@export var set_z_index:int = 0:
	set(value):
		set_z_index = value
		emit_changed()
	get:
		return set_z_index
## Pause the timeline progression until all the animations have finished
## ([param emote] does not count yet)
@export var wait_until_finished:bool = true:
	set(value):
		wait_until_finished = value
		emit_changed()
	get:
		return wait_until_finished
## Whether to fade out or fade in the character
@export var fade_out:bool = false:
	set(value):
		fade_out = value
		emit_changed()
	get:
		return fade_out
## The time it takes for the character to fade out/in
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
	return character.get_state().get_node_name(0) if character else "Character"


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


func _get_category() -> StringName:
	return &"Textalog"
