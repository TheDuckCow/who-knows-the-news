extends Node2D

const SELECT_SCREEN = preload("res://views/select_menu.tscn")

func _ready():
	var res = get_tree().change_scene_to(SELECT_SCREEN)
	if res != OK:
		push_error("Failed to connect change scene")
