extends Node

class_name GoUtils

const SHALLOW_ANGLE = 23
const HALF_STEEP_ANGLE = 45

static func get_angle_from(normal: Vector2) -> float:
	var radians = normal.angle_to(Vector2.UP)
	return -rad2deg(radians)

static func ground_to_global_velocity(velocity, normal) -> Vector2:
	var x_speed = velocity.x * -normal.y + velocity.y * -normal.x
	var y_speed = velocity.x * normal.x - velocity.y * normal.y
	return Vector2(x_speed, y_speed)

static func global_to_ground_velocity(velocity, normal, wall_jump_landing = false, flipped = false) -> Vector2:
	var x_speed = velocity.x
	var angle = abs(get_angle_from(normal))

	if angle > SHALLOW_ANGLE:
		var direction = sign(normal.x)

		x_speed = velocity.y * direction
			
		if wall_jump_landing: 
			x_speed = 5000
			if (flipped): x_speed *= -1
#			print(x_speed, " | ", velocity.length())

	return Vector2(x_speed, 0)
