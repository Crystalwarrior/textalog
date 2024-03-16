@tool
extends Command

## The [String] to show in the showname box of the dialog box
@export var showname:String = "":
	set(value):
		showname = value
		emit_changed()
	get:
		return showname
## The dialog to show in the dialog box. Opens the Dialog Editor.
@export_multiline var dialog:String:
	set(value):
		dialog = value
		emit_changed()
	get:
		return dialog
## Turn this on if you want to add the [param dialog] to the Dialog Box, instead of reset it.
@export var additive:bool = false:
	set(value):
		additive = value
		emit_changed()
	get:
		return additive

# Text Speed constants
const TEXT_SPEED: Array = [
	# 1 letter every 2 frames
	# NORMAL
	0.03,
	# 1 letter every 3 frames
	# SLOW
	0.05,
	# 1 letter every 5 frames
	# TYPEWRITER
	0.08,
	# 1 letter every 1 frame
	# FAST
	0.015,
	# 2 letters every 1 frame
	# RAPID
	0.008,
	# Instant
	0.0
]

enum TextSpeed {NORMAL, SLOW, TYPEWRITER, FAST, RAPID, INSTANT, CUSTOM} 

## The speed of the text crawl in the dialog box
@export var text_speed: TextSpeed:
	set(value):
		text_speed = value
		if text_speed != TextSpeed.CUSTOM:
			_letter_delay = TEXT_SPEED[value]
		emit_changed()
	get:
		return text_speed
var _letter_delay:float = 0.03
## The amount of time text pauses for on each letter
@export_range(0, 10.0) var letter_delay:float = 0.03:
	set(value):
		_letter_delay = value
		var found = TEXT_SPEED.find(value)
		if found != -1:
			text_speed = found
		else:
			text_speed = TextSpeed.CUSTOM
		emit_changed()
	get:
		return _letter_delay
## Pause the timeline until the dialog finishes showing.
@export var wait_until_finished:bool = true:
	set(value):
		wait_until_finished = value
		emit_changed()
	get:
		return wait_until_finished
## The character that should play their speaking animation as the dialog is processed
@export var speaking_character:String = "":
	set(value):
		speaking_character = value
		emit_changed()
	get:
		return speaking_character
## If we want to show a bounce animation on the [param speaking_character]
@export var bump_speaker:bool = false:
	set(value):
		bump_speaker = value
		emit_changed()
	get:
		return bump_speaker
## If we want to highlight the [param speaking_character]
@export var highlight_speaker:bool = false:
	set(value):
		highlight_speaker = value
		emit_changed()
	get:
		return highlight_speaker
## Whether to hide the dialog box after text finished processing,
## or immediately if [param wait_until_finished] is false
@export var hide_dialog:bool = false:
	set(value):
		hide_dialog = value
		emit_changed()
	get:
		return hide_dialog

func _execution_steps() -> void:
	command_started.emit()
	target_node.set_dialog_visible(true)
	target_node.dialog(showname, dialog, additive, letter_delay)
	if speaking_character:
		var speaker = target_node.get_character(speaking_character)
		if speaker:
			if bump_speaker:
				speaker.bump()
			for chara in target_node.get_characters():
				if not highlight_speaker or chara == speaker:
					chara.blackout(false, 0.25)
				else:
					chara.blackout(true, 0.25)
			speaker.start_talking()
			if target_node.is_connected("dialog_finished", speaker.stop_talking):
				target_node.dialog_finished.disconnect(speaker.stop_talking)
			target_node.dialog_finished.connect(speaker.stop_talking, CONNECT_ONE_SHOT)
	if wait_until_finished and letter_delay > 0:
		if target_node.is_connected("dialog_finished", dialog_finished):
			target_node.dialog_finished.disconnect(dialog_finished)
		target_node.dialog_finished.connect(
			dialog_finished,
			CONNECT_ONE_SHOT
			)
	else:
		dialog_finished()

func dialog_finished():
	if hide_dialog:
		target_node.set_dialog_visible(false)
	command_finished.emit()

func _get_name() -> StringName:
	var prefix = ""
	if bump_speaker:
		prefix = "^"
	return (prefix + showname) if showname else "Dialog"


func _get_hint() -> String:
	var regex = RegEx.new()
	regex.compile("\\[.*?\\]")
	var text_without_tags = regex.sub(dialog, "", true)
	return text_without_tags


func _get_icon() -> Texture:
	return load("res://addons/textalog/commands/icons/speech.svg")


# stop at end by default
func _property_can_revert(property: StringName) -> bool:
	if property == "continue_at_end":
		return true
	return false

func _property_get_revert(property: StringName):
	if property == "continue_at_end":
		return false
	return null

func _init() -> void:
	super()
	continue_at_end = false


func _get_category() -> StringName:
	return &"Textalog"

