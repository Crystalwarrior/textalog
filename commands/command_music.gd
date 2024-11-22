@tool
extends Command

enum Action {
	PLAY_MUSIC,
	STOP_MUSIC,
	SET_VOLUME,
	RESUME_MUSIC
}

## Play Music: play the provided [member music] track
## Stop Music: stop currently playing music
## Set Volume: change the volume of the currently playing music
## Resume Music: unpause last played music track
@export var do_what:Action = Action.PLAY_MUSIC:
	set(value):
		do_what = value
		emit_changed()
		notify_property_list_changed()
	get: return do_what

## The time it takes to fade in/out the track
@export var fade_duration: float = 0.0:
	set(value):
		fade_duration = value
		emit_changed()
	get:
		return fade_duration

#@export_range(-80.0, 24)
## The volume to target
var fade_volume: float = 0.0:
	set(value):
		fade_volume = value
		emit_changed()
	get:
		return fade_volume

## The [AudioStream] to play (stops music if not set)
var music:AudioStream:
	set(value):
		music = value
		emit_changed()
	get:
		return music

func _execution_steps() -> void:
	command_started.emit()
	if not target_node.has_method(&"music"):
		push_error("[Music Command]: target_node '%s' doesn't have 'music' method." % target_node)
		return
	# Pass over ourselves to let the target node handle everything else
	target_node.music(self)
	go_to_next_command()


func _get_name() -> StringName:
	return "Music"


func _get_hint() -> String:
	var hint = ""
	match do_what:
		Action.PLAY_MUSIC:
			hint += "play '" + music.resource_path.get_file() + "'"
		Action.STOP_MUSIC:
			hint += "stop"
		Action.SET_VOLUME:
			hint += "set volume"
		Action.RESUME_MUSIC:
			hint += "resume"
	if fade_duration > 0:
		hint += " and fade over " + String.num(fade_duration, 4) + "s"
	if do_what != Action.STOP_MUSIC:
		if fade_volume != 0.0:
			hint += " " + String.num(fade_volume, 4) + "db volume"
		else:
			hint += " full volume"
	return hint


func _get_icon() -> Texture:
	return load("res://addons/textalog/commands/icons/music-note.svg")


func _get_category() -> StringName:
	return &"Textalog"

func _get_property_list() -> Array:
	var p := []
	if do_what == Action.PLAY_MUSIC:
		p.append({
			"name": "music",
			"type": TYPE_OBJECT,
			"class_name": "AudioStream",
			"usage": PROPERTY_USAGE_DEFAULT,
			"hint": PROPERTY_HINT_RESOURCE_TYPE,
			"hint_string": "AudioStream"
			})
	if do_what != Action.STOP_MUSIC:
		p.append({
			"name": "fade_volume",
			"type": TYPE_FLOAT,
			"usage": PROPERTY_USAGE_DEFAULT,
			"hint": PROPERTY_HINT_RANGE,
			"hint_string": "-80.0,24.0"
			})
	return p

func _property_can_revert(property: StringName) -> bool:
	if property == "music":
		return true
	if property == "fade_volume":
		return true
	return false

func _property_get_revert(property: StringName):
	if property == "music":
		return null
	if property == "fade_volume":
		return 0.0
	return null
