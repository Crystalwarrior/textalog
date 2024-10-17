extends Node

@onready var dialogbox = %DialogBox
@onready var command_manager: CommandProcessor = $CommandManager
@onready var testimony_indicator = dialogbox.testimony_indicator
@onready var characters_node = $Characters
@onready var backgrounds = $Background
@onready var canvas_modulate = $CanvasModulate
@onready var choice_list_node = $HUD/MainView/ChoiceList
@onready var evidence_menu = $HUD/EvidenceMenu
const SFXFOLDER = "res://sfx/"
const MUSICFOLDER = "res://music/"

const DialogCommand = preload("res://addons/textalog/commands/command_dialog.gd")
const CharacterCommand = preload("res://addons/textalog/commands/command_character.gd")
const EvidenceCommand = preload("res://addons/textalog/commands/command_evidence.gd")
const MusicCommand = preload("res://addons/textalog/commands/command_music.gd")
const BackgroundCommand = preload("res://addons/textalog/commands/command_background.gd")
const ChoiceListCommand = preload("res://addons/textalog/commands/command_choice_list.gd")

var auto = false:
	set(val):
		auto = val
		dialogbox.next_icon.modulate = Color.YELLOW if auto else Color.WHITE

var auto_delay: float = 1.2

var finished: bool = false
var waiting_on_input: bool = true
var hide_dialog_after_input: bool = false

var current_character = ""

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
		next()
	elif event.is_action_pressed("previous"):
		get_viewport().set_input_as_handled()
		if not waiting_on_input:
			dialogbox.skip()
		else:
			go_to_previous_statement()


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
		return
	if hide_dialog_after_input:
		dialogbox.hide()
	elif (not pause_testimony or finished) and not testimony.is_empty():
		if not pause_testimony or next_statement_on_pause:
			go_to_next_statement()
		else:
			go_to_statement(current_testimony_index)
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
	pause_testimony = false
	command_manager._disconnect_command_signals(command_manager.current_command)
	current_testimony_index = index
	testimony_indicator.select_statement(current_testimony_index)
	var command_bookmark = testimony[current_testimony_index]
	var target_command = testimony_timeline.get_command_by_bookmark(command_bookmark)
	var command_index = testimony_timeline.get_command_absolute_position(target_command)
	command_manager.jump_to_command(command_index, testimony_timeline)


func set_statements(statements: PackedStringArray):
	testimony = statements
	testimony_indicator.set_statements(testimony.size())


func start_testimony(statements: PackedStringArray = []):
	pause_testimony = false
	current_testimony_index = 0
	testimony_timeline = command_manager.current_collection
	print(statements)
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


func set_present(timeline: String = "", allow_evidence = true, allow_notes = false):
	if timeline == "":
		current_present = null
	else:
		current_present = load(timeline)
	$HUD/EvidenceMenu/EvidenceViewer/ShowButton.visible = current_present != null


func press():
	dialogbox.process_charcters = false
	dialog_finished.emit()
	pause_testimony = true
	next_statement_on_pause = true
	command_manager._disconnect_command_signals(command_manager.current_command)
	command_manager.start(current_press)


func dialog(dialog_command:DialogCommand) -> void:
	var showname = dialog_command.showname
	var dialog = dialog_command.dialog
	var letter_delay = dialog_command.letter_delay
	var blip_sound = dialog_command.blip_sound
	var hide_dialog = dialog_command.hide_dialog
	var HideDialog = dialog_command.HideDialog
	var wait_until_finished = dialog_command.wait_until_finished
	var speaking_character = dialog_command.speaking_character
	var additive = dialog_command.additive

	#TODO: use these for the characters
	var bump_speaker = dialog_command.bump_speaker
	var highlight_speaker = dialog_command.highlight_speaker

	dialogbox.letter_delay = letter_delay
	if blip_sound:
		dialogbox.set_blipsound(blip_sound)
	dialogbox.appear()
	dialogbox.display(dialog, showname, additive)
	
	current_character = speaking_character
	var chara = get_character(speaking_character)
	if chara:
		chara.start_talking()

	if hide_dialog == HideDialog.INSTANTLY:
		dialogbox.disappear()

	hide_dialog_after_input = hide_dialog == HideDialog.AFTER_INPUT

	# Pause until dialog finishes processing
	if wait_until_finished:
		print("Await ye mateys: " + dialog)
		await dialog_finished
	print("Paid off...")
	if chara:
		chara.stop_talking()

	if hide_dialog == HideDialog.AT_END:
		dialogbox.disappear()

	current_character = ""
	# If we wait until finished, remember tell the timeline to continue
	if wait_until_finished:
		dialog_command.go_to_next_command()


func character(character_command:CharacterCommand) -> void:
	var character: PackedScene = character_command.character
	var character_name: String = character_command.character_name
	var emote: String = character_command.emote
	var delete: bool = character_command.delete
	var add_position: bool = character_command.add_position
	var to_position: Vector2 = character_command.to_position
	var zoom_duration: float = character_command.zoom_duration
	var flipped: bool = character_command.flipped
	var bounce: bool = character_command.bounce
	var flip_duration: float = character_command.flip_duration
	var shaking:bool = character_command.shaking
	var set_z_index:int = character_command.set_z_index
	var wait_until_finished:bool = character_command.wait_until_finished
	var fade_out:bool = character_command.fade_out
	var fade_duration: float = character_command.fade_duration

	if character_name == "":
		character_name = character.resource_path.get_file().trim_suffix("." + character.resource_path.get_extension())

	var target = get_character(character_name)
	if not target:
		target = add_character(character, to_position, flipped)

	if emote != "":
		target.set_emote(emote)
	if shaking:
		target.start_shaking()
	else:
		target.stop_shaking()
	if fade_out:
		target.fadeout(fade_duration)
	else:
		target.fadein(fade_duration)
	target.z_index = set_z_index
	target.flip_h(flipped, flip_duration)
	target.move_to(to_position, Vector2(1, 1), zoom_duration, add_position)
	if bounce:
		target.bounce()
	# If we wait until finished, remember tell the timeline to continue
	if wait_until_finished:
		if target.waiting_on_animations > 0:
			await target.animation_finished
		character_command.go_to_next_command()
	if delete:
		remove_character(character_name)


func choice_list(choice_list_command:ChoiceListCommand) -> void:
	var choices = choice_list_command.choices
	for choice in choices:
		add_choice(choice)


func evidence(evidence_command:EvidenceCommand) -> void:
	# TODO: have a game data object that tracks evidence, don't let the UI keep track.
	match evidence_command.do_what:
		EvidenceCommand.Action.ADD_EVIDENCE:
			evidence_menu.add(evidence_command.evidence)
		EvidenceCommand.Action.ERASE_EVIDENCE:
			evidence_menu.erase_evidence(evidence_command.evidence)
		EvidenceCommand.Action.INSERT_AT_INDEX:
			push_error("Not implemented!")
			#evidence_menu.evidence_list.insert(evidence_command.at_index, evidence_command.evidence)
		EvidenceCommand.Action.REMOVE_AT_INDEX:
			evidence_menu.remove_evidence_index(evidence_command.at_index)


func set_flag(flag: String, val: Variant):
	flags[flag] = val
	flags_modified.emit(flags)


func get_flag(flag: String):
	if flag not in flags:
		return null
	return flags[flag]


func add_choice(title, disabled = false):
	var choice = choice_list_node.add_choice(title, disabled)
	if choice.text in choice_history:
		choice.modulate = Color(0.65, 0.65, 0.85)


func clear_choices():
	choice_list_node.clear_choices()


func get_savedict() -> Dictionary:
	var save_dict = {
		"main_collection": command_manager.main_collection.resource_path,
		"current_collection": command_manager.current_collection.resource_path,
		"current_command_idx": command_manager.current_command_position,
		"flags": flags,
		"background": current_background,
		"history": [],
		"jump_history": [],
	}

	# Process the history so it's saved not as object, but as paths
	var history = []
	for value in command_manager._history:
		var new_value = value.duplicate()
		new_value[command_manager._HistoryData.COLLECTION] = new_value[command_manager._HistoryData.COLLECTION].resource_path
		print(new_value)
		history.append(new_value)
	save_dict["history"] = history
	
	# Process the jump history so it's saved not as object, but as paths
	var jump_history = []
	for value in command_manager._jump_history:
		var new_value = value.duplicate()
		new_value[command_manager._JumpHistoryData.FROM][command_manager._HistoryData.COLLECTION] = new_value[command_manager._JumpHistoryData.FROM][command_manager._HistoryData.COLLECTION].resource_path
		new_value[command_manager._JumpHistoryData.TO][command_manager._HistoryData.COLLECTION] = new_value[command_manager._JumpHistoryData.TO][command_manager._HistoryData.COLLECTION].resource_path
		jump_history.append(new_value)
	save_dict["jump_history"] = jump_history

	return save_dict


func load_savedict(save_dict: Dictionary):
	if command_manager.current_command:
		command_manager._disconnect_command_signals(command_manager.current_command)
	for key in save_dict.keys():
		if key == "main_collection":
			command_manager.main_collection = load(save_dict[key])
		if key == "current_collection":
			command_manager.current_collection = load(save_dict[key])
		if key == "current_command_idx":
			command_manager.current_command_position = save_dict[key]
		if key == "flags":
			flags = save_dict[key]
		if key == "history":
			var history = []
			for value in save_dict[key]:
				value[command_manager._HistoryData.COLLECTION] = load(value[command_manager._HistoryData.COLLECTION])
				history.append(value)
			command_manager._history = history
		if key == "jump_history":
			var jump_history = []
			for value in save_dict[key]:
				value[command_manager._JumpHistoryData.FROM][command_manager._HistoryData.COLLECTION] = load(value[command_manager._JumpHistoryData.FROM][command_manager._HistoryData.COLLECTION])
				value[command_manager._JumpHistoryData.TO][command_manager._HistoryData.COLLECTION] = load(value[command_manager._JumpHistoryData.TO][command_manager._HistoryData.COLLECTION])
				jump_history.append(value)
			command_manager._jump_history = jump_history
		if key == "background":
			set_background(save_dict[key])
	command_manager.go_to_command(command_manager.current_command_position)


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
		evidence_name = evidence_list[index]["name"]
	return evidence_name


func get_note_name(index: int = -1):
	var note_name = ""
	var notes_list = $HUD/EvidenceMenu.notes_list
	if index < notes_list.size():
		note_name = notes_list[index]["name"]
	return note_name


func _character_stop_talking(speaker):
	speaker.stop_talking()
	dialog_finished.disconnect(_character_stop_talking)


func _on_command_manager_timeline_started(_timeline_resource):
	finished = false


func _on_command_manager_timeline_finished(_timeline_resource):
	# TODO: don't use pause_testimony, instead use the goto/return logic
	#if testimony and pause_testimony:
		#if next_statement_on_pause:
			#go_to_next_statement()
		#else:
			#go_to_statement(current_testimony_index)
		#return
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
	waiting_on_input = false
	pause_testimony = true
	next_statement_on_pause = false
	dialogbox.process_charcters = false
	dialog_finished.emit()
	print("WOAH")
	last_shown_evidence = index
	evidence_shown.emit(index)

	print(current_present)
	if current_present == null:
		return
	#command_manager._disconnect_command_signals(command_manager.current_command)
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
	choice_history.append(choice_list_node.get_choice_by_index(index).text)
	choice_selected.emit(index)
	last_picked_choice = index
	var choice_list_command: ChoiceListCommand = command_manager.current_command
	choice_list_command.choice_selected(index)
	clear_choices()
