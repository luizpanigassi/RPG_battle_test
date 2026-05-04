class_name StoryIntro
extends Control


@onready var texture_rect: TextureRect = $ColorRect/TextureRect
@onready var label: Label = $Control/CenterContainer/Label

var scenes_data: Array = [
	{
		"texture": "res://assets/ui/story_1.png",
		"text": "Times are grim. The evil lord rules with an iron fist, and people are suffering.",
		"display_time": 3.0
	},
	{
		"texture": "res://assets/ui/story_2.png",
		"text": "But one man can save us all, if he is brave enough",
		"display_time": 3.0
	},
	{
		"texture": "res://assets/ui/story_3.png",
		"text": "And a woman will help him find what they need to conquer all evil",
		"display_time": 3.0
	},
	{
		"texture": "",
		"text": "They will be known only as...",
		"display_time": 3.0
	}
]

func _ready():
	label.modulate.a = 0.0
	await SceneTransition.fade_in()
	await play_intro()
	
func play_intro():
	for scene_info in scenes_data:
		await play_single_scene(scene_info)
	
	await SceneTransition.fade_transition_to_scene("res://ui/splash_screen.tscn")
	
func play_single_scene(scene_info: Dictionary):
	
	if scene_info.get("texture", "") != "":
		await fade_out_texture()
		texture_rect.texture = load(scene_info["texture"])
		await fade_in_texture()
	else:
		await fade_out_texture()
		texture_rect.modulate.a = 0.0
	
	label.text = scene_info["text"]
	await  fade_in_label()
	
	await get_tree().create_timer(scene_info["display_time"]).timeout
	
	await fade_out_label()
	
	await get_tree().create_timer(0.5).timeout
	
func fade_in_label():
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	var color = label.modulate
	color.a = 1.0
	tween.tween_property(label, "modulate", color, 0.8)
	
	await tween.finished
	
func fade_out_label():
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN)
	var color = label.modulate
	color.a = 0.0
	tween.tween_property(label, "modulate", color, 0.8)
	await tween.finished

func fade_in_texture():
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN)
	var color = texture_rect.modulate
	color.a = 1.0
	tween.tween_property(texture_rect, "modulate", color, 0.8)
	await tween.finished

func fade_out_texture():
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN)
	var color = texture_rect.modulate
	color.a = 0.0
	tween.tween_property(texture_rect, "modulate", color, 0.8)
	await tween.finished
