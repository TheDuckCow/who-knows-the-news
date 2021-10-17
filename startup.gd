extends Node2D

const SELECT_SCREEN = "res://views/select_menu.tscn"

func _ready():
	assert(get_tree().change_scene(SELECT_SCREEN) == OK)
