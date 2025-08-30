extends CharacterBody2D
@onready var hud = get_node("/root/World/Hud")
var MAX_SPEED: float = 400.0
var MIN_SPEED: float=100.0
var speed: float=100.0
var acceleration: float=1.1
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
# Controls how strongly velocity affects animation speed
var anim_speed_base: float = 1.0	# normal playback at walking speed
var anim_speed_factor: float = 0.02
func _physics_process(_delta: float) -> void:

	var dir := Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	)
	
	# Normalize so diagonals aren't faster
	if dir.length() > 1.0:
		dir = dir.normalized()
	speed=clamp(speed * acceleration ,0,MAX_SPEED)
	velocity = dir * speed
	hud.get_node("Label").text=str(velocity)
	move_and_slide()
	# Animate
	if dir == Vector2.ZERO:
		_play_if_needed("lotti_idle_right") # pick your default idle
		anim.speed_scale = 1.0
		return

	# Pick facing by the dominant axis
	if abs(dir.x) > abs(dir.y):
		if dir.x > 0.0:
			_play_if_needed("lotti_run_right")
		else:
			
			_play_if_needed("lotti_run_right",true)
	else:
		if dir.y > 0.0:
			_play_if_needed("lotti_run_right")
		else:
			_play_if_needed("lotti_run_right")

	# Scale FPS with movement speed
	var vel_mag := velocity.length()
	anim.speed_scale = anim_speed_base + vel_mag * anim_speed_factor

func _play_if_needed(animation_name: String, flip_h:bool=false) -> void:
	if anim.animation != animation_name or anim.is_playing or anim.flip_h != flip_h :
		anim.flip_h=flip_h
		anim.play(animation_name)
		




	