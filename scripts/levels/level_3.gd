extends Node2D

@onready var hud: CanvasLayer = %HUD
@onready var player: Player = %Player

func _ready() -> void:
	Global.current_level = 4
	Global.player = player
	hud.display_collectable = true
	hud.display_boss = false

	if Global.respawn_position != Vector2.INF:
		player.position = Global.respawn_position
