@tool
extends Command

@export var title: String = "":
	set(value):
		title = value
		emit_changed()
	get:
		return title

var choice_picked

const StatementClass = preload("res://addons/textalog/commands/command_testimony_statement.gd")
var generate_default_choices:bool = true

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

func _get_name() -> StringName: return "Testimony"

func _get_hint() -> String:
	return title

func _get_icon() -> Texture:
	return load("res://addons/textalog/commands/icons/testimony.svg")

func _can_hold_commands() -> bool: return true

func can_hold(command) -> bool:
	return command.can_hold_commands

func _notification(what: int) -> void:
	if what == NOTIFICATION_UPDATE_STRUCTURE:
		if generate_default_choices:
			var branches = [StatementClass, StatementClass]
			for command in collection:
				if command.get_script() in branches:
					branches.erase(command.get_script())
			for branch in branches:
				collection.append(branch.new())
			
			generate_default_choices = false


func _get_category() -> StringName:
	return &"Textalog"

