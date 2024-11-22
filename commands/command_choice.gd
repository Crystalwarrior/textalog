@tool
extends Command

@export var text: String = "":
	set(value):
		text = value
		emit_changed()
	get:
		return text

## The condition to evaluate. If false, this choice is skipped.
## You can reference variables and even call functions, for example:[br]
## [code]value == true[/code][br]
## [code]not child.visible[/code][br]
## [code]get_index() == 2[/code][br]
## etc.
@export_placeholder("true") var condition:String:
	set(value):
		condition = value
		emit_changed()

func _execution_steps() -> void:
	command_started.emit()
	command_finished.emit()

func _condition_is_true(node_target = null) -> bool:
	if condition.is_empty():
		return true
	# Local variables. These can be added as context for condition evaluation.
	var variables:Dictionary = {}
	# must be a bool, but Utils.evaluate can return Variant according its input.
	# TODO: Make sure that condition is a boolean operation
	if node_target == null:
		node_target = self.target_node
	var evaluated_condition = Blockflow.Utils.evaluate(condition, node_target, variables)
	if (typeof(evaluated_condition) == TYPE_STRING) and (str(evaluated_condition) == condition):
		# For some reason, your condition cannot be evaluated.
		# Here's a few reasons:
		# 1. Your target_node may not have that property you specified.
		# 2. You wrote wrong the property.
		# 3. You wrote wrong the function name.
		push_warning("%s failed. The condition will be evaluated as false." % [self])
		return false
	
	return bool(evaluated_condition)

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


func _get_category() -> StringName:
	return &"Textalog"
