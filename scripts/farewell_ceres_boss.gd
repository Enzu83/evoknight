extends Area2D

@onready var hud: CanvasLayer = %HUD

@onready var player: Player = %Player
@onready var camera: Camera2D = %Camera

@onready var music: AudioStreamPlayer = %Music
@onready var boss_music: AudioStreamPlayer = %BossMusic

@onready var farewell_ceres: CharacterBody2D = $FarewellCeres

@onready var trigger: CollisionShape2D = $Trigger
@onready var fake_wall: StaticBody2D = $FakeWall

@onready var lower_left_platform: AnimatableBody2D = $LowerLeftPlatform
@onready var lower_middle_left_platform: AnimatableBody2D = $LowerMiddleLeftPlatform
@onready var lower_middle_right_platform: AnimatableBody2D = $LowerMiddleRightPlatform
@onready var lower_right_platform: AnimatableBody2D = $LowerRightPlatform
@onready var middle_left_platform: AnimatableBody2D = $MiddleLeftPlatform
@onready var middle_right_platform: AnimatableBody2D = $MiddleRightPlatform
@onready var upper_left_platform: AnimatableBody2D = $UpperLeftPlatform
@onready var upper_right_platform: AnimatableBody2D = $UpperRightPlatform

@onready var mob_list: Node2D = $MobList

@onready var wave_phase_cooldown: Timer = $WavePhaseCooldown

@onready var dark_cherry_spawn_timer: Timer = $DarkCherrySpawnTimer

var camera_limit_left: int
var camera_limit_right: int
var camera_limit_top: int
var camera_limit_bottom: int

const MOB_SPAWNER = preload("res://scenes/other/mob_spawner.tscn")
var dark_cherry_scene: Resource = preload("res://scenes/chars/dark_cherry.tscn")
var dark_cherry_spawn_counter := 0
var dark_cherry_next_position := "right"
var can_spawn_dark_cherry := false

var state := 0 # odd: classic fight, even: wave fight
var wave_phase := 0
var can_change_wave_phase := false

# {
#	state (2, 4, 6): {
# 		wave_phase (0, 1, 2, 3): [spawns...]
# 	}
# }
var wave_spawn = {
	# first wave
	2: {
		0: [
			["bat", Vector2(15710, -1580), true],
			["bat", Vector2(15866, -1580), false, 0, 0.1],
			["big_bat", Vector2(15788, -1604), false, 20, 0.5],
		],
	
		1: [
			["wind_spirit", Vector2(15710, -1600), true],
			["wind_spirit", Vector2(15916, -1600), false],
		],
	},
	
	# second wave
	4: {
		0: [
			["bat", Vector2(15710, -1600), true],
			["bat", Vector2(15916, -1600), false],
		],
	
		1: [
			["wind_spirit", Vector2(15710, -1600), true],
			["wind_spirit", Vector2(15916, -1600), false],
		],
	},
	
	# third wave
	6: {
		0: [
			["bat", Vector2(15710, -1600), true],
			["bat", Vector2(15916, -1600), false],
		],
	
		1: [
			["wind_spirit", Vector2(15710, -1600), true],
			["wind_spirit", Vector2(15916, -1600), false],
		],
	},
}

func _physics_process(_delta: float) -> void:
	if state > 0:
		# update hud current health bar
		hud.current_boss_health_bar = farewell_ceres.health_bar
		
		update_state()
		handle_enemy_wave()
		
		#print(state, ", ", wave_phase, ", ", dark_cherry_spawn_counter, ", ", can_change_wave_phase)

func update_state() -> void:
	# advance to wave phase when ceres is stalling
	if farewell_ceres.state == farewell_ceres.State.Stall \
	and state % 2 == 1:
		state += 1
		wave_phase = 0
		can_change_wave_phase = false
		can_spawn_dark_cherry = false
		dark_cherry_spawn_timer.start()
		wave_phase_cooldown.start()
		farewell_ceres.test_orb.stop()
		
		update_platforms()

func update_platforms() -> void:
	if state == 1:
		set_platform_process(lower_left_platform, true)
		set_platform_process(lower_middle_left_platform, true)
		set_platform_process(lower_middle_right_platform, true)
		set_platform_process(lower_right_platform, true)
		
		set_platform_process(middle_left_platform, true)
		set_platform_process(middle_right_platform, true)
		
		set_platform_process(upper_left_platform, true)
		set_platform_process(upper_right_platform, true)
	
	elif state == 2:
		set_platform_process(lower_left_platform, true)
		set_platform_process(lower_middle_left_platform, true)
		set_platform_process(lower_middle_right_platform, true)
		set_platform_process(lower_right_platform, true)
		
		set_platform_process(middle_left_platform, false)
		set_platform_process(middle_right_platform, false)
		
		set_platform_process(upper_left_platform, false)
		set_platform_process(upper_right_platform, false)

func set_platform_process(platform: Node2D, enable: bool) -> void:
	if enable:
		platform.process_mode = Node.PROCESS_MODE_INHERIT
		platform.visible = true
	else:
		platform.process_mode = Node.PROCESS_MODE_DISABLED
		platform.visible = false

func handle_enemy_wave() -> void:
	if state in [2, 4, 6]:
		# advance phase
		if can_change_wave_phase and mob_list.get_child_count() == 0:
			advance_wave_phase()
			can_change_wave_phase = false
			wave_phase_cooldown.start()
			
		# dark cherry spawn
		if can_spawn_dark_cherry and dark_cherry_spawn_counter == 0:
			
			if dark_cherry_next_position == "right":
				spawn_enemy("dark_cherry", Vector2(15660, -1488), false, 1)
				dark_cherry_next_position = "left"
				
			elif dark_cherry_next_position == "left":
				spawn_enemy("dark_cherry", Vector2(15916, -1488), true, 1)
				dark_cherry_next_position = "right"
				
			dark_cherry_spawn_counter += 1
			can_spawn_dark_cherry = false
			dark_cherry_spawn_timer.start()

func advance_wave_phase() -> void:
	# remaining enemies
	if wave_phase < wave_spawn[state].size():
		for enemy_info in wave_spawn[state][wave_phase]:
			callv("spawn_enemy", enemy_info)
		
		wave_phase += 1

	# end wave
	else:
		dark_cherry_spawn_timer.stop()
		wave_phase_cooldown.stop()
		state += 1
		
		# resume fight against ceres
		farewell_ceres.teleport_sound.play()
		farewell_ceres.position.y += 300
		farewell_ceres.state = farewell_ceres.State.Default
		farewell_ceres.sprite.visible = true
		farewell_ceres.hurtbox.set_deferred("disabled", false)

func spawn_enemy(mob_name: String, spawn_position: Vector2, flip_sprite: bool, max_health: int = 0, delay: float = 0.0) -> void:
	var mob_spawner = MOB_SPAWNER.instantiate()
	mob_spawner.position = spawn_position
	mob_spawner.flip_sprite = flip_sprite
	mob_spawner.max_health = max_health
	mob_spawner.delay = delay
	mob_spawner.set_mob("res://scenes/chars/" + mob_name + ".tscn")
	
	if mob_name == "dark_cherry":
		add_child(mob_spawner)
	else:
		mob_list.add_child(mob_spawner)

func _on_area_entered(_area: Area2D) -> void:
	# init the fight
	if state == 0:
		state = 1
		#player.state = player.State.Stop
		#player.sprite.flip_h = false
		farewell_ceres.start()
		
		# hud
		Global.boss = farewell_ceres
		hud.display_boss = true
		hud.current_boss_health_bar = farewell_ceres.health_bar
		hud.boss_name.text = "Ceres"
		
		# lock camera
		camera_limit_left = camera.limit_left
		camera_limit_right = camera.limit_right
		camera_limit_top = camera.limit_top
		camera_limit_bottom = camera.limit_bottom
		
		# fix camera limit
		camera.limit_left = 15576
		camera.limit_right = 16002
		camera.limit_top = -1776
		camera.limit_bottom = -1456
		
		# musics
		music.stop()
		boss_music.play()

func _on_dark_cherry_spawn_timer_timeout() -> void:
	can_spawn_dark_cherry = true

func _on_wave_phase_cooldown_timeout() -> void:
	can_change_wave_phase = true
