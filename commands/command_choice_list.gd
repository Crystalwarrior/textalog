@tool
extends Command

var choice_picked

const ChoiceClass = preload("res://addons/textalog/commands/command_choice.gd")
var generate_default_choices:bool = true

func _execution_steps() -> void:
	command_started.emit()
	var choices: PackedStringArray = []
	for command in collection:
		choices.append(command.text)
	target_node.multiple_choice(choices)
	if target_node.is_connected("choice_selected", choice_selected):
		target_node.choice_selected.disconnect(choice_selected)
	target_node.choice_selected.connect(
		choice_selected,
		CONNECT_ONE_SHOT
	)

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
