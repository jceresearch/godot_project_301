# Enemy.gd
class_name Enemy
extends CharacterBody2D

# Signals

signal enemy_died(enemy)

# Enemy stats
var MAX_HEALTH: float = 50.0
var SPEED: float = 1.0
var DAMAGE_INFLICT: float = 25.0 # what this enemy inflicts on player, for now constant
var INITIAL_SCALE:  Vector2= Vector2(.5,.5)

# Current stats

var current_health: float
var is_alive: bool = true

# References

var player: Node2D
var sprite: Sprite2D
var bumpbox: CollisionShape2D
var hitbox: Area2D
var hurtbox: Area2D
func _ready():
	# Get node references
	add_to_group("enemy")
	sprite = get_node("Sprite2D") # Adjust path as needed
	bumpbox= get_node("CollisionShape2D") 
	player = GameManager.player
	hurtbox= get_node_or_null("HurtBox")
	hitbox= get_node_or_null("HitBox")
	if hitbox and hurtbox:
		hitbox.y_sort_enabled = false
		# enemy touches player or other npc
		hitbox.body_entered.connect(_on_area_2d_body_entered)
		
	else:
		print("Debug, didn't find enemy hitbox or hurtbox")
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
		sprite.scale.x = -1 * sprite.scale.x
	else:
		sprite.scale.x = 1 * sprite.scale.x


func reset_enemy():
	#Reset enemy to initial state - called when spawned from pool
	current_health = MAX_HEALTH
	is_alive = true
	velocity = Vector2.ZERO
	if sprite:
		sprite.modulate = Color.WHITE
		sprite.scale = INITIAL_SCALE
		bumpbox.disabled = false

		

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

	bumpbox.disabled = true
	# Emit death signal for pooling system
	enemy_died.emit(self)


func get_health_percentage() -> float:
	#Get health as a percentage
	return current_health / MAX_HEALTH

func _on_area_2d_body_entered(body):
	#event for when 2d body (player) enters the hitbox area of the enemy
	if body.is_in_group("player") and is_alive:
		print("player entered area 2d and will take damage")
		if body.has_method("take_damage"):
			print("enemy is calling body.take_damage()")
			body.take_damage(DAMAGE_INFLICT)
			# Optionally die after hitting player
			# die()

func can_take_damage() -> bool:
	if not is_alive:
		return false
	#we can get here some code for cooldown or slight immunity
    #say just respawn or doing something we want some immunity
	return true	
		

