extends Object

# PlayerPhysics
var host

func _init(_host) -> void:
	host = _host

func handle_ground_motion(slope:float = host.slp):
	var gsp_dir = sign(host.gsp)
	var abs_gsp = abs(host.gsp)
	var ground_angle = host.coll_handler.ground_angle();
	host.gsp -= slope * sin(ground_angle)
	abs_gsp = abs(host.gsp)
	gsp_dir = sign(host.gsp)
	
	if host.direction.x == 0:
		host.is_braking = false
		host.gsp -= min(abs_gsp, host.frc) * gsp_dir
		abs_gsp = abs(host.gsp)
		if abs_gsp < 0.1:
			host.smachine.change_state("Idle")

func handle_rolling_motion():
	var ground_angle = host.coll_handler.ground_angle()
	var abs_gsp = abs(host.gsp)
	var gsp_dir = sign(host.gsp)
	
	var slope : float
	if gsp_dir == sign(sin(ground_angle)):
		slope = -host.slp_roll_up
	else:
		slope = -host.slp_roll_down
	
	host.gsp += slope * sin(ground_angle)
	
	gsp_dir = sign(host.gsp)
	abs_gsp = abs(host.gsp)
	
	if host.direction.x != 0 and host.direction.x == -gsp_dir:
		if abs_gsp > 0 :
			var braking_dec : float = host.roll_dec
			host.gsp += braking_dec * host.direction.x
	else:
		host.gsp -= min(abs_gsp, host.frc / 2.0) * gsp_dir
	
	abs_gsp = abs(host.gsp)
	gsp_dir = sign(host.gsp)
	if host.constant_roll:
		if host.boost_constant_roll:
			if abs_gsp < 300:
				host.gsp += (host.top_roll - abs_gsp) * host.side * host.acc
				host.gsp = clamp(host.gsp, -300, 300)
		host.lock_control()

func handle_air_motion():
	if host.direction.x != 0:
		if abs(host.speed.x) < host.top:
			host.speed.x += host.air * host.direction.x
	
	if host.speed.y < 0 and host.speed.y > -240:
		host.speed.x -= (host.speed.x/7.5)/15360
	
	host.speed.y += host.grv
