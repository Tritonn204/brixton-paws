extends Camera2D

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

export (NodePath) var TargetNodepath = null
export (float) var lerpspeed = 1
export (Vector2) var zoomrange = Vector2(0.5,3.5)
export (float) var defaultzoom = 0.5

var target_zoom = Vector2(defaultzoom, defaultzoom)

onready var target_node = get_node(TargetNodepath)
# Called when the node enters the scene tree for the first time.
func _ready():
	zoom = Vector2(defaultzoom,defaultzoom)
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):

	target_zoom.x = clamp(target_zoom.x, zoomrange.x, zoomrange.y) 
	target_zoom.y = clamp(target_zoom.y, zoomrange.x, zoomrange.y)
	
	if Input.is_action_just_released("zoom_in"):
		target_zoom -= Vector2(0.1, 0.1)

	if Input.is_action_just_released("zoom_out"):  
		target_zoom += Vector2(0.1, 0.1)

		
	if zoom != target_zoom:
		$Tween.interpolate_property(self, "zoom", zoom, target_zoom, 0.5)
		$Tween.start()
		
	var target_position = target_node.position
	self.position  = lerp(self.position, target_position, 1 - pow(lerpspeed, delta))
