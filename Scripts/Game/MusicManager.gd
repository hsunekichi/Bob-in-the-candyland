extends Node

@onready var player: AudioStreamPlayer = AudioStreamPlayer.new()

const MENU_MUSIC = preload("res://Art/Music/Donut Dreams.mp3")
const GAME_MUSIC = preload("res://Art/Music/The Donut Dash.mp3")

func _ready() -> void:
	add_child(player)
	player.autoplay = false
	player.finished.connect(_on_player_finished)

func _on_player_finished() -> void:
	player.play()

func play_menu_music():
	if player.stream != MENU_MUSIC:
		player.stream = MENU_MUSIC
		player.play()

func play_game_music():
	if player.stream != GAME_MUSIC:
		player.stream = GAME_MUSIC
		player.play()
