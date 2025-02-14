extends Area2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	Global.total_stars += 1

func _on_body_entered(_body: Node2D) -> void:
	Global.stars += 1
	animation_player.play("pickup")
