#extends PlayerStateMachine
#
#func _enter_tree() -> void:
#	set_physics_process(false)
#	set_process_input(false)
#	set_process(false)
#
#func _ready() -> void:
#	set_physics_process(false)
#	set_process_input(false)
#	set_process(false)
#
#func get_current_state_node():
#	if state_collection and state_collection.has_state(current_state):
#		return state_collection.get_state(current_state)
#
#func is_current_state(name:String) -> bool:
#	return current_state == name
#
#func _sm_physics_process(delta):
#	var cur_state = get_current_state_node()
#	if state_collection.has_state(current_state) and cur_state.is_state_physics_processing():
#		cur_state.state_physics_process(host, delta)
#		cur_state = get_current_state_node()
#
##	if host.char_state_manager.is_valid_state(current_state):
##		host.char_state_manager._middle_physics_process(host, delta, cur_state, current_state)
#
#	host.prev_position = host.position
#
#
#func _sm_process(delta): 
#	var cur_state = get_current_state_node()
#	if state_collection.has_state(current_state) and cur_state.is_state_processing():
#		cur_state.state_process(host, delta)
#		cur_state = get_current_state_node()
#
##		if !host.play_specific_anim and cur_state.is_state_animation_processing():
##			cur_state.state_animation_process(host, delta, host.animation)
#
#	if host.char_state_manager.is_valid_state(current_state):
#		host.char_state_manager._middle_process(host, delta, get_current_state_node(), current_state)
#		cur_state = get_current_state_node()
##		if !host.play_specific_anim:
##			host.char_state_manager._middle_animation_process(host, delta, host.animation, cur_state, current_state)
##	if host.player_camera:
##		if host.player_camera.enabled:
##			host.player_camera.camera_step(host, delta)
#
#func _sm_input(event:InputEvent):
#	var cur_state = get_current_state_node()
#	if state_collection.has_state(current_state):
#		cur_state.state_input(host, event)
#
#	cur_state = get_current_state_node()
#	if host.char_state_manager.is_valid_state(current_state):
#		host.char_state_manager._middle_input(host, event, cur_state, current_state)
