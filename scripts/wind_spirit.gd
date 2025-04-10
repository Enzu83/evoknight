extends Area2D

const SPEED = 70

const DROP_RATE = 1
const HEAL_DROP_VALUE = 4
const EXP_DROP_VALUE = 8

const GAP_DISTANCE = 96 # from which distance from the target will the enemy cast the magic attack

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

@onready var hurtbox: CollisionShape2D = $Hurtbox
@onready var hurt_sound: AudioStreamPlayer = $HurtSound
@onready var hurt_invicibility_timer: Timer = $HurtInvicibilityTimer

@onready var death_sound: AudioStreamPlayer = $DeathSound

@onready var initial_wait_before_firing: Timer = $InitialWaitBeforeFiring
@onready var tornado: Area2D = $WindSpiritTornado

@onready var player: CharacterBody2D


var home_position: Vector2
var chase := false # enable chasing the player
var max_health := 8
var health := max_health
var strength = 2 # on collision

var hit := false # enemy stun if hit by an attack, can't chase during this period
var target_position := Vector2.ZERO
var can_fire = false

@export var flip_sprite := false

var drop := true

func _ready() -> void:
	add_to_group("enemies")
	can_fire = false
	animated_sprite.flip_h = flip_sprite
	tornado.strength = 2 * strength
	home_position = position

func _physics_process(delta: float) -> void:
	if Global.player != null:
		player = Global.player
	
	# go toward the target	
	if chase and player != null and tornado != null and not tornado.active:
		# move toward the middle of the target's hurtbox with an offset on x
		if not hit:
			target_position = player.position # target position
			target_position.y -= 2 # adjustement to be in the middle 
			
			# desired position is the same for y but the enemy keeps a space with the target position
			if position.x >= target_position.x:
				target_position.x += GAP_DISTANCE
			else:
				target_position.x -= GAP_DISTANCE
			
			# cast the spell if the positioning is correct
			if (position - target_position).length() < 16:
				if can_fire:
					if position.x > player.position.x:
						tornado.start("left")
					elif position.x < player.position.x:
						tornado.start("right")
			
			else:
				position = position.move_toward(target_position, SPEED * delta)
	
	# go back to home
	elif not chase:
		position = position.move_toward(home_position, SPEED * delta)
		
	# flip the sprite to match the direction
	if not chase and (position - home_position).length() > 0:
		if position.x < home_position.x:
			animated_sprite.flip_h = false
		elif position.x > home_position.x:
			animated_sprite.flip_h = true
	else:
		if position.x < player.position.x:
			animated_sprite.flip_h = false
		elif position.x > player.position.x:
			animated_sprite.flip_h = true

func _on_area_entered(area: Area2D) -> void:
	var body := area.get_parent() # get the player

	# hurt the player
	if body == player and player.is_hurtable():
		body.hurt(strength)

func hurt(damage: int, _attack: Area2D) -> bool:
	if health > damage:
		health -= damage
		hurt_sound.play()
		hurtbox.set_deferred("disabled", true)
		hurt_invicibility_timer.start()
		animation_player.play("hit")
		hit = true
	else:
		fainted()
	
	return true

func fainted() -> void:
	if animation_player.current_animation != "death":
		health = 0
		animation_player.play("death")
		death_sound.play()
		tornado.queue_free()
		
		# chance to drop heart/exp
		if drop:
			Global.create_drop(DROP_RATE, HEAL_DROP_VALUE, EXP_DROP_VALUE, position, Vector2.ZERO)

func get_middle_position() -> Vector2:
	return position - Vector2(0, hurtbox.shape.get_rect().size.y)

func _on_detector_body_entered(body: Node2D) -> void:
	if body == player:
		chase = true
		initial_wait_before_firing.start()

func _on_detector_body_exited(body: Node2D) -> void:
	if body == player:
		chase = false
		can_fire = false

func _on_hurt_invicibility_timer_timeout() -> void:
	hit = false
	hurtbox.set_deferred("disabled", false)
	animation_player.play("RESET")

func _on_initial_wait_before_firing_timeout() -> void:
	can_fire = true
