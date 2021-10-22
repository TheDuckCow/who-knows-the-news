extends Node2D

const SELECT_SCREEN = preload("res://views/select_menu.tscn")

func _ready():
	assert(get_tree().change_scene_to(SELECT_SCREEN) == OK)
	#pass
