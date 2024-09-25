extends Node

var infotext_tween: Tween


func _process(_delta):
	var save_slot = null
	var load_slot = null
	if Input.is_action_just_pressed("quicksave_1"):
		save_slot = 1
	if Input.is_action_just_pressed("quicksave_2"):
		save_slot = 2
	if Input.is_action_just_pressed("quicksave_3"):
		save_slot = 3
	if Input.is_action_just_pressed("quicksave_4"):
		save_slot = 4

	if Input.is_action_just_pressed("quickload_1"):
		load_slot = 1
	if Input.is_action_just_pressed("quickload_2"):
		load_slot = 2
	if Input.is_action_just_pressed("quickload_3"):
		load_slot = 3
	if Input.is_action_just_pressed("quickload_4"):
		load_slot = 4

	if save_slot:
		if SaveSystem.save_game(save_slot):
			show_info_text("Saved on slot " + str(save_slot))
		else:
			show_info_text("FAILED to save on slot " + str(save_slot) + "!")
		return

	if load_slot:
		if SaveSystem.load_game(load_slot):
			show_info_text("Loaded slot " + str(load_slot))
		else:
			show_info_text("FAILED to load slot " + str(load_slot) + "!")
		return


func _on_set_button_pressed():
	$MainView/DialogBox.set_showname($DebugStuff/LineEdit.text)
	$MainView/DialogBox.set_msg($DebugStuff/MsgEdit.text)
	$MainView/DialogBox.letter_delay = $DebugStuff/DelaySpinBox.value


func _on_add_button_pressed():
	$MainView/DialogBox.set_showname($DebugStuff/LineEdit.text)
	$MainView/DialogBox.add_msg($DebugStuff/MsgEdit.text)
	$MainView/DialogBox.letter_delay = $DebugStuff/DelaySpinBox.value

func show_info_text(text: String):
	if %DebugInfoLabel.modulate.a < 0.8:
		%DebugInfoLabel.text = ""
	%DebugInfoLabel.modulate.a = 1.0
	%DebugInfoLabel.text += text + "\n"
	var interval = 1
	var fadeout_duration = 1
	if infotext_tween:
		infotext_tween.kill()
	infotext_tween = create_tween()
	infotext_tween.tween_interval(interval)
	infotext_tween.tween_property(%DebugInfoLabel, "modulate:a", 0.0, fadeout_duration).set_trans(Tween.TRANS_QUINT)
