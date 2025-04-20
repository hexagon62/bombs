class_name LevelInfoPanel
extends Panel


@export var star_empty_texture: Texture2D
@export var star_full_texture: Texture2D

var level_name := "":
	get: return level_name
	set(value):
		level_name = value
		name_label.text = level_name
var preview_texture: Texture2D:
	get: return preview_texture
	set(value):
		preview_texture = value
		preview.texture = preview_texture
var star := false:
	get: return star
	set(value):
		star = value
		if star:
			star_display.texture = star_full_texture
		else:
			star_display.texture = star_empty_texture
var best := -1:
	get: return best
	set(value):
		best = value
		if best < 0:
			best_score_label.text = "Best: N/A"
		else:
			best_score_label.text = "Best: %d" % best
var contents_visible:
	get: return contents.visible
	set(value):
		contents.visible = value

@onready var contents: MarginContainer = $Contents
@onready var name_label: Label = %NameLabel
@onready var preview: TextureRect = %Preview
@onready var best_score_label: Label = %BestScoreLabel
@onready var star_display: TextureRect = %StarDisplay
