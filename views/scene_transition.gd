## Scene transition between one view and the next, set up as an AutoLoad
extends CanvasLayer

const CreditsScene := preload("res://views/credits.tscn")
const GameSceneGd := preload("res://views/game_scene.gd")
const GameScene := preload("res://views/game_scene.tscn")
const SelectMenu := preload("res://views/select_menu.tscn")
const StartDaily := preload("res://views/start_daily.tscn")
const TopicSelect := preload("res://views/topic_select.tscn")

onready var _anim_player := $Control/AnimationPlayer
onready var _texture_rect := $Control/texture_rect
onready var _audio_a := $audio_a
onready var _audio_b := $audio_b

var current_scene: Node
var is_menu_screen = false


func _ready():
	# No need for an initial animation to fade in.
	# _anim_player.play_backwards("fade")
	_texture_rect.visible = false
	
	var res = _anim_player.connect("animation_finished", self, "_on_animation_finished")
	if res != OK:
		push_error("Failed to connect animation player")


func _unhandled_input(event):
	if event is InputEventKey and Input.is_action_just_pressed("ui_cancel"):
		if is_menu_screen:
			return # Already top level.
		# print_debug("TODO: popup option to exit game if that's the mode")
		load_menu_select()


func _load_new_scene(scn):
	run_random_audio()
	#_anim_player.seek(0, true) # Make sure at start of anim to begin with.
	# First, capture the current viewport
	var img = get_viewport().get_texture().get_data()
	img.flip_y()
	img.lock()
	var tex := ImageTexture.new()
	tex.create_from_image(img)
	_texture_rect.texture = tex
	_texture_rect.visible = true
	
	# Added while trying to ensure export stability.
	if is_instance_valid(current_scene):
		current_scene.queue_free() # No longer needed.
	current_scene = scn.instance()
	is_menu_screen = false # Greedy, revert back if untrue in load_menu_select.
	get_tree().get_root().add_child(current_scene)
	get_tree().set_current_scene(current_scene)
	#get_tree().get_root().call_deferred("add_child", current_scene)
	#get_tree().call_deferred("set_current_scene", current_scene)


func load_menu_select() -> void:
	_load_new_scene(SelectMenu)
	_anim_player.stop()
	_anim_player.play("next_page")


func load_start_daily() -> void:
	_load_new_scene(StartDaily)
	_anim_player.stop()
	_anim_player.play("next_page")


func start_daily_puzzle(date) -> void:
	_load_new_scene(GameScene)
	current_scene.source = GameSceneGd.ScrambleSource.DAILY_ARTICLE
	current_scene.daily_artical_date = date
	current_scene.load_scramble()
	_anim_player.stop()
	_anim_player.play("next_page")


func start_tutorial_scene(index:int) -> void:
	_load_new_scene(GameScene)
	current_scene.source = GameSceneGd.ScrambleSource.TUTORIAL
	current_scene.tutorial_index = index
	current_scene.load_scramble()
	_anim_player.stop()
	_anim_player.play("next_page")


func load_topic_select_scene() -> void:
	_load_new_scene(TopicSelect)
	_anim_player.stop()
	_anim_player.play("next_page")


func start_topic_scene(topic:String, country:String, language:String) -> void:
	_load_new_scene(GameScene)
	current_scene.source = GameSceneGd.ScrambleSource.TOPIC_ARTICLE
	current_scene.daily_article_topic = topic
	current_scene.daily_article_country = country 
	current_scene.daily_article_language = language
	current_scene.load_scramble()
	_anim_player.stop()
	_anim_player.play("next_page")


func show_credits():
	_load_new_scene(CreditsScene)
	_anim_player.stop()
	_anim_player.play("next_page")
	

func _on_animation_finished(_anim_name) -> void:
	if not _texture_rect.visible:
		return # Bypass to avoid recursive backwards run
	#_anim_player.disconnect("animation_finished", self, "_on_animation_finished")
	#print("Finished animation, start the game scene")
	_texture_rect.visible = false
	# To put back at start - not visible, avoids jitter on next animation run.
	_anim_player.play_backwards("next_page")


func run_random_audio():
	if not Cache.sound_on:
		return
	if randf() > 0.5:
		_audio_a.pitch_scale = 1 + randf() * 0.5
		_audio_a.play()
	else:
		_audio_b.pitch_scale = 1 + randf() * 0.5
		_audio_b.play()
