extends Control

class ReportData:
	var old_mushroom_data: MushroomData
	var new_mushroom_data: MushroomData
	


@export var summary_tile_rating: RichTextLabel
@export var summary_colony_size: RichTextLabel
@export var summary_capacity: RichTextLabel

@export var tiles_likes: RichTextLabel
@export var tiles_dislikes: RichTextLabel
@export var tiles_liked: RichTextLabel
@export var tiles_neutral: RichTextLabel
@export var tiles_disliked: RichTextLabel
@export var tiles_rating: RichTextLabel

@export var culls_manual: RichTextLabel
@export var culls_insect: RichTextLabel
@export var culls_animals: RichTextLabel
@export var culls_total: RichTextLabel

func update_report
