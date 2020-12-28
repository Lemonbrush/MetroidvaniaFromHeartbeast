extends Control

var PlayerStats = ResourceLoader.PlayerStats

onready var full = $Full

func _ready():
	PlayerStats.connect("health_health_changed", self, "_on_player_health_changed")
	
func _on_player_health_changed(value):
	full.rect_size.x = value * 5 # one tile of health is 5 pixel size width 
