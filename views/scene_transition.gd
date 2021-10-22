## Scene transition between one view and the next, set up as an AutoLoad
extends CanvasLayer

const GameSceneGd := preload("res://views/game_scene.gd")
const GameScene := preload("res://views/game_scene.tscn")
const SelectMenu := preload("res://views/select_menu.tscn")
const TopicSelect := preload("res://views/topic_select.tscn")

onready var _anim_player := $Control/AnimationPlayer
onready var _texture_rect := $Control/texture_rect
onready var _audio_a := $audio_a
onready var _audio_b := $audio_b

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
	run_random_audio()
	var res = _anim_player.connect("animation_finished", self, "_on_animation_finished")
	if res != OK:
		push_error("Failed to connect animation player")
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
	current_scene.load_scramble()
	_anim_player.play("next_page")


func load_topic_select_scene() -> void:
	_load_new_scene(TopicSelect)
	_anim_player.play("next_page")


func start_topic_scene(topic:String, country:String, language:String) -> void:
	_load_new_scene(GameScene)
	current_scene.source = GameSceneGd.ScrambleSource.TOPIC_ARTICLE
	current_scene.daily_article_topic = topic
	current_scene.daily_article_country = country 
	current_scene.daily_article_language = language
	current_scene.load_scramble()
	_anim_player.play("next_page")


func _on_animation_finished(_anim_name) -> void:
	_anim_player.disconnect("animation_finished", self, "_on_animation_finished")
	print("Finished animation, start the game scene")
	_texture_rect.visible = false
	# To put back at start - not visible, avoids jitter on next animation run.
	_anim_player.play_backwards("next_page")


func run_random_audio():
	if randf() > 0.5:
		_audio_a.pitch_scale = 1 + randf() * 0.5
		_audio_a.play()
	else:
		_audio_b.pitch_scale = 1 + randf() * 0.5
		_audio_b.play()
