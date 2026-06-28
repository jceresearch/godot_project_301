extends Node2D
@export var enemy_scene: PackedScene
@export var pool_size: int = 50
@export var max_active_enemies: int = 3
@export var spawn_interval: float = 3
@export var spawn_radius: float = 500.0
var enemy_pool: Array[Node] = []
var active_enemies: Array[Node] = []
var spawn_timer: Timer


func _ready():
	initialize_pool()
	spawn_timer = Timer.new()
	add_child(spawn_timer)
	spawn_timer.wait_time = spawn_interval
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	spawn_timer.start()
	

func initialize_pool():
	if not enemy_scene:
		push_error("Enemy scene not assigned to spawner!")
		return
	for i in range(pool_size):
		var enemy = enemy_scene.instantiate()
		_toggle_enemy_physics(enemy, false)
		add_child(enemy)
		if enemy.has_signal("enemy_died"):
			enemy.enemy_died.connect(_on_enemy_died)
		
		# Deactivate physics completely at start
		
		enemy_pool.append(enemy)

func spawn_enemy() -> Node:
	if enemy_pool.is_empty() or active_enemies.size() >= max_active_enemies:
		return null
	var enemy = enemy_pool.pop_back()
	
	# Set position BEFORE turning physics back on
	enemy.global_position = get_spawn_position()
	_toggle_enemy_physics(enemy, true)
	
	enemy.scale = enemy.INITIAL_SCALE
	if enemy.has_method("reset_enemy"):
		enemy.reset_enemy()
	active_enemies.append(enemy)
	return enemy

func return_enemy_to_pool(enemy: Node):
	if not enemy in active_enemies:
		return
	active_enemies.erase(enemy)
	
	# Turn off physics before returning to pool
	_toggle_enemy_physics(enemy, false)
	enemy_pool.append(enemy)

# Helper function to fully mute/unmute enemy nodes
func _toggle_enemy_physics_old(enemy: Node, active: bool):
	enemy.visible = active
	enemy.set_physics_process(active)
	enemy.set_process(active)
	
	# Disable the Area2Ds or the main Collision Shapes
	var hitbox = enemy.get_node_or_null("HitBox")
	var hurtbox = enemy.get_node_or_null("HurtBox")
	
	if hitbox:
		if not enemy.is_inside_tree():
			hitbox.monitoring = active
			hitbox.monitorable = active
		else:
			hitbox.set_deferred("monitoring", active)
			hitbox.set_deferred("monitorable", active)
	if hurtbox:
		if not enemy.is_inside_tree():
			hurtbox.monitoring = active
			hurtbox.monitorable = active
		else:
			hurtbox.set_deferred("monitoring", active)
			hurtbox.set_deferred("monitorable", active)

func _toggle_enemy_physics(enemy: Node, active: bool) -> void:
	enemy.visible = active
	# Master switch: freezes _process, _physics_process, timers, and anims
	enemy.process_mode = Node.PROCESS_MODE_INHERIT if active else Node.PROCESS_MODE_DISABLED
	# 1. Disable the root physical body
	var body_col: CollisionShape2D = enemy.get_node_or_null("CollisionShape2D")
	if body_col:
		body_col.set_deferred("disabled", not active)
	# 2. Disable the trigger areas
	for area_name in ["HitBox", "HurtBox"]:
		var area: Area2D = enemy.get_node_or_null(area_name)
		if area:
			area.set_deferred("monitoring", active)
			area.set_deferred("monitorable", active)
			
	# 3. Safety net: warp pooled objects far away
	if not active and enemy is Node2D:
		enemy.global_position = Vector2(-9999, -9999)




func get_spawn_position() -> Vector2:
	#Get a random spawn position around the player or scene”””
	var spawn_pos: Vector2
	var player= GameManager.player
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
