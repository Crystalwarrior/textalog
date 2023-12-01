@tool
extends Command

var choice_picked

func _execution_steps() -> void:
	command_started.emit()
	for command in collection:
		target_node.add_choice(command.text)
	if target_node.is_connected("choice_selected", choice_selected):
		target_node.choice_selected.disconnect(choice_selected)
	target_node.choice_selected.connect(
		choice_selected,
		CONNECT_ONE_SHOT
	)

func choice_selected(index):
	target_node.clear_choices()
	choice_picked = index
	go_to_next_command()

func _get_name() -> StringName: return "Choice List"

func _get_icon() -> Texture:
	return load("res://addons/textalog/commands/icons/picklist.svg")

func _can_hold_commands() -> bool: return true

func can_hold(command) -> bool:
	return command.command_name == &"Choice"
