extends Object

const _def = preload("res://defines.gd")
const _gen = preload("res://generation.gd")
const _hex = preload("res://hexFuncs.gd")
const _path = preload("res://pathfinding.gd")
const _mob = preload("res://mob.gd")

enum Move_Modes{WALK,HOVER,TELEPORT}

func move_horizontal(mob,Map:TileMap,target_tile:Vector2i,mode:int):
	var next_tile = Map.get_cell_tile_data(0,_hex.axial_to_oddr(Vector3i(_hex.oddr_to_axial(mob.curr_c()))+next_move))
	if(next_tile!=null):
		next_move_cost = next_tile.get_custom_data("M_Cost")
		if next_move_cost!=-1:
			#move player
			if($Player.d_level==-1):
				$Player.world_c=_hex.axial_to_oddr(Vector3i(_hex.oddr_to_axial($Player.world_c)) + next_move)
				#print($Player.world_c)
			else:
				$Player.dun_c=_hex.axial_to_oddr(Vector3i(_hex.oddr_to_axial($Player.dun_c)) + next_move)
				#print($Player.dun_c)
	pass

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
