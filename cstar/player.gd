extends Node2D

var world_c = Vector3i(0,0,0)#q,r,s
var dun_c = Vector3i(0,0,0)#q,r,s in submap
var d_level = -1#-1 = overworld, 0= surface, 1 is 1 below, etc
var sight_range = 5
# Called when the node enters the scene tree for the first time.
func _ready():
	var vpRect = get_viewport_rect()
	self.position.x=vpRect.size.x/2
	self.position.y=vpRect.size.y/2
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func curr_c():
	if(d_level==-1):
		return world_c
	else:
		return dun_c
