extends Node2D


var m:Mob = Mob.new("Player")

# Called when the node enters the scene tree for the first time.
func _ready():
	var vpRect = get_viewport_rect()
	self.position.x=vpRect.size.x/2
	self.position.y=vpRect.size.y/2
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass
