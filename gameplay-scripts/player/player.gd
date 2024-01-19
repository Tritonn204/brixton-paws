extends Node2D

class_name Player

signal ground_enter

export(Array, Resource) var bounds
export(Array, Resource) var stats

export(int, LAYERS_2D_PHYSICS) var wall_layer = 1
export(int, LAYERS_2D_PHYSICS) var ground_layer = 1
export(int, LAYERS_2D_PHYSICS) var ceiling_layer = 1

onready var skin = $Skin as PlayerSkin
onready var state_machine = $StateMachine as PlayerStateMachine
onready var right_paw_ray = $Skin/AirRayContainer/RightRay 
onready var left_paw_ray = $Skin/AirRayContainer/LeftRay
#onready var shields = $Shields as ShieldsManager
#onready var audios = $Audios as PlayerAudio

onready var initial_parent = get_parent()

var world : World2D
var current_bounds : PlayerCollision
var current_stats : PlayerStats

var collider : Area2D
var check_collider : Area2D
var collider_shape : RectangleShape2D
var check_collider_shape : RectangleShape2D

#physics timers
var time_since_jump = 1000
var time_since_fall = 1000
var time_since_wall_landing = 1000

var velocity : Vector2
var prev_velocity : Vector2
var ground_normal : Vector2
var input_direction : Vector2

var ground_angle : float
var absolute_ground_angle : float
var input_dot_velocity: float
var control_lock_timer : float

var limit_left: float
var limit_right: float

var is_jumping : bool
var is_wall_jumping : bool
var is_rolling : bool
var is_control_locked : bool
var is_locked_to_limits: bool
var is_clinging : bool

var __is_grounded : bool

func _ready():
	initialize_collider()
	initialize_resources()
	initialize_state_machine()
	initialize_skin()

func _physics_process(delta):
	prev_velocity = velocity
	increment_timers(delta)
	handle_input()
	handle_control_lock(delta)
	handle_state_update(delta)
	handle_overlap(delta)
	handle_motion(delta)
	handle_limits()
	handle_state_animation(delta)
	handle_skin(delta)

func initialize_collider():
	var collision = CollisionShape2D.new()
	collider_shape = RectangleShape2D.new()
	collider = Area2D.new()
	collision.shape = collider_shape
	collider.add_child(collision)
	
#	var check_collision = CollisionShape2D.new()
#	check_collider = Area2D.new()
#	check_collider_shape = RectangleShape2D.new()
#	check_collision.shape = collider_shape
#	check_collider.add_child(check_collision)
#
	add_child(collider)
#	add_child(check_collider)

func initialize_resources():
	world = get_world_2d()
	set_bounds(0)
	set_stats(0)
 
func initialize_state_machine():
	state_machine.initialize(self)

func initialize_skin():
	remove_child(skin)
	get_tree().root.call_deferred("add_child", skin)

func get_position():
	var y_offset = transform.y * current_bounds.offset.y
	var x_offset = transform.x * current_bounds.offset.x
	return global_position + y_offset + x_offset

func set_bounds(index: int):
	if index >= 0 and index < bounds.size():
		var last_bounds = current_bounds
		current_bounds = bounds[index]
		collider_shape.extents.x = current_bounds.width_radius + current_bounds.push_radius
		collider_shape.extents.y = current_bounds.height_radius
		position -= current_bounds.offset
		
		if last_bounds and last_bounds != current_bounds:
			position += last_bounds.offset

func set_stats(index: int):
	if index >= 0 and index < stats.size():
		current_stats = stats[index]


func is_grounded():
	return __is_grounded and velocity.y >= 0

func handle_state_update(delta: float):
	state_machine.update_state(delta)

func handle_motion(delta: float):
	var offset = velocity.length() * delta
	var max_motion_size = current_bounds.width_radius
	var motion_steps = ceil(offset / max_motion_size)
	var step_motion = velocity / motion_steps

	while motion_steps > 0:
		apply_motion(step_motion, delta)
		handle_collision(delta)
		motion_steps -= 1

func handle_collision(delta: float):
	handle_wall_collision(delta)
	handle_ground_collision(delta)
	handle_ceiling_collision(delta)

func handle_limits():
	if is_locked_to_limits:
		var offset = current_bounds.width_radius
		if global_position.x + offset > limit_right:
			global_position.x = limit_right - offset
			velocity.x = 0
		if global_position.x - offset < limit_left:
			global_position.x = limit_left + offset
			velocity.x = 0

func handle_state_animation(delta):
	state_machine.animate_state(delta)

func handle_skin(delta):
	skin.position = global_position

	var speedfactor = (1-clamp(velocity.x/current_stats.top_speed,0.5,1))*720

	if not __is_grounded:
		var current_rotation = skin.rotation_degrees
		if (is_jumping):
			var dir = -1 if skin.flip_h else 1
			if is_wall_jumping:
				dir *= -1
				skin.rotation_degrees = move_toward(current_rotation, ground_angle-dir*60 + 180,360)
			else:
				skin.rotation_degrees = move_toward(current_rotation, ground_angle-dir*60, 720 * delta)
		elif (not is_clinging):
			skin.rotation_degrees = move_toward(current_rotation, 0, speedfactor * delta)
	else:
		var current_rotation = skin.rotation_degrees
		var target = stepify(ground_angle,5)
		if abs(current_rotation - target) > 180: skin.rotation_degrees = target
		else:
			skin.rotation_degrees = move_toward(current_rotation, stepify(rotation_degrees,5), 720 * delta)

func handle_wall_collision(delta : float):
	var ray_size = current_bounds.width_radius + current_bounds.push_radius
	var origin = global_position + transform.y * current_bounds.push_height_offset if __is_grounded and absolute_ground_angle < 10 else global_position
	var right_ray = GoPhysics.cast_ray(world, origin, transform.x, ray_size, [self], wall_layer)
	var left_ray = GoPhysics.cast_ray(world, origin, -transform.x, ray_size, [self], wall_layer)
	
	if !__is_grounded and time_since_jump > 0.125 and (time_since_fall > 0.4 or is_clinging):
		var paw_hit = left_paw_ray if left_paw_ray.is_colliding() and skin.flip_h else right_paw_ray  if right_paw_ray.is_colliding() and !skin.flip_h else null

		if paw_hit:
			var wall_normal = paw_hit.get_collision_normal()
			var wall_collider = paw_hit.get_collider()
			var wall_position = paw_hit.get_collision_point()
			
			var surface_angle = rad2deg(wall_normal.angle())+90
			
			var ground_data = {
				"normal": wall_normal,
				"collider": wall_collider,
				"position": wall_position,
				"penetration": 0
			}
			
			var dot = velocity.dot(wall_normal)
			var angle = acos(dot / (velocity.length() * wall_normal.length()))
	  
			if abs(surface_angle) >= 80 and angle >= deg2rad(45) and angle <= deg2rad(135):
				# Wall landing logic
				print("wall landing")
				time_since_wall_landing = 0
				set_ground_data(wall_normal) 
				
				set_bounds(0)
				enter_ground(ground_data, 1)
				rotate_to(ground_angle, 1)
				
				is_clinging = true

	if right_ray or left_ray:
		if right_ray:
			handle_contact(right_ray.collider, "player_right_wall_collision")
			
			if not right_ray.collider is SolidObject or right_ray.collider.is_enabled():
				velocity.x = min(velocity.x, 0)
				position -= transform.x * (right_ray.penetration + GoPhysics.EPSILON)
		
		if left_ray:
			handle_contact(left_ray.collider, "player_left_wall_collision")
			
			if not left_ray.collider is SolidObject or left_ray.collider.is_enabled():
				velocity.x = max(velocity.x, 0)
				position += transform.x * (left_ray.penetration + GoPhysics.EPSILON)

func increment_timers(delta : float):
	time_since_jump += delta
	time_since_fall += delta
	time_since_wall_landing += delta

func handle_ceiling_collision(delta: float):
	var ray_size = current_bounds.height_radius
	var ray_offset = transform.x * current_bounds.width_radius
	var hits = GoPhysics.cast_parallel_rays(world, global_position, ray_offset, -transform.y, ray_size, [self], ceiling_layer)
	
	if hits and velocity.y <= 0:
		handle_contact(hits.closest_hit.collider, "player_ceiling_collision")
		
		if not __is_grounded and (not hits.closest_hit.collider is SolidObject or hits.closest_hit.collider.is_enabled()):
			var ceiling_normal = hits.closest_hit.normal
			var ceiling_angle = GoUtils.get_angle_from(ceiling_normal)

			if abs(ceiling_angle) < 135:
				set_ground_data(ceiling_normal)
				rotate_to(ceiling_angle, delta)
				enter_ground(hits.closest_hit, delta)
			else:
				velocity.y = 0
		
			position += transform.y * hits.closest_hit.penetration

func handle_ground_collision(delta: float):
	var ray_offset = transform.x * current_bounds.width_radius
	var dynamic_ground_extension = get_ground_extension(velocity.length(), current_stats.min_speed_to_detach)
	var ray_size = current_bounds.height_radius + dynamic_ground_extension if __is_grounded else current_bounds.height_radius
	var hits = GoPhysics.cast_parallel_rays(world, global_position, ray_offset, transform.y, ray_size, [self], ground_layer)

	if hits and velocity.y >= 0:
		handle_contact(hits.closest_hit.collider, "player_ground_collision")
		
		if not hits.closest_hit.collider is SolidObject or hits.closest_hit.collider.is_enabled():
			if not __is_grounded and velocity.y >= 0:
				set_ground_data(hits.closest_hit.normal)
				position -= transform.y * hits.closest_hit.penetration
				enter_ground(hits.closest_hit, delta)
			elif hits.left_hit or hits.right_hit:
				var safe_distance = hits.closest_hit.penetration - dynamic_ground_extension
				set_ground_data(hits.closest_hit.normal)
				rotate_to(ground_angle, delta)
				position -= transform.y * safe_distance
	else:
		exit_ground()

func handle_overlap(delta : float):
	var direction = transform.y
	var origin = global_position

	var offset = transform.x * (current_bounds.width_radius*0.8)
	var length = current_bounds.height_radius - 2

	var rays = GoPhysics.cast_spread_rays(world, origin, direction, length, 7, offset)
	var deepest = null
	for ray in rays:
		if ray:
			deepest = ray if !deepest or deepest.penetration < ray.penetration else deepest
			
	if time_since_jump > 0.15 and time_since_wall_landing > 0.2 and deepest and !(is_clinging and deepest.penetration < length*0.8):
#		print("deep collision")
		set_ground_data(deepest.normal)
		position -= direction * (deepest.penetration + 2)
		velocity *= transform.y.normalized()
		enter_ground(deepest, delta)

	
func handle_contact(static_body: StaticBody2D, signal_name: String):
	if static_body is SolidObject:
		static_body.emit_signal(signal_name, self)

func handle_platform(platform_collider: StaticBody2D):
#	if __is_grounded and platform_collider is MovingPlatform:
#		reparent(platform_collider)
#	else:
		reparent(initial_parent)

func apply_motion(desired_velocity: Vector2, delta: float):
	if __is_grounded:
		var global_velocity = GoUtils.ground_to_global_velocity(desired_velocity, ground_normal)
		position += global_velocity * delta
	else:
		position += desired_velocity * delta

func set_ground_data(normal: Vector2 = Vector2.UP):
	ground_normal = normal
	ground_angle = GoUtils.get_angle_from(normal)
	absolute_ground_angle = abs(ground_angle)

func rotate_to(angle: float, delta: float):
	var closest_angle = stepify(angle, 1)
	rotation_degrees = move_toward(rotation_degrees, closest_angle,  360 * delta)

func handle_input():
	var right = Input.is_action_pressed("player_right")
	var left = Input.is_action_pressed("player_left")
	var up = Input.is_action_pressed("player_up")
	var down = Input.is_action_pressed("player_down")
	var horizontal = 1 if right else (-1 if left else 0)
	var vertical = 1 if up else (-1 if down else 0)

	horizontal = 0 if is_control_locked else horizontal
	input_direction = Vector2(horizontal, vertical)
	input_dot_velocity = input_direction.dot(velocity)

func lock_controls():
	if not is_control_locked:
		input_direction.x = 0
		is_control_locked = true
		control_lock_timer = current_stats.control_lock_duration

func unlock_controls():
	if is_control_locked:
		is_control_locked = false
		control_lock_timer = 0

func handle_control_lock(delta: float):
	if is_control_locked:
		input_direction.x = 0
		if __is_grounded:
			control_lock_timer -= delta
			if abs(velocity.x) == 0 or control_lock_timer <= 0:
				unlock_controls()

func handle_fall():
	var dynamic_slide_angle = current_stats.cling_slide_angle if is_clinging else current_stats.slide_angle
	if __is_grounded and time_since_wall_landing > current_stats.wall_grace_period and absolute_ground_angle > dynamic_slide_angle and abs(velocity.x) <= current_stats.min_speed_to_fall:
		lock_controls()

		if not is_clinging and absolute_ground_angle > current_stats.fall_angle:
			time_since_fall = 0
			exit_ground()

func handle_slope(delta: float):
	if __is_grounded:
		var down_hill = velocity.dot(ground_normal) > 0
		var rolling_factor = current_stats.slope_roll_down if down_hill else current_stats.slope_roll_up
		var amount = rolling_factor if is_rolling else current_stats.cling_slope_factor if is_clinging else current_stats.slope_factor
#		velocity.x += amount * ground_normal.x * delta

func handle_gravity(delta: float):
	if not __is_grounded:
		velocity.y += current_stats.gravity * delta

func handle_acceleration(delta: float):
	if input_direction.x != 0:
		if sign(input_direction.x) == sign(velocity.x) or not __is_grounded:
			var amount = current_stats.cling_acceleration if is_clinging and __is_grounded else current_stats.acceleration if __is_grounded else current_stats.air_acceleration
			
			if abs(velocity.x) < current_stats.top_speed:
				velocity.x += input_direction.x * amount * delta
				velocity.x = clamp(velocity.x, -current_stats.top_speed, current_stats.top_speed)
		else:
			velocity.x += input_direction.x * current_stats.deceleration * delta

func handle_deceleration(delta: float):
	if input_direction.x != 0 and sign(input_direction.x) != sign(velocity.x):
		var amount = current_stats.roll_deceleration if is_rolling else current_stats.deceleration
		velocity.x = move_toward(velocity.x, 0, amount * delta)

func handle_friction(delta: float):
	if __is_grounded and (input_direction.x == 0 or is_rolling):
		var amount = current_stats.cling_friction if is_clinging else current_stats.control_lock_friction if is_control_locked else current_stats.friction
		velocity.x = move_toward(velocity.x, 0, amount * delta)

func wall_jump(factor : float):
	print(velocity)
	is_wall_jumping = true
	var direction = -1 if skin.flip_h else 1
	var vertical_scale = 1.0 - current_stats.wall_jump_direction_blend
	var horizontal_scale = current_stats.wall_jump_direction_blend
	velocity.x += current_stats.max_jump_height*direction*horizontal_scale*factor
	velocity.y += -current_stats.max_jump_height*vertical_scale*factor
	skin.flip_h = !skin.flip_h
	print(velocity)

func handle_jump():
	if __is_grounded and Input.is_action_just_pressed("player_a"):
		is_jumping = true
		time_since_jump = 0 # reset jump timer
		is_rolling = true
#		audios.jump_audio.play()
		
		# Wall jump influence
		if time_since_wall_landing < 0.3:
			wall_jump(1.1)
		elif abs(ground_angle) >= 80:
			var speed_check = (velocity.x > 150 and !skin.flip_h) or (velocity.x < -150 and skin.flip_h)
			if is_clinging and abs(velocity.x) < 50:
				wall_jump(1.1)
			elif !is_clinging and speed_check:
				wall_jump(1.5)
			else:
				velocity.y = -current_stats.max_jump_height
		else:
			velocity.y = -current_stats.max_jump_height

	if is_jumping and Input.is_action_just_released("player_a") and velocity.y < -current_stats.min_jump_height:
		velocity.y = -current_stats.min_jump_height

func lock_to_limits(left: float, right: float):
	limit_left = left
	limit_right = right
	is_locked_to_limits = true

func reparent(new_parent: Node):
	var current_parent = get_parent()
	if new_parent != current_parent:
		var old_transform = global_transform
		current_parent.remove_child(self)
		new_parent.add_child(self)
		global_transform = old_transform
		
func get_ground_extension(speed: float, top_speed: float) -> float:
	if (!is_clinging):
		return current_bounds.min_ground_extension
	var speed_ratio = clamp(floor(abs(speed)) / top_speed, 0, 1)
	var margin = current_bounds.ground_extension - current_bounds.min_ground_extension
	var result = current_bounds.ground_extension - (margin * speed_ratio)
	return result

func enter_ground(ground_data: Dictionary, delta : float):
	if not __is_grounded:
		var wall_jump_landing = is_wall_jumping
		is_jumping = false
		is_wall_jumping = false
		is_rolling = false
		__is_grounded = true
		velocity = GoUtils.global_to_ground_velocity(velocity, ground_normal, wall_jump_landing, skin.flip_h)
#		print(velocity)
		rotate_to(rad2deg(ground_normal.angle())+90, delta)
		handle_platform(ground_data.collider)
		emit_signal("ground_enter")

func exit_ground():
	if __is_grounded:
		__is_grounded = false
		reparent(initial_parent)
		velocity = GoUtils.ground_to_global_velocity(velocity, ground_normal)
		rotate_to(0, 1)
	
func _draw():
	var ground_ray_size = current_bounds.height_radius + get_ground_extension(velocity.length(), current_stats.min_speed_to_detach) if __is_grounded else current_bounds.height_radius
#	var horizontal_origin = Vector2.ZERO - Vector2.UP * current_bounds.push_height_offset if __is_grounded and absolute_ground_angle < 1 else Vector2.ZERO
#
#	draw_line(horizontal_origin, horizontal_origin + Vector2.RIGHT * (current_bounds.width_radius + current_bounds.push_radius), Color.crimson)
#	draw_line(horizontal_origin, horizontal_origin - Vector2.RIGHT * (current_bounds.width_radius + current_bounds.push_radius), Color.hotpink)
#	draw_line(Vector2.RIGHT * current_bounds.width_radius, Vector2.RIGHT * current_bounds.width_radius - Vector2.UP * ground_ray_size, Color.cyan)
#	draw_line(-Vector2.RIGHT * current_bounds.width_radius, -Vector2.RIGHT * current_bounds.width_radius - Vector2.UP * ground_ray_size, Color.green)
#	draw_line(Vector2.RIGHT * current_bounds.width_radius, Vector2.RIGHT * current_bounds.width_radius + Vector2.UP * current_bounds.height_radius, Color.yellow)
#	draw_line(-Vector2.RIGHT * current_bounds.width_radius, -Vector2.RIGHT * current_bounds.width_radius + Vector2.UP * current_bounds.height_radius, Color.blue)
	var origin = global_position
	var direction = Vector2.DOWN

	var offset = transform.x * (current_bounds.width_radius*0.8)
	var length = current_bounds.height_radius

	var rays = GoPhysics.draw_spread_rays(origin, direction, length, 7, offset)
	for ray in rays:
		draw_line(ray.from - global_position, ray.to - global_position, Color.yellow)
