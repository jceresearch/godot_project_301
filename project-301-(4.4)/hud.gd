extends CanvasLayer
#hud.gd

@onready var health_bar: ProgressBar = $Health_bar
@onready var health_label: Label = $Health_label
@onready var speed_label: Label= $Speed_label

var player: Node2D

func _ready():
	# Find the player and connect to health signals
	player = get_tree().get_first_node_in_group("player")
	if player:
		# Connect to player's health signals
		if player.has_signal("health_changed"):
			player.health_changed.connect(_on_player_health_changed)
		else:
			print("Debug couldn't setup health_changed signal'")
		if player.has_signal("player_died"):
			player.player_died.connect(_on_player_died)
		else:
			print("Debug couldn't setup player_died signal")
		
		# Initialize UI
		update_health_display(player.get_health(), player.get_max_health())

func _on_player_health_changed(current_health: float, max_health: float):
	"""Called when player's health changes"""
	update_health_display(current_health, max_health)

func update_speed_display(current_speed:float, is_dashing:bool):
	if speed_label:
		var dashing_text=" Dash" if is_dashing else ""
		speed_label.text="Speed: " + str(int(current_speed))+dashing_text
			
func update_health_display(current_health: float, max_health: float):
	"""Update the health bar and label"""
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = current_health
	else:
		print("Debug: coudn't find health bar'")
	
	if health_label:
		health_label.text = "Health: " + str(int(current_health)) + "/" + str(int(max_health))

func _on_player_died():
	"""Called when player dies"""
	if health_label:
		health_label.text = "GAME OVER"
		health_label.modulate = Color.RED
