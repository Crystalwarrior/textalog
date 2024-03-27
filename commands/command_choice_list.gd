@tool
extends Command

var choice_picked
var choices: PackedStringArray = []

const ChoiceClass = preload("res://addons/textalog/commands/command_choice.gd")
var generate_default_choices:bool = true

func _execution_steps() -> void:
	command_started.emit()
	if not target_node.has_method(&"choice_list"):
		push_error("[Choice List Command]: target_node '%s' doesn't have 'choice_list' method." % target_node)
		return
	choices.clear()
	for command in collection:
		choices.append(command.text)
	target_node.choice_list(self)

func choice_selected(index):
	choice_picked = index
	go_to_next_command()

func _get_name() -> StringName: return "Choice List"

func _get_icon() -> Texture:
	return load("res://addons/textalog/commands/icons/picklist.svg")

func _can_hold_commands() -> bool: return true

func can_hold(command) -> bool:
	return command.can_hold_commands

func _notification(what: int) -> void:
	if what == NOTIFICATION_UPDATE_STRUCTURE:
		if generate_default_choices:
			var branches = [ChoiceClass, ChoiceClass]
			for command in collection:
				if command.get_script() in branches:
					branches.erase(command.get_script())
			for branch in branches:
				collection.append(branch.new())
			
			generate_default_choices = false


func _get_category() -> StringName:
	return &"Textalog"
