extends Area2D

export(int) var damage = 1

# if hitbox intersects hutbox it makes 
# hurtbox scream that it got some damage
func _on_Hitbox_area_entered(hurtbox):
	hurtbox.emit_signal("hit",damage)
