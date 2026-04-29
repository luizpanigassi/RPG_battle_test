extends Control
class_name BadguyDialog

signal boss_accepted
signal boss_declined
signal boss_closed

@onready var boss_title_label: Label = $CenterContainer/PanelContainer/VBoxContainer/TitleLabel
@onready var boss_body_label: RichTextLabel = $CenterContainer/PanelContainer/VBoxContainer/DialogLabel
@onready var boss_accept_button: Button = $CenterContainer/PanelContainer/VBoxContainer/HBoxContainer/ButtonYes
@onready var boss_decline_button: Button = $CenterContainer/PanelContainer/VBoxContainer/HBoxContainer/ButtonNo

func _ready():
	hide()
	boss_accept_button.pressed.connect(_on_boss_yes_pressed)
	boss_decline_button.pressed.connect(_on_boss_no_pressed)

func boss_dialog_open(title_text: String, body_text: String, boss_yes_text: String = "Be ready, evil lord!", boss_no_text: String = "No, I'm a little chicken") -> void:
	boss_title_label.text = title_text
	boss_body_label.text = body_text
	boss_accept_button.text = boss_yes_text
	boss_decline_button.text = boss_no_text
	show()
	boss_accept_button.grab_focus()

func boss_close_dialog():
	hide()
	boss_closed.emit()

func _on_boss_yes_pressed():
	boss_accepted.emit()
	boss_close_dialog()

func _on_boss_no_pressed():
	boss_declined.emit()
	boss_close_dialog()
