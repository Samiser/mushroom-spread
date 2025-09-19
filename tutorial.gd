extends Control
class_name Tutorial

@export var tutorial_panel: Panel
@export var title_label: RichTextLabel
@export var text_label: RichTextLabel
@export var next_button: Button
@export var ok_button: Button

var current_step = -1

class TutorialItem:
	var title: String
	var text: String
	var has_next_button: bool
	var has_ok_button: bool
	var panel_position: Vector2
	
	func _init(item_title: String, item_text: String, next_button: bool = false, ok_button: bool = false, pos: Vector2 = Vector2(189., 115.5)) -> void:
		title = item_title
		text = item_text
		has_next_button = next_button
		has_ok_button = ok_button
		panel_position = pos

var tutorial_script: Array[TutorialItem] = [
	TutorialItem.new(
		"Welcome to [color=#ffe6c9]Ambergrove[/color]!",
		"You are in control of a mushroom colony, and rely on expansion of your population to survive and thrive!",
		true
	),
	TutorialItem.new(
		"Getting Around",
		"Drag with left click to move around, and with right click to rotate the camera. Scroll to zoom in and out.",
		true
	),
	TutorialItem.new(
		"First Fungus",
		"Place your starter mushroom on any of the highlighted tiles",
		false,
		false,
		Vector2(10, 115.5)
	),
	TutorialItem.new(
		"Spreading Spores",
		"Great! Once a mushroom is fully grown, it can be clicked to spread spores. They will settle nearby, creating new mushrooms.",
		true
	),
	TutorialItem.new(
		"Spreading Spores",
		"The mushroom you choose to spread from is how you can affect where your colony expands to.\nGive it a try!",
		false,
		false,
		Vector2(10, 115.5)
	),
	TutorialItem.new(
		"Reading the Forest",
		"Your shrooms prefers certain tiles\n• [color=#63C74D]Liked[/color] tiles improve growth.\n• [color=#DC4C46]Disliked[/color] tiles weaken the colony.",
		true
	),
	TutorialItem.new(
		"Reading the Forest",
		"You can check what your colony likes and dislikes by ???. Spread carefully to ensure your colony thrives!",
		false,
		true
	),
	TutorialItem.new(
		"Night falls",
		"Once you've hit your current capacity, you can end the day to let your new mushrooms settle in. You'll also see a report showing how your colony is getting on.",
		false,
		false
	),
]

func _ready() -> void:
	next_button.pressed.connect(next)
	ok_button.pressed.connect(func() -> void: tutorial_panel.visible = false)

func get_current_title() -> String:
	if tutorial_script.size() > current_step:
		return tutorial_script[current_step].title
	else:
		return ""

func _show_tutorial(step: int) -> void:
	var item: TutorialItem = tutorial_script[step]

	title_label.text = item.title
	text_label.text = item.text
	next_button.visible = item.has_next_button
	ok_button.visible = item.has_ok_button
	tutorial_panel.position = item.panel_position
	
	tutorial_panel.visible = true

func next() -> void:
	current_step += 1
	if tutorial_script.size() > current_step:
		_show_tutorial(current_step)
	else:
		tutorial_panel.visible = false
