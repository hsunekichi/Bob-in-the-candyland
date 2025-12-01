extends Node

@onready var player: AudioStreamPlayer = AudioStreamPlayer.new()

const MENU_MUSIC = preload("res://Art/Music/Donut Dreams.mp3")
const GAME_MUSIC_EASY = preload("res://Art/Music/The Donut Dash.mp3")
const GAME_MUSIC_MEDIUM = preload("res://Art/Music/Tricera-Dash.mp3")
const GAME_MUSIC_HARD = preload("res://Art/Music/Candy Escape.mp3")

func _ready() -> void:
	add_child(player)
	player.autoplay = false
	player.finished.connect(_on_player_finished)
	player.volume_db = -25

func _on_player_finished() -> void:
	player.play()

func play_menu_music():
	if player.stream != MENU_MUSIC:
		player.stream = MENU_MUSIC
		player.play()

func play_game_music():
	var difficulty = World.get_difficulty()
	
	print(difficulty)
	
	if difficulty == "easy":
		if player.stream != GAME_MUSIC_EASY:
			player.stream = GAME_MUSIC_EASY
			player.play()
	elif difficulty == "medium":
		if player.stream != GAME_MUSIC_MEDIUM:
			player.stream = GAME_MUSIC_MEDIUM
			player.play()
	elif difficulty == "hard":
		if player.stream != GAME_MUSIC_HARD:
			player.stream = GAME_MUSIC_HARD
			player.play()
