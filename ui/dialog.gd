extends Control
class_name DialogScreen

signal accepted
signal declined
signal closed

@onready var title_label: Label = $CenterContainer/PanelContainer/VBoxContainer/TitleLabel
@onready var body_label: RichTextLabel = $CenterContainer/PanelContainer/VBoxContainer/DialogLabel
@onready var accept_button: Button = $CenterContainer/PanelContainer/VBoxContainer/HBoxContainer/ButtonYes
@onready var decline_button: Button = $CenterContainer/PanelContainer/VBoxContainer/HBoxContainer/ButtonNo

func _ready():
	hide()
	accept_button.pressed.connect(_on_yes_pressed)
	decline_button.pressed.connect(_on_no_pressed)

func open_dialogue(title_text: String, body_text: String, yes_text: String = "Yes!", no_text: String = "No.") -> void:
	title_label.text = title_text
	body_label.text = body_text
	accept_button.text = yes_text
	decline_button.text = no_text
	show()
	accept_button.grab_focus()

func close_dialogue():
	hide()
	closed.emit()

func _on_yes_pressed():
	accepted.emit()
	close_dialogue()

func _on_no_pressed():
	declined.emit()
	close_dialogue()
