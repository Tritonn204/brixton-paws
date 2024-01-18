extends Node2D
class_name PlayerStateMachine

signal state_changed(prev_state, current_state, host)

var _host_ready = false setget , is_host_ready
var state_collection:StateCollection = StateCollection.new() setget , get_state_collection
var host

export var initial_state:String = 'Regular'
onready var current_state = initial_state setget change_state

var last_state: String

func initialize(_host):
	host = _host
	state_collection.generate_states(get_children())
	change_state(initial_state)

func update_state(delta: float):
	var cur_state = get_current_state_node()
	if current_state:
		cur_state.step(host, delta) 

func animate_state(delta: float):
	var cur_state = get_current_state_node()
	if current_state:
		cur_state.animate(host, delta)

func get_current_state_node():
	#print(state_collection.has_state(current_state)) 
	if state_collection.has_state(current_state):
		return state_collection.get_state(current_state)

func change_state(state_name):
	assert(state_collection.has_state(state_name), "Error: State %s does not exist in current context" % state_name)
	if state_name == current_state:
		return
	
	#Exit 
	var cur_state = get_current_state_node()
	cur_state.exit(host)
	last_state = current_state
	current_state = state_name
	
	#Enter
	cur_state = get_current_state_node()
	cur_state.enter(host)
	
	
func get_state_collection() -> StateCollection: return state_collection

func is_host_ready() -> bool:
	return _host_ready
