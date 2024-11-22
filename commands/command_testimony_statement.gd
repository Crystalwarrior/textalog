@tool
extends Command

## The title of the statement to display in the editor
@export var title: String = "":
	set(value):
		title = value
		emit_changed()
	get:
		return title

## The condition to evaluate if the statement will be shown.
## If the evaluated result is false, this statement will be hidden.
## You can reference variables and even call functions, for example:[br]
## [code]value == true[/code][br]
## [code]not child.visible[/code][br]
## [code]get_index() == 2[/code][br]
## etc.
@export_placeholder("true") var condition:String:
	set(value):
		condition = value
		emit_changed()

## If not null, which collection to jump to when pressing for info
@export var press_collection:Collection:
	set(value):
		present_collection = value
		emit_changed()
	get: return present_collection

## If not null, which collection to jump to when presenting evidence
@export var present_collection:Collection:
	set(value):
		present_collection = value
		emit_changed()
	get: return present_collection


func _execution_steps() -> void:
	command_started.emit()
	command_finished.emit()

func _get_hint() -> String:
	var hint = ""
	if title:
		hint = "'" + title + "' "
	if not condition.is_empty():
		hint += "reveal if " + condition
	return hint

func _get_icon() -> Texture:
	return load("res://addons/textalog/commands/icons/statement.svg")


func _get_color() -> Color:
	return Color(0.5,1,0.5,1)


#func _can_be_moved() -> bool: return false

func _get_name() -> StringName:
	if index < 0:
		return &"Statement"
	return &"Statement " + str(index+1)

func _can_hold_commands() -> bool: return true

func get_next_command_position() -> int:
	var owner := get_command_owner()
	if not owner:
		# There's no command owner defined?
		assert(false)
		return -1
	
	# No more commands?
	if owner is Blockflow.CommandCollectionClass:
		assert(false)
		return -1

	if owner.current_statement == index:
		return position + 1

	var sibling_command := get_next_available_command()

	if sibling_command:
		return sibling_command.position
	
	var owner_sibling = owner.get_next_available_command()
	
#	while owner.get_next_available_command() == null:
	while owner_sibling == null:
		owner = owner.get_command_owner()
		if owner == null or owner is Blockflow.CommandCollectionClass:
			assert(false)
			return -1
		owner_sibling = owner.get_next_available_command()
	
	return owner_sibling.position


func _get_category() -> StringName:
	return &"Textalog"
