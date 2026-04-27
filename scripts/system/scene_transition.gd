extends CanvasLayer

var fade_rect
var is_transitioning := false

func _ready():
	layer = 100

	fade_rect = ColorRect.new()
	fade_rect.color = Color(0,0,0,0)
	fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fade_rect)
	
func flash_and_fade():
	fade_rect.color = Color(1, 1, 1, 0)
	var flash_tween = create_tween()
	flash_tween.tween_property(fade_rect, "color:a", 1.0, 0.12)
	flash_tween.tween_property(fade_rect, "color:a", 0.0, 0.10)
	await flash_tween.finished

	fade_rect.color = Color(0, 0, 0, 0)
	var fade_tween = create_tween()
	fade_tween.tween_property(fade_rect, "color:a", 1.0, 0.25)
	await fade_tween.finished

func fade_out():
	fade_rect.color = Color(0,0,0,0)
	
	var tween = create_tween()
	tween.tween_property(fade_rect, "color:a", 1.0, 0.5)
	
	await tween.finished
	
func fade_in():
	fade_rect.color = Color(0,0,0,1)
	var tween = create_tween()
	tween.tween_property(fade_rect, "color:a", 0.0, 1.5)
	await  tween.finished

func transition_to_scene(scene_path: String):
	if is_transitioning:
		return

	is_transitioning = true
	await flash_and_fade()
	get_tree().change_scene_to_file(scene_path)
	await get_tree().process_frame
	await fade_in()
	is_transitioning = false
