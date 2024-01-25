extends Node

@onready var dialogbox = $HUD/MainView/DialogBox
@onready var command_manager: CommandProcessor = $CommandManager
@onready var testimony_indicator = $HUD/MainView/DialogBox/TestimonyIndicator
@onready var characters_node = $Characters
@onready var backgrounds = $Background
@onready var canvas_modulate = $CanvasModulate
@onready var choice_list = $HUD/MainView/ChoiceList

var auto = false:
	set(val):
		auto = val
		$HUD/MainView/DialogBox/NextIcon.modulate = Color.YELLOW if auto else Color.WHITE

var auto_delay: float = 1.2

var finished = false
var waiting_on_input = true

var testimony: PackedStringArray = []
var testimony_timeline: CommandCollection
var current_testimony_index: int = 0

var pause_testimony: bool = false
var next_statement_on_pause: bool = false
var current_press: CommandCollection
var current_present: CommandCollection

var last_shown_evidence: int = -1

var last_picked_choice: int = -1

var current_background: String

var value: int = 0

var choice_history: PackedStringArray = []

var flags = {}:
	set(val):
		flags = val
		flags_modified.emit(flags)

signal wait_for_input(tog)
signal flags_modified(flags)
signal choice_selected(index)

signal dialog_finished
signal evidence_shown(index)


func _process_testimony(event):
	if event.is_action_pressed("next"):
		get_viewport().set_input_as_handled()
		get_window().gui_release_focus()
		next()
	elif event.is_action_pressed("previous"):
		get_window().gui_release_focus()
		get_viewport().set_input_as_handled()
		if not waiting_on_input:
			dialogbox.skip()
		else:
			go_to_previous_statement()
	elif event.is_action_pressed("press") and current_press:
		get_window().gui_release_focus()
		get_viewport().set_input_as_handled()
		press()


func _process_timeline(event):
	if event.is_action_pressed("auto"):
		get_viewport().set_input_as_handled()
		auto = not auto
		if waiting_on_input and auto:
			next()
	if event.is_action_pressed("next"):
		get_viewport().set_input_as_handled()
		if auto:
			auto = false
			return
		next()


func next():
	get_window().gui_release_focus()
	if not waiting_on_input:
		dialogbox.skip()
	elif not pause_testimony and not testimony.is_empty():
		go_to_next_statement()
	elif not finished:
		if not command_manager.main_collection:
			command_manager.start()
		else:
			command_manager.go_to_next_command()


func canvas_fade(to_color: Color = Color.WHITE, duration: float = 1.0):
	canvas_modulate.fade(to_color, duration)


func canvas_fadeout(duration: float = 1.0):
	canvas_fade(Color.BLACK, duration)


func canvas_fadein(duration: float = 1.0):
	canvas_fade(Color.WHITE, duration)


func dialog_fade(speed: float = 1.0):
	$HUD/MainView.fade(speed)


func add_character(res_path, starter_pos: Vector2 = Vector2(0, 0), flipped: bool = false):
# multithreaded character loading, this is WIP and will probably need 
# its own command node to handle more efficiently
#	ResourceLoader.load_threaded_request(res_path)
#	while(ResourceLoader.load_threaded_get_status(res_path) == ResourceLoader.THREAD_LOAD_IN_PROGRESS):
#		await get_tree().process_frame
#	var chara = ResourceLoader.load_threaded_get(res_path).instantiate()
	var chara
	if res_path is PackedScene:
		chara = res_path.instantiate()
	elif res_path is String:
		chara = load(res_path).instantiate()
	else:
		push_error("add_character: 'res_path' not String or PackedScene")
		return null
	chara.add_to_group("save")
	chara.add_to_group("characters")
	var found = characters_node.get_node_or_null(NodePath(chara.name))
	if found:
		found.free()
	characters_node.add_child(chara)
	chara.position = starter_pos
	if flipped:
		chara.flip_h(0)
	return chara


func get_characters():
	return get_tree().get_nodes_in_group("characters")


func get_character(charname):
	var characters = get_characters()
	for chara in characters:
		if chara.name.to_lower() == charname.to_lower():
			return chara
	return null


func remove_character(charname):
	var chara = get_character(charname)
	if chara:
		chara.queue_free()


func set_background(res_path):
	clear_background()

	var bg = load(res_path)
	if bg is PackedScene:
		bg = bg.instantiate()
		if bg.has_signal("object_clicked"):
			bg.object_clicked.connect(_on_object_clicked)
	else:
		var sprite := TextureRect.new()
		sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		sprite.texture = bg
		sprite.set_anchors_preset(sprite.PRESET_FULL_RECT)
		bg = sprite
	current_background = res_path
	backgrounds.add_child(bg)


func clear_background():
	current_background = ""
	for child in backgrounds.get_children():
		child.queue_free()


func play_sound(res_path):
	var sfx = load(res_path)
	var audio := AudioStreamPlayer.new()
	add_child(audio)
	audio.stream = sfx
	audio.play()
	audio.finished.connect(audio.queue_free, CONNECT_ONE_SHOT)


func go_to_next_statement():
	var target_index = (current_testimony_index + 1) % testimony.size()
	go_to_statement(target_index)


func go_to_previous_statement():
	var target_index = posmod(current_testimony_index - 1, testimony.size())
	go_to_statement(target_index)


func go_to_statement(index: int):
	command_manager._disconnect_command_signals(command_manager.current_command)
	current_testimony_index = index
	testimony_indicator.select_statement(current_testimony_index)
	var command_bookmark = testimony[current_testimony_index]
	var target_command = testimony_timeline.get_command_by_bookmark(command_bookmark)
	var command_index = testimony_timeline.get_command_absolute_position(target_command)
	command_manager.go_to_command_in_collection(command_index, testimony_timeline)


func set_statements(statements: PackedStringArray):
	testimony_timeline = command_manager.current_collection
	testimony = statements
	testimony_indicator.set_statements(testimony.size())


func start_testimony(statements: PackedStringArray = []):
	pause_testimony = false
	current_testimony_index = 0
	if not statements.is_empty():
		set_statements(statements)
	go_to_statement(current_testimony_index)


func stop_testimony():
	pause_testimony = false
	testimony_timeline = null
	testimony.clear()
	current_press = null
	current_present = null
	current_testimony_index = 0
	testimony_indicator.set_statements(0)


func set_press(timeline: CommandCollection = null):
	current_press = timeline


func set_present(timeline: CommandCollection = null):
	current_present = timeline
	$HUD/EvidenceMenu/EvidenceViewer/ShowButton.visible = current_present != null


func press():
	dialogbox.process_charcters = false
	dialog_finished.emit()
	pause_testimony = true
	next_statement_on_pause = true
	command_manager._disconnect_command_signals(command_manager.current_command)
	command_manager.start(current_press)


func dialog(showname: String = "", text: String = "", additive: bool = false, letter_delay: float = 0.02) -> void:
	dialogbox.letter_delay = letter_delay
	dialogbox.set_showname(showname)
	if additive:
		dialogbox.add_msg(text)
	else:
		dialogbox.set_msg(text)


func set_flag(flag: String, val: Variant):
	flags[flag] = val
	flags_modified.emit(flags)


func get_flag(flag: String):
	if flag not in flags:
		return null
	return flags[flag]


func add_choice(title, disabled = false):
	var choice = choice_list.add_choice(title, disabled)
	if choice.text in choice_history:
		choice.modulate = Color(0.65, 0.65, 0.85)


func clear_choices():
	choice_list.clear_choices()


func get_savedict() -> Dictionary:
	var save_dict = {
		"timeline": command_manager.current_collection.get_path(),
		"current_command_idx": command_manager.current_command_idx,
		"flags": flags,
		"history": command_manager._history,
		"jump_history": command_manager._jump_history,
		"background": current_background,
	}
	return save_dict


func load_savedict(save_dict: Dictionary):
	if command_manager.current_command:
		command_manager._disconnect_command_signals(command_manager.current_command)
	for key in save_dict.keys():
		if key == "timeline":
			command_manager.current_collection = load(save_dict[key])
		if key == "current_command_idx":
			command_manager.current_command_idx = save_dict[key]
		if key == "flags":
			flags = save_dict[key]
		if key == "history":
			command_manager._history = save_dict[key]
		if key == "jump_history":
			command_manager._jump_history = save_dict[key]
		if key == "background":
			set_background(save_dict[key])
	command_manager.start(null, command_manager.current_command_idx)


func evidence_exists(evidence_name: String):
	var evidence_list = $HUD/EvidenceMenu.evidence_list
	for evi in evidence_list:
		if evi["name"] == evidence_name:
			return true
	return false


func get_evidence_name(index: int = -1):
	var evidence_name = ""
	var evidence_list = $HUD/EvidenceMenu.evidence_list
	if index < evidence_list.size():
		return evidence_list[index]["name"]
	return evidence_name


func _character_stop_talking(speaker):
	speaker.stop_talking()
	dialog_finished.disconnect(_character_stop_talking)


func _on_command_manager_timeline_started(_timeline_resource):
	finished = false


func _on_command_manager_timeline_finished(_timeline_resource):
	# TODO: don't use pause_testimony, instead use the goto/return logic
	if testimony and pause_testimony:
		pause_testimony = false
		if next_statement_on_pause:
			go_to_next_statement()
		else:
			go_to_statement(current_testimony_index)
		return
	finished = true


func set_waiting_on_input(tog: bool):
	waiting_on_input = tog
	wait_for_input.emit(tog)

func _on_command_manager_command_started(_command):
	set_waiting_on_input(false)


func _on_command_manager_command_finished(_command):
	set_waiting_on_input(_command.get_script().resource_path == "res://addons/textalog/commands/command_dialog.gd")
	if auto and waiting_on_input and not _command.continue_at_end:
		await get_tree().create_timer(auto_delay).timeout
		if auto:
			next()


func _on_dialog_box_message_end():
	dialog_finished.emit()


func _on_show_evidence(index):
	#pause_testimony = true
	next_statement_on_pause = false
	dialogbox.process_charcters = false
	dialog_finished.emit()
	$HUD/EvidenceMenu/EvidenceToggle.button_pressed = false

	last_shown_evidence = index
	evidence_shown.emit(index)

	if current_present == null:
		return
	command_manager._disconnect_command_signals(command_manager.current_command)
	command_manager.go_to_command_in_collection(0, current_present)


func _on_evidence_menu_show_evidence(index):
	_on_show_evidence(index)


func _on_object_clicked(obj, target_timeline: CommandCollection):
	if not obj or obj.is_queued_for_deletion():
		return
	if not target_timeline:
		return
	command_manager.start(target_timeline)
	
	# TODO: don't use await lol
	await command_manager.collection_finished
	if not obj or obj.is_queued_for_deletion():
		return
	obj.checked = true


func _on_choice_list_choice_selected(index):
	choice_history.append(choice_list.get_choice_by_index(index).text)
	choice_selected.emit(index)
	last_picked_choice = index
