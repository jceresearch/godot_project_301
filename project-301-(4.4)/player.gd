extends CharacterBody2D
#player.gd

@onready var hud = get_node("/root/World/Hud")
@onready var hurtbox: Area2D = $Hurtbox  # This is what enemies will detect
var MAX_SPEED: float = 3000.0
var MIN_SPEED: float=100.0
var ACCELERATION: float=1.01
var current_speed: float=0.0

# Player stats
@export var MAX_HEALTH: float = 100.0


# Current stats
var current_health: float=0
var is_alive: bool = true

# Damage immunity (prevent spam damage)
var is_immune: bool = false
var IMMUNITY_DURATION: float = 1.0	# 1 second of immunity after taking damage

# References
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var immunity_timer: Timer = Timer.new()

# Signals (optional - for UI updates, game over, etc.)
signal health_changed(new_health: float, max_health: float)
signal player_died

# Dash settings
var DASH_MULTIPLIER: float = 1.05	# how strong the boost is
var DASH_TIME: float = 0.15			# seconds the boost lasts
var DASH_COOLDOWN: float = 0.6		# seconds before next dash
var _is_dashing: bool = false
var _dash_ready_at: float = 0.0		# unixtime (seconds) cooldown
@onready var swoosh: AudioStreamPlayer2D = $SwooshSound


@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
# Controls how strongly velocity affects animation speed
var ANIM_SPEED_BASE: float = 1.0	# normal playback at walking speed
var ANIM_SPEED_FACTOR: float = 0.02
var ANIM_SPEED_TOP_FACTOR: float= 3.0
var UPPER_MAGNITUDE: float= 800.0
var LOWER_MAGNITUDE: float = 100.0

@onready var DEFAULT_MODULATE_COLOR: Color

func _ready():
	self.add_to_group("player")
	current_health = MAX_HEALTH
	current_speed=MIN_SPEED
	DEFAULT_MODULATE_COLOR=self.modulate
	add_child(immunity_timer) # after receiving a hit some immunity time
	immunity_timer.wait_time = IMMUNITY_DURATION
	immunity_timer.one_shot = true
	immunity_timer.timeout.connect(_on_immunity_timeout)	
	health_changed.emit(current_health, MAX_HEALTH)
	hurtbox.add_to_group("player_hurtbox")
	# Disable Y-sorting to avoid conflicts
	hurtbox.y_sort_enabled = false
	
func _physics_process(_delta: float) -> void:
	var dir := Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	)
	if Input.is_action_just_pressed("reset_position"):
		global_position=Vector2i(0,0)
		velocity=Vector2(0,0)
	if dir.length() > 1.0:
		dir = dir.normalized() #  so diagonals aren't faster
		
	if Input.is_action_just_pressed("dash") and not _is_dashing and dir != Vector2.ZERO and Time.get_unix_time_from_system() >= _dash_ready_at:
		_do_dash(dir)
		
	current_speed=clamp(current_speed * ACCELERATION ,MIN_SPEED,MAX_SPEED)
	# If dashing, give the speed a stronger push while the dash is active
	if _is_dashing:
		current_speed = clamp(current_speed * DASH_MULTIPLIER, MIN_SPEED, MAX_SPEED)
	velocity = dir * current_speed
	hud.update_speed_display(current_speed,_is_dashing)
	move_and_slide()

	# Animate
	if dir == Vector2.ZERO:
		_play_if_needed("lotti_idle_right") # pick your default idle
		anim.speed_scale = 1.0
		current_speed=0
		return

	# Pick facing by the dominant axis
	if abs(dir.x) > abs(dir.y):
		if dir.x > 0.0:
			_play_if_needed("lotti_run_right")
		else:
			
			_play_if_needed("lotti_run_right",true)
	else:
		if dir.y > 0.0:
			_play_if_needed("lotti_run_front")
		else:
			_play_if_needed("lotti_run_up")

	# Scale FPS with movement speed
	var vel_magnitude := velocity.length()
	#anim.speed_scale = anim_speed_base + vel_magnitude * anim_speed_factor
	#var K := 100	# steepness factor
	#anim.speed_scale = anim_speed_base + (1.0 / (1.0 + exp(-k * (vel_magnitude - 500.0)))) * anim_speed_factor * 10.0 # s curve
	#anim.speed_scale = anim_speed_base + log(1.0 + K+vel_magnitude) * anim_speed_factor # logarithmic
	var span= (UPPER_MAGNITUDE-LOWER_MAGNITUDE) * .8 #slight overshoot in span acceleration
	if vel_magnitude < LOWER_MAGNITUDE:
		anim.speed_scale = ANIM_SPEED_BASE
	elif vel_magnitude < UPPER_MAGNITUDE:
		anim.speed_scale = lerp(ANIM_SPEED_BASE,ANIM_SPEED_TOP_FACTOR , (vel_magnitude - LOWER_MAGNITUDE) / span)
	else:
		anim.speed_scale = UPPER_MAGNITUDE
	
	
	
	
func _play_if_needed(animation_name: String, flip_h:bool=false) -> void:
	if anim.animation != animation_name or anim.is_playing or anim.flip_h != flip_h :
		anim.flip_h=flip_h
		anim.play(animation_name)
		


func _do_dash(dir: Vector2) -> void:
	_is_dashing = true
	if swoosh.stream and not swoosh.playing:
		swoosh.play()
	# Optional: tiny immediate impulse so dash feels snappy
	velocity = dir * min(current_speed * DASH_MULTIPLIER, MAX_SPEED)
	# End dash after dash_time, then start cooldown
	_end_dash_later()

func _end_dash_later() -> void:
	await get_tree().create_timer(DASH_TIME).timeout
	_is_dashing = false
	_dash_ready_at = Time.get_unix_time_from_system() + DASH_COOLDOWN


func take_damage(amount: float):
	"""Make the player take damage"""
	print("Player took damage ", str(amount))
	if not is_alive or is_immune:
		return
	current_health -= amount
	damage_flash()
	start_immunity()
	health_changed.emit(current_health, MAX_HEALTH)
	if current_health <= 0:
		die()
func damage_flash():
	"""Visual feedback when taking damage"""
	if sprite:
		sprite.modulate = Color.RED
		var tween = create_tween()
		tween.tween_property(sprite, "modulate", DEFAULT_MODULATE_COLOR, 0.2)
	else:
		print("Debug couldn't find the sprite for damage_flash()'")

func start_immunity():
	is_immune = true
	if hurtbox:
		hurtbox.monitoring = false
		hurtbox.monitorable = false
	immunity_timer.start()
	start_immunity_blink()
	

func start_immunity_blink():
	"""Make player blink during immunity"""
	if not sprite:
		return
	var blink_tween = create_tween()
	blink_tween.set_loops(int(IMMUNITY_DURATION * 4))	# Blink 4 times per second
	blink_tween.tween_property(sprite, "modulate:a", 0.5, 0.125)
	blink_tween.tween_property(sprite, "modulate:a", 1.0, 0.125)

func _on_immunity_timeout():
	"""Called when immunity period ends"""
	is_immune = false
	if sprite:
		sprite.modulate = DEFAULT_MODULATE_COLOR # Ensure sprite is fully visible
			# Re-enable hurtbox
	if hurtbox:
		hurtbox.monitoring = true
		hurtbox.monitorable = true
	

func die():
	"""Handle player death"""
	if not is_alive:
		return
		
	is_alive = false
	current_health = 0
	if hurtbox:
		hurtbox.monitorable = false
	
	print("Player died!")
	
	# Death visual effects
	if sprite:
		var death_tween = create_tween()
		death_tween.parallel().tween_property(sprite, "scale", Vector2.ZERO, 0.5)
		death_tween.parallel().tween_property(sprite, "modulate", Color.TRANSPARENT, 0.5)
	
	# Emit death signal
	player_died.emit()
	
	# Optional: Restart game after delay
	await get_tree().create_timer(2.0).timeout
	get_tree().reload_current_scene()

# Healing method (bonus!)
func heal(amount: float):
	"""Heal the player"""
	if not is_alive:
		return
		
	current_health += amount
	current_health = min(current_health, MAX_HEALTH)	# Don't exceed max health
	
	print("Player healed for ", amount, "! Health: ", current_health)
	health_changed.emit(current_health, MAX_HEALTH)

# Getter methods
func get_health() -> float:
	return current_health

func get_max_health() -> float:
	return MAX_HEALTH

func get_health_percentage() -> float:
	return current_health / MAX_HEALTH
# Optional: Method to get the hurtbox for external reference
func get_hurtbox() -> Area2D:
	return hurtbox
func is_player_alive() -> bool:
	return is_alive
	