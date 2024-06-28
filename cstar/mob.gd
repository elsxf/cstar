extends Object

const _def = preload("res://defines.gd")

var world_c:Vector3i
var dun_c:Vector3i
var d_level : int
var FOV = []
var sight_range = 1
var time_u : int
var Hp_max : int
var Hp : int
var attack : int

var t_data:TileData

var target_mob = null
var target_tile = null
var time_cost = 0


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
