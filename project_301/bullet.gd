class_name Bullet
extends Area2D

@export var speed: float = 1800.0
var damage: float = 10.0
var bullet_lifespan_seconds: float = 4.0
var direction: Vector2 = Vector2.RIGHT

func _ready() -> void:
	add_to_group("weapon")
	add_to_group("projectiles")
	# Automatically clean up bullet if it doesn't hit anything
	get_tree().create_timer(bullet_lifespan_seconds).timeout.connect(queue_free)
	body_entered.connect(_on_body_entered)
	
func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta

func resolve_hit() -> void:
	queue_free()
	
func _on_body_entered(_body: Node2D) -> void:
	resolve_hit()