#extends KinematicBody2D
#
#class_name PlayerPhysics
#
##imports
#const COLLISION_HANDLER = preload("res://assets/gameplay-scripts/collision-handler.gd")
#const MOTION_HANDLER = preload("res://assets/gameplay-scripts/motion-handler.gd")
#
#enum Side{
#	LEFT=-1, RIGHT=1
#}
#
#var ground_ray : RayCast2D
#var direction : Vector2 = Vector2.ZERO
#var up_direction : Vector2 = Vector2.UP
#var prev_position : Vector2
#var speed : Vector2
#var ground_mode : int
#var is_ray_colliding : bool
#var gsp : float
#var is_grounded : bool
#var control_locked : bool
#var ground_point : Vector2
#var ground_normal : Vector2
#var can_fall : bool
#var snaps : float = 15
#var snap_margin = snaps
#var has_jumped : bool
#var player_index: int
#var is_floating : bool
#var is_braking : bool
#var spring_loaded : bool
#var spring_loaded_v : bool
#var was_damaged : bool
#var suspended_jump : bool = false
#var suspended_can_right : bool = true
#var suspended_can_left : bool = true
#var tsincegrounded : float = 0
#
#var side : int setget set_side, get_side
#
#export (float) var slp
#export (float) var slp_roll_up
#export (float) var slp_roll_down
#export (float) var acc
#export (float) var dec
#export (float) var roll_dec
#export (float) var frc
#export (float) var top
#export (float) var top_roll
#export (float) var jmp
#export (float) var fall
#export (float) var air
#export (float) var grv
#export (float) var cliffspeed
#
#
#onready var character = $Character
#onready var smachine : = $StateMachine
#onready var char_state_manager := $MSM
#onready var sprite := $Character/Kitty/Sprite
#onready var main_collider:CollisionPolygon2D = $MainCollider
#onready var char_default_collision := get_node("Character/Kitty/CollisionContainer/Default")
#
#const control_unlock_time_normal = .5
#onready var control_unlock_timer : Timer = $ControlUnlockTimer
#
#onready var ground_sensors_container:Node2D = $GroundSensors
#onready var left_ground := $GroundSensors/LeftGroundRay as RayCast2D
#onready var middle_ground := $GroundSensors/MiddleGroundRay as RayCast2D
#onready var right_ground := $GroundSensors/RightGroundRay as RayCast2D
#
#onready var m_handler:MOTION_HANDLER = MOTION_HANDLER.new(self)
#onready var coll_handler := COLLISION_HANDLER.new(self)
#
## Called when the node enters the scene tree for the first time.
#func _ready():
#	set_physics_process(false)
#	set_process(false)
#	smachine._on_host_ready(self)
#
#func _physics_process(delta: float) -> void:
#	smachine._sm_physics_process(delta)
#	coll_handler.step_collision(delta)
#	speed = move_and_slide_preset()
#	if is_grounded:
#		ground_sensors_container.global_rotation = -coll_handler.ground_angle()
#	else:
#		ground_sensors_container.global_rotation = 0
#
#	if is_on_floor():
#		is_grounded = true
#	ground_ray = coll_handler.get_ground_ray()
#	is_ray_colliding = ground_ray != null
#	if ground_ray and is_ray_colliding:
#		tsincegrounded = 0
#		if Utils.Collision.is_collider_oneway(ground_ray, ground_ray.get_collider()) and ground_mode != 0:
#			ground_normal = ground_ray.get_collision_normal()
#			ground_mode = 0
#			return
#		ground_normal = Utils.Collision.get_collider_normal_precise(ground_ray, ground_mode)
#		ground_mode = int(round(coll_handler.ground_angle() / (PI * 0.5))) % 4
#		ground_mode = 2 if ground_mode == -2 else ground_mode
#	else:
#		ground_mode = 0
#		ground_normal = Vector2(0, -1)
#		is_grounded = false
#		tsincegrounded += delta
#
#
##	is_wall_left = coll_handler.is_colliding_on_wall(left_wall) or coll_handler.is_colliding_on_wall(left_wall_bottom)
##	is_wall_right = coll_handler.is_colliding_on_wall(right_wall) or coll_handler.is_colliding_on_wall(right_wall_bottom)
##	if player_camera: 
##		is_wall_left = is_wall_left or global_position.x- Utils.Collision.get_width_of_shape(main_collider.shape) - player_camera.camera.limit_left <= 0
##		is_wall_right = is_wall_right or global_position.x+9 - player_camera.camera.limit_right >= 0
#
#func _process(delta : float) -> void:
#	smachine._sm_process(delta)
#	character.global_position = global_position
#	character.z_index = z_index
#	character.visible = visible
#
#func lock_control(time:float = control_unlock_time_normal) -> void:
##	control_locked = true
##	control_unlock_timer.start(time)
#	pass
#
#func unlock_control() -> void:
##	control_locked = false
##	control_unlock_timer.stop()
#	pass
#
#func set_side(val : int) -> void:
#	side = val
#	character.scale.x = side
#
#func get_side() -> int:
#	if character and character.scale.x != 0:
#		return int(sign(character.scale.x))
#	return 1
#
#func move_and_slide_preset(val = null) -> Vector2:
#	var top_collide:Vector2 = Vector2(sin(rotation), -cos(rotation))
#	#var fways:Vector2 = Utils.angle2Vec2(Utils.rad2dir(top_collide.angle_to(Vector2.LEFT), 4))
#	var tess = clamp(abs(gsp)/cliffspeed,0,1)
#	if (!is_grounded):
#		tess = 0
#	var bottom_snap:Vector2 = Vector2(sin(top_collide.angle() + deg2rad(45*tess)), cos(top_collide.angle() + deg2rad(45*tess)))
##	if (is_grounded and abs(gsp) > cliffspeed): bottom_snap = Vector2.ZERO
#	print(rad2deg(top_collide.angle()))
#	print(rad2deg(top_collide.angle() + deg2rad(10)))
#
#	return move_and_slide_with_snap(
#		speed if !val else val,
#		Vector2(0, 20),
#		bottom_snap,
#		true,
#		4,
#		deg2rad(45),
#		true
#	)
#
#func reset_snap():
#	snap_margin = snaps
#
#func erase_snap():
#	snap_margin = 0
#
#func _unhandled_input(event: InputEvent) -> void:
#	var action_chk = funcref(Utils.UInput, "is_action")
#	if !control_locked:
#		var game_left = 'game_left'
#		var game_right = 'game_right'
#		if action_chk.call_func(game_left) or action_chk.call_func(game_right):
#			direction.x = Input.get_axis(game_left, game_right)
#	else:
#		direction.x = 0.0
#
##	var ui_up = 'game_up'
##	var ui_down = 'game_down'
##	if action_chk.call_func(ui_up) or action_chk.call_func(ui_down):
##		direction.y = Input.get_axis(ui_up, ui_down)
#
#	smachine._sm_input(event)
