extends Node2D

var world_c : Vector2i = Vector2i(0,0)#q,r,s
var dun_c : Vector2i = Vector2i(0,0)#q,r,s in submap
var d_level : int = -1#-1 = overworld, 0= surface, 1 is 1 below, etc
var sight_range : int = 5
var FOV : Array = []
var tile_id : int = 15
# Called when the node enters the scene tree for the first time.
func _ready():
	var vpRect = get_viewport_rect()
	self.position.x=vpRect.size.x/2
	self.position.y=vpRect.size.y/2
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
