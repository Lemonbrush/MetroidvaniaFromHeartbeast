extends Resource
class_name PlayerStats

var max_health = 4
var health = max_health setget set_health

signal health_health_changed(value)
signal player_died

func set_health(value):
	#if a new health value is less than current one - player is damaged
	if value < health:
		Events.emit_signal("add_screenshake", 0.4, 0.5)
	health = clamp(value, 0, max_health)
	emit_signal("health_health_changed", health)
	if health == 0:
		emit_signal("player_died")
