extends Resource
class_name StateCollection

var _states : Dictionary

func generate_states(list:Array) -> void:
	for i in list:
		_states[i.name] = i

func get_state(state_name:String): return _states[state_name]

func has_state(state_name:String) -> bool: return _states.has(state_name)

func get_states() -> Dictionary: return _states

func add_state(name:String, state:PlayerState):
	if _states.has(state): return
	_states[name] = state

func remove_state(state:String) -> void: 
	if has_state(state):
		var st = get_state(state)
		_states.erase(state)
		st.queue_free()
