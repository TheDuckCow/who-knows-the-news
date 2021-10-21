## Scene transition between one view and the next, set up as an AutoLoad
extends CanvasLayer

const GameSceneGd := preload("res://views/game_scene.gd")
const GameScene := preload("res://views/game_scene.tscn")
const SelectMenu := preload("res://views/select_menu.tscn")

onready var _anim_player := $Control/AnimationPlayer
onready var _texture_rect := $Control/texture_rect

var current_scene: Node


func _ready():
	#var root = get_tree().get_root()
	# current_scene = root.get_child(root.get_child_count() - 1)
	# No need for an initial animation to fade in.
	# _anim_player.play_backwards("fade")
	_texture_rect.visible = false


func _process(_delta):
	if Input.is_action_just_pressed("ui_cancel"):
		print_debug("TODO: popup option to exit game if that's the mode")
		load_menu_select()


func _load_new_scene(scn):
	assert(_anim_player.connect("animation_finished", self, "_on_animation_finished") == OK)
	#_anim_player.seek(0, true) # Make sure at start of anim to begin with.
	# First, capture the current viewport
	var img = get_viewport().get_texture().get_data()
	img.flip_y()
	img.lock()
	var tex := ImageTexture.new()
	tex.create_from_image(img)
	_texture_rect.texture = tex
	_texture_rect.visible = true
	
	current_scene.queue_free() # No longer needed.
	print_debug(scn)
	current_scene = scn.instance()
	get_tree().get_root().add_child(current_scene)
	get_tree().set_current_scene(current_scene)
	

func load_menu_select() -> void:
	print("Load menu select scene")
	_load_new_scene(SelectMenu)
	_anim_player.play("next_page")


func start_tutorial_scene(index:int) -> void:
	_load_new_scene(GameScene)
	
	current_scene.source = GameSceneGd.ScrambleSource.TUTORIAL
	current_scene.tutorial_index = index
	
	_anim_player.play("next_page")
	current_scene.load_scramble()


func _on_animation_finished(_anim_name) -> void:
	_anim_player.disconnect("animation_finished", self, "_on_animation_finished")
	print("Finished animation, start the game scene")
	_texture_rect.visible = false
	# To put back at start, not visible but avoids initisl jitter.
	_anim_player.play_backwards("next_page")

