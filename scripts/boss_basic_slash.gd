extends Area2D

const STRENGTH = 4

@onready var sprite: Sprite2D = $Sprite

@onready var animation_player: AnimationPlayer = $AnimationPlayer

@onready var boss: CharacterBody2D = $".."

var active: bool = false
var direction: String

func reset() -> void:
	active = false
	animation_player.play("RESET")

func start(orientation: String) -> void:
	direction = orientation
	active = true
	animation_player.play(orientation)
	
	# flip horizontally the attack to match the player's direction
	if (orientation == "up" and boss.sprite.flip_h) \
	or (orientation == "down" and not boss.sprite.flip_h):
		scale.x = -1

func _on_area_entered(area: Area2D) -> void:
	var body := area.get_parent() # get the player

	# hurt the player
	if body == boss.player and boss.player.is_hurtable():
		body.hurt(STRENGTH)
		
		# make player bounce on the enemy
		if animation_player.current_animation == "down":
			boss.handle_bounce()


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name != "RESET":
		animation_player.play("RESET")
