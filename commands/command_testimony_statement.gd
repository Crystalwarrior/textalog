@tool
extends Command

@export var title: String = "":
	set(value):
		title = value
		emit_changed()
	get:
		return title

func _execution_steps() -> void:
	command_started.emit()
	command_finished.emit()

func _get_hint() -> String:
	return title

func _get_icon() -> Texture:
	return load("res://addons/textalog/commands/icons/statement.svg")


func _get_color() -> Color:
	return Color(0.5,1,0.5,1)


#func _can_be_moved() -> bool: return false

func _get_name() -> StringName:
	if index < 0:
		return &"Statement"
	return &"Statement " + str(index)

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
