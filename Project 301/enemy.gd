# Enemy.gd
extends CharacterBody2D

# Signals

signal enemy_died(enemy)

# Enemy stats
var MAX_HEALTH: float = 100.0
var SPEED: float = 10.0
var DAMAGE: float = 25.0

# Current stats

var current_health: float
var is_alive: bool = true

# References

var player: Node2D
var sprite: Sprite2D
var collision_shape_body: CollisionShape2D
var collision_shape_feet: CollisionShape2D
func _ready():
	# Get node references
	add_to_group("enemy")
	sprite = get_node("Sprite2D") # Adjust path as needed
	collision_shape_body = get_node("BodyArea2D/CollisionShape2D")
	collision_shape_feet= get_node("FeetCollisionShape2D") 
	player = get_tree().get_first_node_in_group("player")
	var damage_area: Area2D = get_node_or_null("DamageArea2D")
	
	if damage_area:
		damage_area.y_sort_enabled = false
		damage_area.body_entered.connect(_on_area_2d_body_entered)
		damage_area.area_entered.connect(_on_area_2d_area_entered)
	else:
		print("Debug, didn't find damage area'")
	reset_enemy()
	


func _physics_process(_delta):
	if not is_alive or not player:
		return
	# Move towards player
	var direction = (player.global_position - global_position).normalized()
	velocity = direction * SPEED
	move_and_slide()

	# Face the player (optional)
	if direction.x < 0:
		sprite.scale.x = -1
	else:
		sprite.scale.x = 1


func reset_enemy():
	#Reset enemy to initial state - called when spawned from pool
	current_health = MAX_HEALTH
	is_alive = true
	velocity = Vector2.ZERO
	if sprite:
		sprite.modulate = Color.WHITE
		sprite.scale = Vector2.ONE
		collision_shape_body.disabled = false
		collision_shape_body.disabled = false
		

func take_damage(amount: float):
	#Make the enemy take damage”””
	if not is_alive:
		return
	print("Debug take_damage taking damage ", str(amount))
	current_health -= amount
	#Visual feedback
	if sprite:
		print("Debug trying visual feedback")
		sprite.modulate = Color.RED
		create_tween().tween_property(sprite, "modulate", Color.WHITE, 0.1)

	# Check if dead
	if current_health <= 0:
		die()
func die():
	#Handle enemy death
	if not is_alive:
		return
	is_alive = false

	# Death effects (optional)
	if sprite:
		var tween = create_tween()
		tween.parallel().tween_property(sprite, "scale", Vector2.ZERO, 0.3)
		tween.parallel().tween_property(sprite, "modulate", Color.TRANSPARENT, 0.3)

	collision_shape_body.disabled = true
	collision_shape_feet.disabled=true
	# Emit death signal for pooling system
	enemy_died.emit(self)


func get_health_percentage() -> float:
	#Get health as a percentage
	return current_health / MAX_HEALTH

func _on_area_2d_body_entered(body):
	#event for when 2d body (player) enters the damage area of the enemy
	if body.is_in_group("player") and is_alive:
		print("player entered area 2d and will take damage")
		if body.has_method("take_damage"):
			print("enemy is calling body.take_damage()")
			body.take_damage(DAMAGE)
			# Optionally die after hitting player
			# die()
	
func _on_area_2d_area_entered(area):
	#If projectiles use Area2D”””
	if area.is_in_group("player_projectile") and is_alive:
		print("area2d entered damage area")
		var projectile_damage = 50.0 # Or get from projectile
		if area.has_method("get_damage"):
			projectile_damage = area.get_damage()
		take_damage(projectile_damage)
		# Destroy projectile
		if area.has_method("destroy"):
			area.destroy()
		else:
			area.queue_free()

