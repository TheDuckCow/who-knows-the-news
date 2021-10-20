extends Control

const SELECT_SCREEN = "res://views/select_menu.tscn"

onready var leader_button = get_node("anim_control/Control/HBoxContainer/leaderboard_name")

func _ready():
	leader_button.grab_focus()


func _on_menu_pressed():
	assert(get_tree().change_scene(SELECT_SCREEN) == OK)


func _on_leaderboard_name_pressed():
	pass
