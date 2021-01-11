extends "res://Enemies/Enemy.gd"

export(int) var ACCELERATION = 100

var MainInstances = ResourceLoader.MainInstances

onready var sprite = $Sprite

func _physics_process(delta):
	var player = MainInstances.Player
	
	if player != null:
		chase_player(player,delta)
		
func chase_player(player, delta):
	var direction = (player.global_position - global_position).normalized() #calculate direction to the player
	motion += direction * ACCELERATION * delta #add motion to the direction
	motion = motion.clamped(MAX_SPEED) #remein speed under enemy's maximum 
	sprite.flip_h = global_position < player.global_position #Enemy looks in player's direction
	motion = move_and_slide(motion) #actual move
