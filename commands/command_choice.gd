@tool
extends Command

@export var text: String = "":
	set(value):
		text = value
		emit_changed()
	get:
		return text

func _execution_steps() -> void:
	command_started.emit()
	command_finished.emit()

func _get_hint() -> String:
	return text

func _get_icon() -> Texture:
	return load("res://addons/blockflow/icons/group.svg")

#func _can_be_moved() -> bool: return false

func _get_name() -> StringName:
	return &"Choice"

func _can_hold_commands() -> bool: return true

func get_next_command_position() -> int:
	var owner := get_command_owner()
	if not owner:
		# There's no command owner defined?
		return -1
	
	# No more commands?
	if owner is Blockflow.CommandCollectionClass:
		return -1

	if owner.choice_picked == index:
		return position + 1

	var sibling_command := get_next_available_command()

	if sibling_command:
		return sibling_command.position
	
	var owner_sibling = owner.get_next_available_command()
	
#	while owner.get_next_available_command() == null:
	while owner_sibling == null:
		owner = owner.get_command_owner()
		if owner == null or owner is Blockflow.CommandCollectionClass:
			return -1
		owner_sibling = owner.get_next_available_command()
	
	return owner_sibling.position
