extends Node
class_name MiddleStateManager
onready var state_collection : StateCollection = StateCollection.new() setget , get_state_collection

var current_state :String
var character

func character_ready(character_):
	character = character_
	state_collection.generate_states(get_children())

func disconnect_all_states(state_machine: StateMachine):
	for i in state_collection.get_states().values():
		i.disconnect("finished", state_machine, "change_state")

func connect_all_states(state_machine : StateMachine):
	for i in state_collection.get_states().values():
		i.connect("finished", state_machine, "change_state")

func is_valid_state(val : String):
	return state_collection.has_state(val)

func _middle_enter(host, prev_state, state, state_name:String) -> void:
	current_state = state_name
	state_collection.get_state(state_name).state_enter(host, prev_state, state)
	state_collection.get_state(state_name).connect("finished", host.smachine, "change_state", [], CONNECT_ONESHOT)

func _middle_exit(host, next_state, state, state_name:String) -> void:
	state_collection.get_state(state_name).state_exit(host, next_state, state)
	state_collection.get_state(state_name).disconnect("finished", host.smachine, "change_state")

func _middle_physics_process(host, delta, state, state_name:String) -> void:
	if state_collection.get_state(state_name).is_state_physics_processing():
		state_collection.get_state(state_name).state_physics_process(host, delta, state)

func _middle_process(host, delta, state, state_name:String) -> void:
	if state_collection.get_state(state_name).is_state_processing():
		state_collection.get_state(state_name).state_process(host, delta, state)

func _middle_animation_process(host, delta, animator, state, state_name:String) -> void:
	if state_collection.get_state(state_name).is_state_animation_processing():
		state_collection.get_state(state_name).state_animation_process(host, delta, animator, state)

func _middle_animation_finished(host, anim_name, state, state_name:String) -> void:
	if state_collection.get_state(state_name).is_state_animation_processing():
		state_collection.get_state(state_name).state_animation_finished(host, anim_name, state)

func _middle_animation_started(host, anim_name, state, state_name:String) -> void:
	if state_collection.get_state(state_name).is_state_animation_processing():
		state_collection.get_state(state_name).state_animation_started(host, anim_name, state)

func _middle_animation_changed(host, old_name:String, new_name:String, state, state_name:String) -> void:
	if state_collection.get_state(state_name).is_state_animation_processing():
		state_collection.get_state(state_name).state_animation_finished(host, old_name, new_name, state)

func _middle_input(host, event: InputEvent, state, state_name:String) -> void:
	state_collection.get_state(state_name).state_input(host, event, state)

func _middle_draw(host, state, state_name:String) -> void:
	state_collection.get_state(state_name).draw(host, state)

func get_state_collection() -> StateCollection: return state_collection
