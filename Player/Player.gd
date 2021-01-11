extends KinematicBody2D

const DustEffect = preload("res://Effects/DustEffect.tscn")
const PlayerBullet = preload("res://Player/PlayerBullet.tscn")
const JumpEffect = preload("res://Effects/JumpEffect.tscn")
const WallDustEffect = preload("res://Effects/WallDustEffect.tscn")

var PlayerStats = ResourceLoader.PlayerStats
var MainInstances = ResourceLoader.MainInstances

export (int) var ACCELERATION = 512
export (int) var MAX_SPEED = 64
export (float) var FRICTION = 0.25
export (int) var GRAVITY = 200
export (int) var WALL_SLIDE_SPEED = 48
export (int) var MAX_WALL_SLIDE_SPEED = 128
export (int) var JUMP_FORCE = 128
export (int) var MAX_SLOPE_ANGLE = 46
export (int) var BULLET_SPEED = 250

enum {
	MOVE,
	WALL_SLIDE
}
var state = MOVE
var invincible = false setget set_invincible
var motion = Vector2.ZERO
var snap_vector = Vector2.ZERO
var just_jumped = false
var double_jump = true

onready var sprite = $Sprite
onready var spriteAnimator = $SpriteAnimator
onready var blinkAnimator = $BlinkAnimator
onready var coyoteJumpTimer = $CoyoteJumpTimer #allows player to jump after leaving an edge 
onready var fireBulletTimer = $FireBulletTimer
onready var gun = $Sprite/PlayerGun
onready var muzzle = $Sprite/PlayerGun/Sprite/Muzzle

func set_invincible(value):
	invincible = value
	
func _ready():
	PlayerStats.connect("player_died", self, "_on_died")
	MainInstances.Player = self

func _exit_tree():
	MainInstances.Player = null

#called every Frame of the game
func _physics_process(delta):
	just_jumped = false
	
	match state:
		MOVE: 
			var input_vector = get_input_vector()
			apply_horizontal_force(input_vector, delta)
			apply_friction(input_vector)
			update_snup_vector()
			jump_check()
			apply_gravity(delta)
			update_animations(input_vector)
			move()
			wall_slide_check()
			
		WALL_SLIDE:
			spriteAnimator.play("Wall Slide")
			
			var wall_axis = get_wall_axis() # 0 no walls; 1 wall on left; -1 wall on right
			if wall_axis != 0:
				sprite.scale.x = wall_axis
			
			wall_slide_jump_check(wall_axis) # slightly slide down by pressing up
			wall_slide_drop(delta) # jump on the opposite side from the wall by pressing left or right & increase down speed by pressing down
			move()
			wall_detach(delta, wall_axis) # check walls and change the state to MOVE
	
	if Input.is_action_pressed("Fire") and fireBulletTimer.time_left == 0:
		fire_bullet()
	
func fire_bullet():
	var bullet = Utils.instance_scene_on_main(PlayerBullet, muzzle.global_position)
	bullet.velocity = Vector2.RIGHT.rotated(gun.rotation) * BULLET_SPEED #find the gun angle and add speed
	bullet.velocity.x *=sprite.scale.x # it will be 1 or 0 related to the direction player goes 
	bullet.rotation = bullet.velocity.angle() # bullet will be rotated to the direction it flies 
	fireBulletTimer.start()
	
func create_dust_effect():
	var dust_position = global_position # dust position = player position
	dust_position.x += rand_range(-4, 4) # little bit of random
	Utils.instance_scene_on_main(DustEffect, dust_position)

func get_input_vector():
	var input_vector = Vector2.ZERO
	# x will be 1 or 0 by detecting and subtracting value from these functions (they return 0 or 1 if the key is pressed or not) 
	input_vector.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	input_vector.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	return input_vector
	
func apply_horizontal_force(input_vector, delta):
	if input_vector.x != 0:
		motion.x += input_vector.x * ACCELERATION * delta
		motion.x = clamp(motion.x, -MAX_SPEED, MAX_SPEED) #Clamps value and returns a value not less than min and not more than max.

func apply_friction(input_vector):
	if input_vector.x == 0 and is_on_floor():
		#motion.x - FRICTION % untill it becomes 0
		motion.x = lerp(motion.x, 0, FRICTION) 
		
func update_snup_vector():
	if is_on_floor():
		snap_vector = Vector2.DOWN
	
func jump_check():
	# if the Player on the floor he can jump
	if is_on_floor() or coyoteJumpTimer.time_left > 0:
		if Input.is_action_just_pressed("ui_up"):
			jump(JUMP_FORCE)
			just_jumped = true
	else: 
		# Small jump if the Player gently pressed the jump button
		if Input.is_action_just_released("ui_up") and motion.y < -JUMP_FORCE/2:
			motion.y = -JUMP_FORCE/2
		
		# another jump 
		if Input.is_action_just_pressed("ui_up") and double_jump == true:
			jump(JUMP_FORCE * .75) # the second jump is only 75% of original one
			double_jump = false

func jump(force):
	Utils.instance_scene_on_main(JumpEffect, global_position)
	motion.y = -force
	snap_vector = Vector2.ZERO
	

func apply_gravity(delta):
	if not is_on_floor():
		motion.y += GRAVITY * delta
		motion.y = min(motion.y, JUMP_FORCE) # gravity will always be less or equal to jump force 

func update_animations(input_vector):
	sprite.scale.x = sign(get_local_mouse_position().x)
	
	if input_vector.x != 0:
		# it takes into account that controllers haven't direct numbers because of sticks
		# flips sprite depending on the direction 1,-1,0
		# sprite.scale.x = sign(input_vector.x) returns -1 if the value is negative and 1 if it is positive and 0 if 0
		spriteAnimator.play("Run")
		spriteAnimator.playback_speed = input_vector.x * sprite.scale.x # plays animation in the mouse direction by their position difference
	else:
		spriteAnimator.playback_speed = 1 #reset sprite direction
		spriteAnimator.play("idle")
		
	if not is_on_floor():
		spriteAnimator.play("Jump")

func move():
	#states before changes
	var was_in_air = not is_on_floor()
	var was_on_floor = is_on_floor()
	var last_motion = motion
	var last_position = position
	
	motion = move_and_slide_with_snap(motion, snap_vector*4, Vector2.UP, true, 4, deg2rad(MAX_SLOPE_ANGLE))#Moves the body along a vector
	# it also returns to the motion variable leftover motion vector after colliding with some object
	# so it can continue to move along a wall instead just stopping 
	# the third parameter gives the engine to know which direction floor faces so player could use is_on_floor()
	# the second and the last parameters glue player to the floor
	# the 4th parameter sets snap
	
	#all the code below changes some parameters which move_and_slide() does 
	
	#landing
	if was_in_air and is_on_floor():
		#prevents player from sliding on slopes
		motion.x = last_motion.x
		Utils.instance_scene_on_main(JumpEffect, global_position) #create jump effect
		double_jump = true
	
	#just left ground
	if was_on_floor and not is_on_floor() and not just_jumped:
		# eliminates any unexpected jumps
		motion.y = 0
		position.y = last_position.y
		coyoteJumpTimer.start()
	
	#prevent sliding (hack)
	if is_on_floor() and get_floor_velocity().length() == 0 and abs(motion.x) < 1:
		#if player on a ground and the ground doesn't move and player moves really slow he doesn't change his position
		position.x = last_position.x

func wall_slide_check():
	if not is_on_floor() and is_on_wall():
		state = WALL_SLIDE
		double_jump = true
		create_dust_effect()

func get_wall_axis():
	var is_right_wall = test_move(transform, Vector2.RIGHT) # returns true if there is collision on the right
	var is_left_wall = test_move(transform, Vector2.LEFT)
	# returns 0 is there is no collisions on left and right sides
	# returns 1 if there is a collision on the left side and -1 if it is on the other one
	return int(is_left_wall) - int(is_right_wall) 

func wall_slide_jump_check(wall_axis):
	if Input.is_action_just_pressed("ui_up"):
		motion.x = wall_axis * MAX_SPEED
		motion.y = -JUMP_FORCE/1.25
		state = MOVE
		
		var dust_position = global_position + Vector2(wall_axis*4, 0)
		var dust = Utils.instance_scene_on_main(WallDustEffect, dust_position)
		dust.scale.x = wall_axis

func wall_slide_drop(delta):
	var max_slide_speed = WALL_SLIDE_SPEED 
	# increases player's slide speed by pressing down
	if Input.is_action_pressed("ui_down"):
		max_slide_speed = MAX_WALL_SLIDE_SPEED
	# apply these forces 
	motion.y = min(motion.y + GRAVITY * delta, max_slide_speed)
	
func wall_detach(delta, wall_axis):
	if Input.is_action_just_pressed("ui_right"):
		motion.x = ACCELERATION * delta
		state = MOVE
	
	if Input.is_action_just_pressed("ui_left"):
		motion.x = -ACCELERATION * delta
		state = MOVE
	
	if wall_axis == 0 or is_on_floor():
		state = MOVE

func _on_HurtBox_hit(damage):
	if not invincible:
		PlayerStats.health -= damage
		blinkAnimator.play("Blink")

func _on_died():
	queue_free()
