extends Control

const SELECT_SCREEN = "res://views/select_menu.tscn"

onready var next_button = get_node("anim_control/Control/HBoxContainer/next_button")


func _ready():
	next_button.grab_focus()


func _on_menu_pressed():
	SceneTransition.load_menu_select()
	#assert(get_tree().change_scene(SELECT_SCREEN) == OK)


func _on_leaderboard_name_pressed():
	pass
