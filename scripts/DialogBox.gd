@tool
extends Control


signal message_set()
signal message_add()
signal message_end()

@export var showname_label: RichTextLabel
@export var dialog_label: RichTextLabel
@export var letter_delay: float = 0.02

@export var blip_sound: AudioStream
@export var blip_rate: int = 2

@export var next_icon: Control

@export var visual_box: Control

@export var testimony_indicator: Control

# Text Speed constants
# TODO: make "decay" decide *how long* the shake lasts rather than being nebulous as it is right now
const SHAKE_INTENSITIES: Array = [
	# LIGHT
	{
		trauma=0.5,
		decay=1.5,
		trauma_power = 1,
		max_offset = Vector2(20, 20),
	},
	# MEDIUM
	{
		trauma = 1,
		decay = 3,
		trauma_power = 1,
		max_offset = Vector2(20, 20),
	},
	# STRONG
	{
		trauma = 2,
		decay = 3,
		trauma_power = 2,
		max_offset = Vector2(15, 10),
	},
	# INTENSE
	{
		trauma = 3,
		decay = 3,
		trauma_power = 2,
		max_offset = Vector2(8, 5),
	},
]
enum ShakeIntensities {LIGHT, MEDIUM, STRONG, INTENSE} 

@onready var blip_player: AudioStreamPlayer = $BlipPlayer
var process_charcters: bool = false
var process_counter: float = 0.0

var last_animation = ""
var last_animation_speed = 1.0

var blip_counter: int = 0

var parsed_text = ""

# How quickly the shaking stops
var decay = 1.5
# Current shake strength.
var trauma = 0.0
# Trauma exponent. Use [2, 3].
var trauma_power = 2
# Maximum hor/ver shake in pixels. If trauma is above 1, it will go BEYOND
var max_offset = Vector2(20, 20)

const BLIPMALE_STREAM: AudioStream = preload("res://addons/textalog/sfx/blip_male.wav")
const BLIPFEMALE_STREAM: AudioStream = preload("res://addons/textalog/sfx/blip_female.wav")
const BLIPTYPEWRITER_STREAM: AudioStream = preload("res://addons/textalog/sfx/typewriter.wav")
const BLIPFOLDER = "res://blips/"


func _on_dialog_view_wait_for_input(tog):
	next_icon._on_dialog_view_wait_for_input(tog)


func _process(delta):
	if process_charcters:
		process_counter += delta
		if process_counter >= letter_delay:
			var count: int = int(process_counter / letter_delay)
			while (letter_delay == 0 or count > 0) and process_charcters:
				next_letter()
				count -= 1
			process_counter = 0
			var letter = parsed_text[dialog_label.visible_characters-1] if parsed_text != "" else ""
			if blip_counter == 0 and letter != "":
				blip()
			blip_counter = (blip_counter + 1) % blip_rate
	if trauma:
		trauma = max(trauma - decay * delta, 0)
		%chat_bg.modulate.a = max(1.0 - trauma, 0)
		%chat_speedlines.modulate.a = trauma
		shake()


func blip():
	blip_player.play()


func skip():
	if process_charcters:
		dialog_label.visible_characters = parsed_text.length()
		next_letter()


func next_letter():
	dialog_label.visible_characters += 1
	if dialog_label.visible_characters >= parsed_text.length():
		process_charcters = false
		message_end.emit()


func start_processing():
	blip_counter = 0
	process_charcters = true


func set_showname(showname):
	showname_label.text = showname
	showname_label.visible = not showname_label.text.is_empty()


func set_msg(text):
	dialog_label.visible_characters = 0
	dialog_label.text = text
	message_set.emit()


func add_msg(text):
	dialog_label.text += text
	message_add.emit()


func display(text, showname, additive):
	set_showname(showname)
	if additive:
		add_msg(text)
	else:
		set_msg(text)
	parsed_text = dialog_label.get_parsed_text()
	start_processing()


func appear():
	show()


func disappear():
	hide()


func set_blipsound(blip_string:String):
	var new_stream: AudioStream
	if blip_string == "male":
		new_stream = BLIPMALE_STREAM
	elif blip_string == "female":
		new_stream = BLIPFEMALE_STREAM
	elif blip_string == "typewriter":
		new_stream = BLIPTYPEWRITER_STREAM
	else:
		# Direct filepath to blip
		if ResourceLoader.exists(blip_string, "AudioStream"):
			new_stream = load(blip_string)
		# Filename in the blips folder
		elif ResourceLoader.exists(BLIPFOLDER + blip_string + ".wav", "AudioStream"):
			new_stream = load(BLIPFOLDER + blip_string + ".wav")
		else:
			push_error("Blip sound ", blip_string, " not found!")
	blip_player.set_stream(new_stream)


func get_savedict() -> Dictionary:
	var save_dict = {
		"letter_delay": letter_delay,
		"showname": showname_label.text,
		"dialog": dialog_label.text,
		"animation": [last_animation, last_animation_speed],
	}
	return save_dict


func shake():
	var amount = pow(trauma, trauma_power)
	visual_box.position.x = max_offset.x * amount * randf_range(-1, 1)
	visual_box.position.y = max_offset.y * amount * randf_range(-1, 1)


func set_shake(intesnity: ShakeIntensities):
	pass


func load_savedict(save_dict: Dictionary):
	for key in save_dict.keys():
		var value = save_dict[key]
		if key == "showname":
			showname_label.text = value
		if key == "dialog":
			set_msg(value)
		if key == "letter_delay":
			set(key, value)
		if key == "animation":
			$AnimationPlayer.play(value[0], -1, value[1], value[1] < 0)


func _on_animation_player_animation_started(_anim_name):
	last_animation = $AnimationPlayer.current_animation
	last_animation_speed = $AnimationPlayer.get_playing_speed()


func _on_shake_me_pressed():
	var shake_intensity = SHAKE_INTENSITIES[%ShakeMeOptions.get_selected_id()]
	trauma = shake_intensity.trauma
	decay = shake_intensity.decay
	trauma_power = shake_intensity.trauma_power
	max_offset = shake_intensity.max_offset
