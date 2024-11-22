@tool
extends EditorInspectorPlugin
var editor_plugin:EditorPlugin

const CommandDialog = preload("res://addons/textalog/commands/command_dialog.gd")

const DialogEditorPath = preload("res://addons/textalog/commands/dialog/dialog_editor.tscn")

const edit_icon = preload("res://addons/textalog/commands/icons/speech.svg")

const highlighter = preload("res://addons/textalog/commands/dialog/dialog_highlighter.tres")

class DialogEditorWindow extends ConfirmationDialog:
	var editor_plugin:EditorPlugin
	var dialog_editor
	func _init() -> void:
		title = "Dialog Editor"
		dialog_editor = DialogEditorPath.instantiate()
		add_child(dialog_editor)

class DialogEditorButton extends EditorProperty:
	var editor_plugin:EditorPlugin
	var hbox:HBoxContainer
	var text_edit:TextEdit
	var method_button:Button
	var dialog_editor_window:DialogEditorWindow
	
	func _update_property() -> void:
		var edited_object:CommandDialog = get_edited_object()
		var dialog:String = edited_object.dialog
		var text:String = ""
		var icon:Texture = get_theme_icon("Node", "EditorIcons")

		if text_edit.text != dialog:
			text_edit.text = dialog
	
	func _method_button_pressed() -> void:
		dialog_editor_window.confirmed.connect(_method_selector_confirmed, CONNECT_ONE_SHOT)
		dialog_editor_window.popup_centered(Vector2i(1288, 720))
		dialog_editor_window.dialog_editor.set_command(get_edited_object())

	func _method_selector_confirmed() -> void:
		get_edited_object().dialog = dialog_editor_window.dialog_editor.text_edit.text
		get_edited_object().notify_property_list_changed()

	func _on_text_changed() -> void:
		get_edited_object().dialog = text_edit.text

	func _enter_tree() -> void:
		dialog_editor_window = editor_plugin.dialog_editor

	func _init() -> void:
		hbox = HBoxContainer.new()
		add_child(hbox)
		set_bottom_editor(hbox)
		
		text_edit = TextEdit.new()
		text_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text_edit.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
		text_edit.custom_minimum_size = Vector2(0, 96)
		text_edit.syntax_highlighter = highlighter
		text_edit.text_changed.connect(_on_text_changed)
		
		hbox.add_child(text_edit)
		add_focusable(text_edit)

		method_button = Button.new()
		method_button.icon = edit_icon
		method_button.expand_icon = true
		method_button.pressed.connect(_method_button_pressed)
		method_button.custom_minimum_size = Vector2(32, 0)
		method_button.tooltip_text = "Open Dialog Editor"
		hbox.add_child(method_button)
		add_focusable(method_button)

func _can_handle(object: Object) -> bool:
	return object is CommandDialog

func _parse_property(
	object: Object,
	type, # For some reason, setting it typed is inconsistent
	name: String,
	hint_type,
	hint_string: String,
	usage_flags,
	wide: bool ) -> bool:
		if not object:
			# For some reason there's no object?
			return false
		
		var override_property = object.get_meta("__editor_override_property__", true)
		if name == "dialog":
			var dialog_editor_button := DialogEditorButton.new()
			dialog_editor_button.editor_plugin = editor_plugin
			add_property_editor("dialog", dialog_editor_button)
			return override_property
		
		return false
