extends Node2D
@export var enemy_scene: PackedScene
@export var pool_size: int = 50
@export var max_active_enemies: int = 3
@export var spawn_interval: float = 10
@export var spawn_radius: float = 500.0
var enemy_pool: Array[Node] = []
var active_enemies: Array[Node] = []
var spawn_timer: Timer
@onready var player: Node2D

func _ready():
	initialize_pool()
	spawn_timer = Timer.new()
	add_child(spawn_timer)
	spawn_timer.wait_time = spawn_interval
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	spawn_timer.start()
	player = get_tree().get_first_node_in_group("player")

func initialize_pool():
	if not enemy_scene:
		push_error("Enemy scene not assigned to spawner!")
		return
	for i in range(pool_size):
		var enemy = enemy_scene.instantiate()
		add_child(enemy)
		# Connect enemy death signal
		if enemy.has_signal("enemy_died"):
			enemy.enemy_died.connect(_on_enemy_died)
		enemy.set_physics_process(false)
		enemy.set_process(false)
		enemy.visible = false
		enemy_pool.append(enemy)


func spawn_enemy() -> Node:
	if enemy_pool.is_empty() or active_enemies.size() >= max_active_enemies:
		return null
	var enemy = enemy_pool.pop_back()
	var spawn_position = get_spawn_position()
	enemy.global_position = spawn_position
	enemy.visible = true
	enemy.set_physics_process(true)
	enemy.set_process(true)
	if enemy.has_method("reset_enemy"):
		enemy.reset_enemy()
	active_enemies.append(enemy)
	return enemy

func get_spawn_position() -> Vector2:
	#Get a random spawn position around the player or scene”””
	var spawn_pos: Vector2
	if player:
		# Spawn around player
		var angle = randf() * TAU
		var distance = spawn_radius
		spawn_pos = player.global_position + Vector2(cos(angle), sin(angle)) * distance
	else:
		# Spawn randomly in scene
		var viewport_size = get_viewport().get_visible_rect().size
		spawn_pos = Vector2(
		randf_range(0, viewport_size.x),
		randf_range(0, viewport_size.y)
	)

	return spawn_pos


func return_enemy_to_pool(enemy: Node):
	#Return an enemy to the pool”””
	if not enemy in active_enemies:
		return
	# Remove from active list
	active_enemies.erase(enemy)

	# Deactivate enemy
	enemy.visible = false
	enemy.set_physics_process(false)
	enemy.set_process(false)

	# Return to pool
	enemy_pool.append(enemy)

func _on_spawn_timer_timeout():
	#Called when spawn timer times out”””
	spawn_enemy()

func _on_enemy_died(enemy: Node):
	#Called when an enemy dies”””
	return_enemy_to_pool(enemy)

func get_active_enemy_count() -> int:
	#Get the number of currently active enemies”””
	return active_enemies.size()

func get_pool_size() -> int:
	#Get the size of the available pool”””
	return enemy_pool.size()

# Optional: Manual spawn method for special events
func force_spawn_enemy(new_position: Vector2 = Vector2.ZERO) -> Node:
	#Force spawn an enemy at a specific position
	var enemy = spawn_enemy()
	if enemy and new_position != Vector2.ZERO:
		enemy.global_position = new_position
	return enemy