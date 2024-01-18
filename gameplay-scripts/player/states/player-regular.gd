extends PlayerState

class_name RegularPlayerState

func enter(host):
	host.set_bounds(0)

func step(host: Player, delta: float):
	host.handle_fall()
	host.handle_gravity(delta)
	host.handle_jump()
	host.handle_slope(delta)
	host.handle_acceleration(delta)
	host.handle_friction(delta)
	
	host.is_clinging = host.input_direction.y < 0

	if host.is_grounded():
#		if host.input_dot_velocity < 0 and abs(host.velocity.x) >= host.current_stats.min_speed_to_brake:
#			host.state_machine.change_state("Braking")
		pass
	else:
		host.state_machine.change_state("Airborne")

func animate(host, _delta: float):
	var absolute_speed = abs(host.velocity.x)
	
	host.skin.handle_flip(host.input_direction.x)
	host.skin.set_regular_animation_speed(absolute_speed)
	
	if absolute_speed >= 0.3:
		host.skin.set_running_animation_state(absolute_speed)
	else:
		host.skin.set_animation_state(PlayerSkin.ANIMATION_STATES.idle)
