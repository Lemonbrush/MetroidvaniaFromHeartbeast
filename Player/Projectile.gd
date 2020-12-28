extends Node2D

const ExplosionEffect = preload("res://Effects/ExplosionEffect.tscn")

var velocity = Vector2.ZERO

func _process(delta):
	position += velocity *delta

func _on_VisibilityNotifier2D_viewport_exited(_viewport):
	queue_free()

func _on_Hitbox_body_entered(_body):
	Utils.instance_scene_on_main(ExplosionEffect, global_position) #create an explosion effect
	queue_free()

func _on_Hitbox_area_entered(_area):
	Utils.instance_scene_on_main(ExplosionEffect, global_position) #create an explosion effect
	queue_free()
