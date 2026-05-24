extends CharacterBody2D
#player.gd
@export var bullet_scene: PackedScene
@export var fire_rate: float = 0.25
var _can_shoot: bool = true


@onready var hurtbox: Area2D = $HurtBox  # This is what enemies will detect
var MAX_SPEED: float = 1000.0
var MIN_SPEED: float=100.0
var MAX_HEALTH: float = 100.0

var ACCELERATION: float = 50.0 # Gain X pixels/sec
var FRICTION: float = 200.0  # Lose X pixels/sec when stopping


# Current stats
var current_speed: float=0.0
var current_drag: float=0.0
var current_acceleration: float = 0.0
var current_health: float=0
var is_alive: bool = true
var last_dir: Vector2 = Vector2.RIGHT


# Damage immunity (prevent spam damage)
var is_immune: bool = false
var IMMUNITY_DURATION: float = 1.0	# 1 second of immunity after taking damage
@onready var immunity_timer: Timer = Timer.new()

# Signals (optional - for UI updates, game over, etc.)
signal health_changed(new_health: float, max_health: float)
signal player_died

# Dash settings
var DASH_MULTIPLIER: float = 1.2 	# how strong the boost is
var DASH_TIME: float = 2.0			# seconds the boost lasts
var DASH_COOLDOWN: float = 2.0		# seconds before next dash
var PANT_DURATION: float = 0.5 # seconds for panting after dash
var _is_dashing: bool = false
var _is_panting: bool = false
var _dash_ready_at: float = 0.0		# unixtime (seconds) cooldown
@onready var swoosh: AudioStreamPlayer2D = $SwooshSound

# Animation related
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
# Controls how strongly velocity affects animation speed
var ANIM_SPEED_BASE: float = 1.0	# normal playback at walking speed
var ANIM_SPEED_FACTOR: float = 0.02
var ANIM_SPEED_TOP_FACTOR: float= 3.0
var UPPER_MAGNITUDE: float= 800.0
var LOWER_MAGNITUDE: float = 100.0
@onready var DEFAULT_MODULATE_COLOR: Color

func _enter_tree() -> void:
	GameManager.player = self

func _exit_tree() -> void:
	if GameManager.player == self:
		GameManager.player = null

func _ready():
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
	hurtbox.area_entered.connect(_on_hurtbox_area_entered)
	print("Finished getting the player ready")
func _on_hurtbox_area_entered(area: Area2D) -> void:
	print("Something entered hurtbox area",area.name)
	if not is_alive or is_immune:
		return
	if "damage" in area:
		take_damage(area.damage)

	




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
	


@onready var hud=GameManager.hud

func _physics_process(delta: float) -> void:
	var dir := Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	).normalized()
	hud.get_node("SpeedLabel").text = str(dir.x) + " " + str(dir.y)

	if dir != Vector2.ZERO:
		last_dir = dir

	if Input.is_action_just_pressed("reset_position"):
		global_position = Vector2.ZERO
		velocity = Vector2.ZERO
		current_speed = 0
		current_health = MAX_HEALTH
		return
		
		
	if Input.is_action_just_pressed("fire") and _can_shoot and is_alive:
		_shoot()
	# Added condition to prevent dashing while panting
	if Input.is_action_just_pressed("dash") and not _is_dashing and not _is_panting and dir != Vector2.ZERO and Time.get_unix_time_from_system() >= _dash_ready_at:
		_do_dash(dir)
	
	if _is_dashing:
		current_speed = clamp(current_speed * DASH_MULTIPLIER, MIN_SPEED, MAX_SPEED)
	elif _is_panting:
		# Rapidly scale speed down to zero
		current_speed = move_toward(current_speed, 0.0, FRICTION * 8.0 * delta)
	else:
		if dir != Vector2.ZERO:
			current_speed += ACCELERATION * delta
			if current_speed < MIN_SPEED:
				current_speed = MIN_SPEED
		else:
			current_speed -= FRICTION * delta
			
		current_speed = clamp(current_speed, 0, MAX_SPEED)

	velocity = last_dir * current_speed
	
	# Handle panting animation state when completely stopped
	if _is_panting and current_speed == 0:
		if last_dir.x < 0.0:
			_play_if_needed("lotti_idle_right", true)
		else:
			_play_if_needed("lotti_idle_right", false)
		anim.speed_scale = 1.0
	elif current_speed == 0:
		_play_if_needed("lotti_idle_right")
		anim.speed_scale = 1.0
	else:
		if abs(last_dir.x) > abs(last_dir.y):
			if last_dir.x > 0.0:
				_play_if_needed("lotti_run_right")
			else:
				_play_if_needed("lotti_run_right", true)
		else:
			if last_dir.y > 0.0:
				_play_if_needed("lotti_run_front")
			else:
				_play_if_needed("lotti_run_up")

		var vel_magnitude := velocity.length()
		var span = (UPPER_MAGNITUDE - LOWER_MAGNITUDE) * 0.8
		
		if vel_magnitude < LOWER_MAGNITUDE:
			anim.speed_scale = ANIM_SPEED_BASE
		elif vel_magnitude < UPPER_MAGNITUDE:
			anim.speed_scale = lerp(ANIM_SPEED_BASE, ANIM_SPEED_TOP_FACTOR, (vel_magnitude - LOWER_MAGNITUDE) / span)
		else:
			anim.speed_scale = ANIM_SPEED_TOP_FACTOR

	move_and_slide()

func _shoot() -> void:
	if not bullet_scene:
		return
	
	_can_shoot = false
	var bullet = bullet_scene.instantiate()
	
	# Spawn bullet at player position and face movement direction
	bullet.global_position = global_position
	bullet.direction = last_dir
	bullet.rotation = last_dir.angle()
	
	# Add bullet to main scene tree so it moves independently of player
	get_tree().current_scene.add_child(bullet)
	
	# Handle Cooldown
	await get_tree().create_timer(fire_rate).timeout
	_can_shoot = true
	
	
func _end_dash_later() -> void:
	await get_tree().create_timer(DASH_TIME).timeout
	_is_dashing = false
	_is_panting = true
	
	# Wait here until physics process brings speed down to 0
	while current_speed > 0:
		await get_tree().process_frame
	
	# Run the panting animation state for exactly 1 second
	await get_tree().create_timer(PANT_DURATION).timeout
	
	_is_panting = false
	_dash_ready_at = Time.get_unix_time_from_system() + DASH_COOLDOWN
