extends Control

signal show_evidence(index, is_note)

@onready var gray_out := %GrayOut

@onready var viewer := %EvidenceViewer

@onready var evidence_scroller := %EvidenceScroller
@onready var evidence_toggle := %EvidenceToggle

@onready var notes_scroller := %NotesScroller
@onready var notes_toggle := %NotesToggle

var current_selected_evidence = -1

var evidence_list = []
var notes_list = []

func deselect_all():
	evidence_scroller.deselect()
	notes_scroller.deselect()


func _on_show_button_pressed():
	show_evidence.emit(current_selected_evidence, viewer.show_button.text == "Ask")
	_on_expand_collapse_button_pressed()
	_on_evidence_scroller_selected_evidence(-1)


func add(evidence: Evidence, is_note=false):
	if is_note:
		if evidence in notes_list:
			push_warning("Note %s already in notes list, skipping..." % [evidence.name])
			return
		notes_list.append(evidence)
		notes_scroller.add_evidence(evidence)
	else:
		if evidence in evidence_list:
			push_warning("Evidence '%s' already in evidence list, skipping..." % [evidence.name])
			return
		evidence_list.append(evidence)
		evidence_scroller.add_evidence(evidence)


#region EVIDENCE CODE

func clear_evidence():
	evidence_list.clear()
	evidence_scroller.clear_evidence()


func remove_evidence_index(index):
	var evidence = evidence_list[index]
	if not evidence:
		return
	erase_evidence(evidence)


func remove_evidence_name(evidence_name):
	var evidence = find_name(evidence_name)
	if not evidence:
		return
	erase_evidence(evidence)


func erase_evidence(evidence):
	deselect_all()
	evidence_list.erase(evidence)
	evidence_scroller.remove_evidence(evidence.name)


func erase_note(note):
	deselect_all()
	notes_list.erase(note)
	notes_scroller.remove_evidence(note.name)


func find_name(evidence_name):
	for evi in evidence_list:
		if evi["name"] == evidence_name:
			return evi


# TODO: deprecate
func add_evidence(_name, _desc, _icon):
	if _icon is String:
		_icon = load(_icon)
	var evidence = {
		"name": _name,
		"desc": _desc,
		"icon": _icon
	}
	evidence_list += [evidence]
	evidence_scroller.add_evidence(evidence)


func select_evidence(evi):
	if evi is String:
		evi = evidence_list.find(find_name(evi))
	if evi <= -1:
		return
	evidence_toggle.set_pressed(true)
	evidence_scroller.select_evidence(evi)


func _on_evidence_scroller_selected_evidence(index):
	viewer.set_visible(index > -1)
	gray_out.set_visible(index > -1)
	current_selected_evidence = index
	if index > -1:
		viewer.set_data(evidence_list[index])


func _on_evidence_toggled(toggled_on):
	notes_toggle.set_pressed_no_signal(not toggled_on)
	notes_scroller.set_visible(not toggled_on)
	evidence_toggle.set_pressed_no_signal(toggled_on)
	evidence_scroller.set_visible(toggled_on)
	deselect_all()

#endregion


#region NOTES CODE

func clear_notes():
	notes_list.clear()
	notes_scroller.clear_evidence()


func remove_note(note_name):
	var note = find_note_name(note_name)
	if not note:
		return
	notes_list -= [note]
	notes_scroller.remove_note(note)


func find_note_name(note_name):
	for evi in notes_list:
		if evi["name"] == note_name:
			return evi


# TODO: deprecate
func add_note(_name, _desc, _icon):
	if _icon is String:
		_icon = load(_icon)
	var note = {
		"name": _name,
		"desc": _desc,
		"icon": _icon
	}
	notes_list += [note]
	notes_scroller.add_evidence(note)


func select_note(note):
	if note is String:
		note = notes_list.find(find_note_name(note))
	if note <= -1:
		return
	notes_toggle.set_pressed(true)
	notes_scroller.select_evidence(note)


func _on_note_scroller_selected_note(index):
	viewer.set_visible(index > -1)
	gray_out.set_visible(index > -1)
	current_selected_evidence = index
	if index > -1:
		viewer.set_data(notes_list[index])


func _on_notes_scroller_selected(index):
	viewer.set_visible(index > -1)
	gray_out.set_visible(index > -1)
	current_selected_evidence = index
	if index > -1:
		viewer.set_data(notes_list[index])


func _on_notes_toggled(toggled_on):
	notes_toggle.set_pressed_no_signal(toggled_on)
	notes_scroller.set_visible(toggled_on)
	evidence_toggle.set_pressed_no_signal(not toggled_on)
	evidence_scroller.set_visible(not toggled_on)
	deselect_all()

#endregion



func _on_expand_collapse_button_pressed():
	deselect_all()
	viewer.set_visible(false)
	var shown = not %EvidencePullout.visible
	%EvidencePullout.set_visible(shown)
	%ExpandCollapseButton.set_text("⬆💼⬆" if shown else "⬇💼⬇")
