extends Area2D

@export var parent_entity: Node

func _ready() -> void:
	assert(parent_entity != null, "Hurtbox missing parent_entity, manually assign in inspector!")
	y_sort_enabled=false
	area_entered.connect(_on_area_entered)		
	
func _on_area_entered(area: Area2D) -> void:
	if area is Bullet:
		if parent_entity.can_take_damage() and parent_entity.is_alive:
			parent_entity.take_damage(area.damage)
			area.resolve_hit()
			

