## Unit test for sequences of screens.
extends WAT.Test

const GameSceneGd := preload("res://views/game_scene.gd")
const SelectMenu = preload("res://views/select_menu.gd")


func title() -> String:
	return "Given the select screen"


func test_open_tutorial() -> void:
	describe("Open the tutorial scene correctly")
	var select_menu = SelectMenu.new()
	Cache.tutorial_stage = 1
	select_menu._on_tutorial_pressed()
	asserts.is_equal(Cache.tutorial_stage, 1, "Tutorial state remains the same")
	
	asserts.is_equal(SceneTransition.current_scene.source,
					GameSceneGd.ScrambleSource.TUTORIAL,
					"The expected tutorial scene is open")
	
	Cache.tutorial_stage = 4
	select_menu._on_tutorial_pressed()
	asserts.is_equal(Cache.tutorial_stage, 0, "Tutorial state reset to valid")


func test_play_today() -> void:
	describe("Open the daily puzzle scene")
	var select_menu = SelectMenu.new()
	select_menu._on_play_today_pressed()
	
	var start_daily = get_node("/root/start_daily")
	asserts.is_not_null(start_daily.play_another)
	# Could test:
	# Assert that first time opened within day, shows "start now";
	# but if already played, then in a disabled state.
