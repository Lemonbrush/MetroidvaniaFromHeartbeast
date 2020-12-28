extends ColorRect

var paused = false setget set_paused

# hides and shows the menue by the paused value
func set_paused(value):
	paused = value
	get_tree().paused = paused #stops all processes in its parent and his children due to inheritance
	visible = paused

func _process(delta):
	if Input.is_action_just_pressed("pause"):
		self.paused = !paused

func _on_ResumeButton_pressed():
	self.paused = false

func _on_QuitButton_pressed():
	get_tree().quit()
