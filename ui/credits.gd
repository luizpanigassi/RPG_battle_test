extends Control

@export var scroll_speed := 30.0

@onready var scroll: ScrollContainer = $ScrollContainer
@onready var skip_button: Button = $SkipButton
@onready var credits_text: RichTextLabel = $ScrollContainer/VBoxContainer/CreditsText
@onready var spacer: Control = $ScrollContainer/VBoxContainer/TopSpacer
@onready var bottom_spacer: Control = $ScrollContainer/VBoxContainer/BottomSpacer
@onready var fake_button: Button = $VBoxContainer/CenterContainer/RewardButton
@onready var fake_message: Label = $VBoxContainer/RewardMessage
@onready var fake_box: VBoxContainer = $VBoxContainer
@onready var music: AudioStreamPlayer = $MusicPlayer

var tracks := [
	preload("res://assets/music/Banner_Over_the_Highland.mp3"),
	preload("res://assets/music/Beyond_the_Valley_Gate.mp3"),
	preload("res://assets/music/Victory_in_a_Paper_Sleeve.mp3"),
	preload("res://assets/music/The_Gilded_Ruckus.mp3")
]

var current_track := 0

var fake_messages := [
	"Try again.",
	"Nope, still not working",
	"Three time's a charm",
	"NG+ delayed due to budget constraints. Try again later.",
	"Click again, it might work.",
	"Connection lost.",
	"LOL, this ain't an online game, man.",
	"Ok, now you look silly.",
	"Two more and I'll start NG+.",
	"One more.",
	"You seriously fell for it?",
	"Ok, next one is the last",
	"    ",
	"Bye, bye!"
]

var fake_index := 0

var _tween = null

func _ready():
	fake_box.visible = false
	fake_box.modulate = Color(1, 1, 1, 0)
	fake_button.visible = false
	fake_button.pressed.connect(_on_fake_button_pressed)
	fake_message.visible = false
	scroll.visible = false
	skip_button.pressed.connect(_finish_credits)
	credits_text.bbcode_enabled = true
	music.finished.connect(_on_music_finished)
	credits_text.text = FileAccess.get_file_as_string("res://ui/credits.txt")

	play_track(0)
	credits_text.queue_redraw()
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().create_timer(0.1).timeout

	scroll.scroll_vertical = 0

	spacer.custom_minimum_size.y = scroll.size.y
	bottom_spacer.custom_minimum_size.y = scroll.size.y
	
	await get_tree().process_frame
	
	var content_height = (credits_text.get_content_height() + spacer.custom_minimum_size.y + bottom_spacer.custom_minimum_size.y)
	var viewport_height = scroll.size.y
	
	var distance := maxf(content_height - viewport_height, 0.0)
	
	if distance <= 0.0:
		return
		
	var duration := distance / scroll_speed
	
	scroll.visible = true
	
	_tween = create_tween()
	_tween.tween_property(scroll, "scroll_vertical", distance, duration)
	_tween.set_trans(Tween.TRANS_LINEAR)
	_tween.finished.connect(_credits_finished)
	
func _finish_credits() -> void:
	if _tween != null and _tween.is_running():
		_tween.kill()
	_tween = null
	SceneTransition.fade_transition_to_scene("res://ui/splash_screen.tscn")
	
func _credits_finished() -> void:
	fake_button.visible = true
	fake_message.visible = true
	fake_box.visible = true
	var tween = create_tween()
	tween.tween_property(fake_box, "modulate", Color(1, 1, 1), 1.5)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)

func _on_fake_button_pressed() -> void:
	if fake_index < fake_messages.size():
		fake_message.text = fake_messages[fake_index]
		fake_index += 1
	else:
		fake_message.text = "YOU'RE STILL HERE?"

func play_track(index: int):
	if index >= tracks.size():
		return
		
	current_track = index
	
	music.stop()
	music.stream = tracks[index]
	music.play()
	
func _on_music_finished():
	
	await get_tree().create_timer(4.0).timeout
	
	current_track += 1
	
	if current_track < tracks.size():
		play_track(current_track)
