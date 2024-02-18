@tool
extends Control

const color_save_path = "res://addons/textalog/swatches.ini"

@onready var text_edit: TextEdit = %TextEdit

@onready var dialog_box = %DialogBox
@onready var color_picker_dialog = %ColorPickerDialog
@onready var color_picker = %ColorPicker

@onready var button_bar = %ButtonBar

var current_color_tag = ""

var editor_command: Command

var current_speed = 0.034
var current_blip = "male"


func _ready():
	if dialog_box.dialog_container.shake_effect == null:
		dialog_box.dialog_container.add_shake_effect()

	load_color_presets()


func set_command(command: Command):
	editor_command = command
	set_dialog(editor_command.dialog)
	dialog_box.dialog_container.set_showname_text(editor_command.showname)
	current_speed = editor_command.letter_delay
	dialog_box.set_speed(current_speed)
	current_blip = editor_command.blip_sound
	dialog_box.set_blipsound(current_blip)


func set_dialog(text: String):
	text_edit.text = text
	dialog_box.dialog_container.set_text_to_show(text_edit.text)
	dialog_box.dialog_container.text_label.visible_characters = -1


func _on_text_edit_text_changed():
	dialog_box.dialog_container.set_text_to_show(text_edit.text)
	dialog_box.dialog_container.text_label.visible_characters = -1


func insert_tag(tag: String, options: Variant =null, overwrite_tag = false):
	text_edit.begin_complex_operation()
	for i in text_edit.get_caret_count():
		var text = text_edit.get_selected_text(i)
		var line_from = text_edit.get_selection_from_line(i)
		var column_from = text_edit.get_selection_from_column(i)
		var line_to = text_edit.get_selection_to_line(i)
		var column_to = text_edit.get_selection_to_column(i)
		if text.begins_with("[" + tag) and text.ends_with("[/" + tag + "]"):
			var found_l = text.substr(0, text.find("]")+1)
			var found_r = "[/" + tag + "]"
			var untag_to = text.length()-found_l.length()-found_r.length()
			var untagged_text = text.substr(found_l.length(), untag_to)
			
			text_edit.delete_selection(i)
			text_edit.insert_text_at_caret(untagged_text, i)
			var line = text_edit.get_caret_line(i)
			var column = text_edit.get_caret_column(i)
			text_edit.select(line_from, column_from, line, column, i)
			if not overwrite_tag:
				continue
			text = text_edit.get_selected_text(i)
			line_from = text_edit.get_selection_from_line(i)
			column_from = text_edit.get_selection_from_column(i)
			line_to = text_edit.get_selection_to_line(i)
			column_to = text_edit.get_selection_to_column(i)

		var insert = "[" + tag
		if options is String:
			insert += "=" + options
		elif options is Dictionary:
			for key in options:
				insert += " " + key + "=" + options[key]
		elif options != null:
			push_error("Invalid tag options: must be String or Dictionary")
			return
		insert += "]" + text + "[/" + tag + "]"

		text_edit.insert_text_at_caret(insert, i)
		var line = text_edit.get_caret_line(i)
		var column = text_edit.get_caret_column(i)
		if column_from == -1:
			column_from = column-insert.length()
			line_from = line
		text_edit.select(line_from, column_from, line, column, i)

	text_edit.end_complex_operation()
	text_edit.grab_focus()


func insert_color(tag: String, color: Color):
	insert_tag(tag, "#" + color.to_html(), true)


func _on_play_button_pressed():
	dialog_box.set_speed(current_speed)
	dialog_box.set_blipsound(current_blip)
	dialog_box.display_text(text_edit.text, editor_command.showname)


func _on_color_picker_dialog_confirmed():
#	button_bar.get_node(current_color_tag).modulate = color_picker.color
	insert_color(current_color_tag, color_picker.color)
	current_color_tag = ""


func _on_color_picker_dialog_canceled():
	current_color_tag = ""


func _on_text_color_pressed():
	color_picker_dialog.title = "Pick a text color"
	color_picker_dialog.popup_centered()
	current_color_tag = "color"


func _on_background_color_pressed():
	color_picker_dialog.title = "Pick a background color"
	color_picker_dialog.popup_centered()
	current_color_tag = "bgcolor"


func _on_foreground_color_pressed():
	color_picker_dialog.title = "Pick a foreground color"
	color_picker_dialog.popup_centered()
	current_color_tag = "fgcolor"


func insert_text_command(cmd: String, param: String=""):
	var params = " " + param if param != "" else ""
	var insert_text = "{" + cmd + params + "}"
	text_edit.begin_complex_operation()
	for i in text_edit.get_caret_count():
		text_edit.insert_text_at_caret(insert_text, i)
	text_edit.end_complex_operation()
	text_edit.grab_focus()


func _on_option_button_item_selected(index):
	var item_text = %spd_button.get_item_text(index)
	var cmd = CmdValues.SPD
	if item_text == "custom":
		insert_text_command(cmd, "0.034")
	else:
		insert_text_command(cmd + "_" + item_text)


func _on_shake_pressed():
	insert_text_command(CmdValues.SHAKE)


func _on_flash_pressed():
	insert_text_command(CmdValues.FLASH)


func _on_pause_pressed():
	insert_text_command(CmdValues.PAUSE, "0.2")


func _on_blip_pressed():
	insert_text_command(CmdValues.BLIP, "male")


func load_color_presets():
	var config_file := ConfigFile.new()
	var error := config_file.load(color_save_path)

	if error:
		print("Failed to load color picker presets for the Dialog Editor!")
		return

	var color_presets: PackedColorArray = config_file.get_value("", "colors", null)
	for old_color in color_picker.get_presets():
		color_picker.erase_preset(old_color)
	for color in color_presets:
		color_picker.add_preset(color)


func save_color_presets():
	var config_file := ConfigFile.new()

	config_file.set_value("", "colors", color_picker.get_presets())

	config_file.save(color_save_path)


func _on_color_picker_preset_added(_color):
	save_color_presets()


func _on_color_picker_preset_removed(_color):
	save_color_presets()
