extends Object

var host

func _init(_host) -> void: host = _host

func step_collision(delta):
	setup_collision()
#	check_if_can_break()
	
func setup_collision():
	host.main_collider.polygon = host.char_default_collision.polygon
	host.main_collider.global_position = host.char_default_collision.global_position
#	host.attack_shape.shape = host.selected_character_node.current_attack_shape.shape
#	host.attack_shape.position = host.selected_character_node.current_attack_shape.position
#	host.hitbox_shape.shape = host.main_collider.shape
#	host.hitbox_shape.position = host.main_collider.position
	pass

func get_ground_ray() -> RayCast2D:
	host.can_fall = true
	
	if !host.left_ground.is_colliding() && !host.right_ground.is_colliding():
		return null
	elif !host.left_ground.is_colliding() && host.right_ground.is_colliding():
		return host.right_ground
	elif !host.right_ground.is_colliding() && host.left_ground.is_colliding():
		return host.left_ground
	
	host.can_fall = false
	
	var left_point : float
	var right_point : float
	
	var l_relative_point : Vector2 = host.left_ground.get_collision_point() - host.position
	var r_relative_point : Vector2 = host.right_ground.get_collision_point() - host.position
	
	left_point = sin(host.rotation) * l_relative_point.x + cos(host.rotation) + l_relative_point.y
	right_point = sin(host.rotation) * r_relative_point.x + cos(host.rotation) + r_relative_point.y

	if left_point <= right_point:
		return host.left_ground
	else:
		return host.right_ground

func snap_to_ground() -> void:
	var ground_ang = ground_angle()
	
	#var g_angle_final = ground_ang
	#host.previous_rotation = host.rotation
	host.rotation = -ground_ang
	host.speed += -host.ground_normal * 150

func ground_reacquisition() -> void:
	var ground_angle = ground_angle();
	var angle_speed : Vector2
	angle_speed.x = cos(ground_angle) * host.speed.x
	angle_speed.y = -sin(ground_angle) * host.speed.y
	var converted_speed = angle_speed.x + angle_speed.y
	host.gsp = converted_speed

func ground_angle() -> float:
	return host.ground_normal.angle_to(Vector2(0, -1))

func is_on_ground() -> bool:
	var ground_ray = get_ground_ray()
	if ground_ray != null:
		var point = ground_ray.get_collision_point()
		var normal = ground_ray.get_collision_normal()
		if abs(rad2deg(normal.angle_to(Vector2(0, -1)))) < 90:
			var player_pos = host.global_position.y+ 10 + (Utils.Collision.get_height_of_shape(host.main_collider.shape))
			var to_return = player_pos > point.y
			return to_return
	
	return false

func fall_from_ground() -> bool:
	if should_slip():
		
		var deg_angle = rad2deg(ground_angle())
		var angle = abs(deg_angle)
		var r_angle = round(angle)
		
		host.lock_control()
		if r_angle >= 90 and r_angle <= 180:
			host.ground_mode = 0
			return true
		else:
			host.gsp += 2.5 * Utils.Math.bool_sign((deg_angle + 180) < 180)
	return false

func should_slip() -> bool:
	if abs(host.gsp) < host.fall and host.ground_mode != 0:
		return true
	return false
