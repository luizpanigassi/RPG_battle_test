extends Control
class_name HolyMcguffinDialog

signal holy_accepted
signal holy_declined
signal holy_closed

@onready var title_label: Label = $CenterContainer/PanelContainer/VBoxContainer/TitleLabel
@onready var body_label: RichTextLabel = $CenterContainer/PanelContainer/VBoxContainer/DialogLabel
@onready var accept_button: Button = $CenterContainer/PanelContainer/VBoxContainer/HBoxContainer/ButtonYes
@onready var decline_button: Button = $CenterContainer/PanelContainer/VBoxContainer/HBoxContainer/ButtonNo


func _ready():
	hide()
	accept_button.pressed.connect(_on_yes_pressed)
	decline_button.pressed.connect(_on_no_pressed)

func open_holy_dialogue(title_text: String, body_text: String, yes_text: String = "We need all the power we can get!", no_text: String = "Nah, I'm strong enough on my own") -> void:
	title_label.text = title_text
	body_label.text = body_text
	accept_button.text = yes_text
	decline_button.text = no_text
	show()
	accept_button.grab_focus()

func close_dialogue():
	hide()
	holy_closed.emit()

func _on_yes_pressed():
	holy_accepted.emit()
	close_dialogue()

func _on_no_pressed():
	holy_declined.emit()
	close_dialogue()
