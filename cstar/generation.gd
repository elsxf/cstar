extends Object

const _def = preload("res://defines.gd")
const _path = preload("res://pathfinding.gd")

static var save_seed
static var overworld_noise = FastNoiseLite.new()
static var surface_noise = FastNoiseLite.new()

static func gen_overworld(chunk_coord: Vector2i, chunk:TileMap):
	var stair_down = _def.feature_t_dat[_def.feature_tile_names.sDown][_def.T_data_cols.Scource]
	chunk.clear()
	for i in range(_def.chunk_size):
		for j in range(_def.chunk_size):
			#var coord = chunkCoords * _def.chunk_size + Vector2(i,j)
			var coord = Vector2(i,j)
			var value = overworld_noise.get_noise_2dv(coord)
			value = clamp(int((value*3+1) * (_def.over_t_dat.size())/2),0,_def.over_t_dat.size()-1)
			chunk.set_cell(_def.Layer_Names.Terrain,Vector2(i,j),_def.over_t_dat[value][0],Vector2(0,0))
			if(randi_range(0,100)==0):
				chunk.set_cell(_def.Layer_Names.Features,Vector2(i,j),stair_down,Vector2(0,0))
			chunk.set_cell(_def.Layer_Names.Vis,Vector2(i,j),_def.vis_t_dat[0][0],Vector2(0,0))
	return chunk
	
static func gen_surface(over_coord: Vector2i, chunk:TileMap):
	surface_noise.seed = over_coord.x * _def.chunk_size + over_coord.y
	var base_value = overworld_noise.get_noise_2dv(over_coord) * 3 + 1
	var over_tile = chunk.get_cell_source_id(_def.Layer_Names.Features,over_coord)
	chunk.clear()
	for i in range(_def.chunk_size):
		for j in range(_def.chunk_size):
			#var coord = chunkCoords * _def.chunk_size + Vector2(i,j)
			var coord = Vector2(i,j)
			var value = surface_noise.get_noise_2dv(coord)+base_value
			value = clamp(int((value) * (_def.over_t_dat.size())/2),0,_def.over_t_dat.size()-1)
			if(value==_def.Over_tile_names.Forest):
				value=_def.Over_tile_names.Hills
				chunk.set_cell(_def.Layer_Names.Features,Vector2(i,j),_def.feature_t_dat[_def.feature_tile_names.tree][0],Vector2(0,0))
			chunk.set_cell(_def.Layer_Names.Terrain,Vector2(i,j),_def.over_t_dat[value][0],Vector2(0,0))
	chunk.set_cell(_def.Layer_Names.Features,over_coord,over_tile,Vector2(0,0))
	return chunk

static func gen_dungeon(entry:Vector2i, chunk:TileMap):
	var wall_hex=_def.dun_t_dat[_def.Under_tile_names.Cave_Wall][_def.T_data_cols.Scource]
	var floor_hex=_def.dun_t_dat[_def.Under_tile_names.Cave_Floor][_def.T_data_cols.Scource]
	#var unknown_hex = _def.vis_t_dat[_def.vis_tile_names.Unknown][_def.T_data_cols.Scource]
	var stair_down = _def.feature_t_dat[_def.feature_tile_names.sDown][_def.T_data_cols.Scource]
	var stair_up = _def.feature_t_dat[_def.feature_tile_names.sUp][_def.T_data_cols.Scource]
	chunk.clear()
	for i in range(_def.chunk_size):
		for j in range(_def.chunk_size):
			BetterTerrain.set_cell(chunk,_def.Layer_Names.Terrain,Vector2(i,j),0)
			#chunk.set_cell(_def.Layer_Names.Vis, Vector2(i,j), unknown_hex,Vector2i(0, 0))
	var num_rooms = randi_range(10,25)
	var room_loc=[]
	var room_size=[]
	for i in range(num_rooms):#generate room sizes
		room_size.append(randi_range(3,8))
	for i in range(num_rooms):#generate room locations
		var maxRange = _def.chunk_size-room_size[i]-2
		var x = randi_range(2, maxRange)
		var y = randi_range(2, maxRange)
		room_loc.append(Vector2i(x,y))
	room_loc[0] = Vector2i(entry.x - room_size[0]/2,entry.y-room_size[0]/2)
	#place rooms
	for v in range(room_loc.size()):
		for i in range(room_size[v]):
			for j in range(room_size[v]):
				chunk.set_cell(_def.Layer_Names.Terrain,room_loc[v]+Vector2i(i,j),floor_hex,Vector2(0,0))
	#connect rooms
	for i in range(num_rooms):
		var path = _path.pathFind(room_loc[i],room_loc[(i+1)%num_rooms],chunk, _path.Astar_modes.Tunnel)
		for j in path:
			chunk.set_cell(_def.Layer_Names.Terrain,j,floor_hex,Vector2(0,0))
	#up stair at entry
	chunk.set_cell(_def.Layer_Names.Features,entry,stair_up,Vector2(0,0))
	#down stair in random room
	chunk.set_cell(_def.Layer_Names.Features,room_loc[randi_range(1,num_rooms-1)],stair_down,Vector2(0,0))
	return chunk
	


# Called when the node enters the scene tree for the first time.

static func init_random(init_seed=Time.get_unix_time_from_system()):
	seed(init_seed)
	save_seed=init_seed
	overworld_noise.frequency=.02
	overworld_noise.fractal_lacunarity=3
	overworld_noise.domain_warp_enabled=false
	overworld_noise.cellular_distance_function=FastNoiseLite.DISTANCE_HYBRID
	overworld_noise.seed = randi();
	surface_noise.frequency = .05
	surface_noise.fractal_lacunarity=5
	surface_noise.domain_warp_enabled=true
	surface_noise.cellular_distance_function=FastNoiseLite.DISTANCE_HYBRID

func _ready():

	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
