extends Control

@export var scroll_speed := 30.0

@onready var scroll: ScrollContainer = $ScrollContainer
@onready var skip_button: Button = $SkipButton
@onready var credits_text: RichTextLabel = $ScrollContainer/VBoxContainer/CreditsText
@onready var spacer: Control = $ScrollContainer/VBoxContainer/TopSpacer
@onready var bottom_spacer: Control = $ScrollContainer/VBoxContainer/BottomSpacer
@onready var fake_button: Button = $RewardButton
@onready var fake_message: Label = $RewardMessage

var fake_messages := [
	"Try again.",
	"Nope, still not working",
	"Three time's a charm",
	"NG+ delayed due to budget constraints. Try again later.",
	
]

var _tween = null

func _ready():
	fake_button.visible = false
	fake_button.pressed.connect(_on_fake_button_pressed)
	scroll.visible = false
	skip_button.pressed.connect(_finish_credits)
	credits_text.bbcode_enabled = true
	credits_text.text = FileAccess.get_file_as_string("res://ui/credits.txt")

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
	_tween.finished.connect(_finish_credits)
	
func _finish_credits() -> void:
	if _tween != null and _tween.is_running():
		_tween.kill()
	_tween = null
	SceneTransition.fade_transition_to_scene("res://ui/splash_screen.tscn")
	
func _on_fake_button_pressed() -> void:
	fake_button.text = "Wow, you actually clicked it."
	
	await get_tree().create_timer(2.0).timeout
