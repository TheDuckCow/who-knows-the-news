extends Control

const GAME_SCENE = "res://views/game_scene.tscn"


func _ready():
	pass


func _on_play_today_pressed():
	assert(get_tree().change_scene(GAME_SCENE) == OK)
