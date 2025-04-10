extends Area2D

@onready var music: AudioStreamPlayer = %Music
@onready var boss_music: AudioStreamPlayer = %BossMusic

@onready var big_bat: Area2D = $BigBat
@onready var fight_trigger: CollisionShape2D = $FightTrigger
@onready var start_timer: Timer = $StartTimer

@onready var left_bat_spawner: Node2D = $LeftBatSpawner
@onready var right_bat_spawner: Node2D = $RightBatSpawner


@onready var player: Player = %Player
@onready var camera: Camera2D = %Camera

@onready var large_platform: AnimatableBody2D = $LargePlatform

const UPGRADE = preload("res://scenes/items/upgrade.tscn")

func _physics_process(_delta: float) -> void:
	# spawn the mana orb of the boss is defeated
	if not is_instance_valid(big_bat) and not Global.big_bat_defeated:
		camera.limit_bottom = -32
		boss_music.stop()
		music.play()
		Global.big_bat_defeated = true
		left_bat_spawner.stop_spawn()
		right_bat_spawner.stop_spawn()
		get_parent().add_child(UPGRADE.instantiate().init(0, Vector2(2720, -300), Vector2(2720, -320))) # spell
	
	if Global.big_bat_defeated and player.mana_enabled:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	# start fight
	if body == player \
	and big_bat.state == big_bat.State.Sleep \
	and not Global.big_bat_defeated:
		camera.limit_bottom = -216
		start_timer.start()
		player.state = player.State.Stop
		player.velocity.x = 0
		player.direction = 0
		player.phantom_cooldown.stop()
		left_bat_spawner.start_spawn()
		right_bat_spawner.start_spawn()
		music.stop()

func _on_start_timer_timeout() -> void:
	big_bat.animation_player.play("wake_up")
