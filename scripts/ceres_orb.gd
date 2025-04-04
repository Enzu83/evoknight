extends Area2D

const SPEED = 300
const STRENGTH = 7

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var slash_sound: AudioStreamPlayer = $SlashSound

@onready var initial_wait_timer: Timer = $InitialWaitTimer
@onready var wait_timer: Timer = $WaitTimer
@onready var duration: Timer = $Duration

@onready var ceres: CharacterBody2D = $".."

@onready var target_icon: AnimatedSprite2D = $TargetIcon
@onready var target_icon_2: AnimatedSprite2D = $TargetIcon2

var direction: Vector2
var current_speed: Vector2

var active := false
var fire := false

var initial_position: Vector2
var target_position: Vector2
var initial_wait_time: float
var play_sound: bool

var second_target_position := Vector2.ZERO

func init(initial_position_: Vector2, target_position_: Vector2, initial_wait_time_: float = 0.0, play_sound_: bool = true) -> Node2D:
	initial_position = initial_position_
	target_position = target_position_
	initial_wait_time = initial_wait_time_
	play_sound = play_sound_
	
	return self

func second_target(second_target_position_: Vector2) -> Node2D:
	second_target_position = second_target_position_
	
	return self

func _ready() -> void:
	position = initial_position
	target_icon.position = target_position
	initial_wait_timer.start(initial_wait_time + 0.01)

func _physics_process(delta: float) -> void:
	if active \
	and not fire:
		var orientation := (target_icon.position - position).normalized()
		rotation += atan2(orientation.y, orientation.x)
		direction = orientation
		
		duration.start()
		fire = true
		animation_player.play("shoot")
		
		if play_sound:
			slash_sound.play()
		
	# move toward the target
	if fire:
		current_speed.x = move_toward(current_speed.x, direction.x * SPEED, abs(direction.x) * 20)
		current_speed.y = move_toward(current_speed.y, direction.y * SPEED, abs(direction.y) * 20)
		
		position += current_speed * delta
	
	# stop attacking if ceres is defeated
	if ceres.state == ceres.State.Defeated:
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	var body := area.get_parent() # get the player

	# hurt the player
	if body == ceres.player and ceres.player.is_hurtable():
		body.hurt(STRENGTH)

func _on_duration_timeout() -> void:
	animation_player.play("fade_out")

func _on_wait_timer_timeout() -> void:
	# can shoot
	active = true


func _on_initial_wait_timer_timeout() -> void:
	target_icon.visible = true
	
	if second_target_position != Vector2.ZERO:
		target_icon_2.position = second_target_position
		target_icon_2.visible = true
	
	wait_timer.start()
