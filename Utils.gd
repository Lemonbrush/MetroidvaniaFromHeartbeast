extends Node

# it is a singleton which allows you to instance anything from anywhere and have an access to the instanced object
func instance_scene_on_main(scene, position):
	var main = get_tree().current_scene
	var instance = scene.instance()
	
	main.add_child(instance)
	instance.global_position = position
	return instance
