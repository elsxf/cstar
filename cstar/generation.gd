extends Object

const _def = preload("res://defines.gd")
const _path = preload("res://pathfinding.gd")

static var save_seed
static var overworld_noise = FastNoiseLite.new()

static func gen_overworld(chunk_coord: Vector2i, chunk:TileMap):
	for i in range(_def.chunk_size):
		for j in range(_def.chunk_size):
			#var coord = chunkCoords * _def.chunk_size + Vector2(i,j)
			var coord = Vector2(i,j)
			var value = overworld_noise.get_noise_2dv(coord)
			value = clamp(int((value*4+1) * (_def.over_t_dat.size())/2),0,_def.over_t_dat.size()-1)
			chunk.set_cell(_def.Layer_Names.Terrain,Vector2(i,j),_def.over_t_dat[value][0],Vector2(0,0))
	return chunk
	
static func gen_surface():
	pass

static func gen_dungeon(chunk:TileMap):
	var wall_hex=_def.dun_t_dat[_def.Under_tile_names.Cave_Wall][_def.T_data_cols.Scource]
	var floor_hex=_def.dun_t_dat[_def.Under_tile_names.Cave_Floor][_def.T_data_cols.Scource]
	for i in range(_def.chunk_size):
		for j in range(_def.chunk_size):
			chunk.set_cell(_def.Layer_Names.Terrain,Vector2(i,j),wall_hex,Vector2(0,0))
	var num_rooms = randi_range(5,15)
	var room_loc=[]
	var room_size=[]
	for i in range(num_rooms):#generate room sizes
		room_size.append(randi_range(7,15))
	for i in range(num_rooms):#generate room locations
		var maxRange = _def.chunk_size-room_size[i]-1
		var x = randi_range(1, maxRange)
		var y = randi_range(1, maxRange)
		room_loc.append(Vector2i(x,y))
	for v in range(room_loc.size()):#place rooms
		for i in range(room_size[v]):
			for j in range(room_size[v]):
				chunk.set_cell(_def.Layer_Names.Terrain,room_loc[v]+Vector2i(i,j),floor_hex,Vector2(0,0))
	for i in range(num_rooms):#connect rooms
		var path = _path.pathFind(room_loc[i],room_loc[(i+1)%num_rooms],chunk, _path.Astar_modes.Tunnel)
		for j in path:
			chunk.set_cell(_def.Layer_Names.Terrain,j,floor_hex,Vector2(0,0))
	return chunk
	


# Called when the node enters the scene tree for the first time.

static func init_random(init_seed=Time.get_unix_time_from_system()):
	seed(init_seed)
	save_seed=init_seed
	overworld_noise.frequency=.001
	overworld_noise.fractal_lacunarity=3
	overworld_noise.domain_warp_enabled=true
	overworld_noise.cellular_distance_function=FastNoiseLite.DISTANCE_HYBRID
	overworld_noise.seed = randi();

func _ready():

	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
