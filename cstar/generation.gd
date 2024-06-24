extends Node

const _def = preload("res://defines.gd")

static var save_seed
static var overworld_noise = FastNoiseLite.new()

static func gen_overworld(chunk_coord: Vector2i):
	var chunk = []
	for i in range(_def.chunk_size):
		chunk.append([])
		for j in range(_def.chunk_size):
			#var coord = chunkCoords * _def.chunk_size + Vector2(i,j)
			var coord = Vector2(i,j)
			var value = overworld_noise.get_noise_2dv(coord)
			value = clamp(int((value*4+1) * (_def.over_t_dat.size())/2),0,_def.over_t_dat.size()-1)
			chunk[i].append(value)
	return chunk
	
static func gen_surface():
	pass

static func gen_dungeon():
	var chunk = []
	for i in range(_def.chunk_size):
		chunk.append([])
		for j in range(_def.chunk_size):
			chunk[i].append(_def.dun_t_dat[_def.Under_tile_names.Cave_Wall][_def.T_data_cols.Scource])
	var num_rooms = randi_range(5,15)
	var room_loc=[]
	var room_size=[]
	for i in range(num_rooms):#generate room sizes
		room_size.append(randi_range(7,15))
	for i in range(num_rooms):#generate room locations
		var range = _def.chunk_size-room_size[i]-1
		var x = randi_range(1, range)
		var y = randi_range(1, range)
		room_loc.append(Vector2i(x,y))
	for v in range(room_loc.size()):
		for i in range(room_size[v]):
			for j in range(room_size[v]):
				var value = _def.dun_t_dat[_def.Under_tile_names.Cave_Floor][_def.T_data_cols.Scource]
				chunk[room_loc[v].x+i][room_loc[v].y+j]=value
	return chunk	
	


# Called when the node enters the scene tree for the first time.
func _ready():
	save_seed = Time.get_unix_time_from_system()
	seed(Time.get_unix_time_from_system())
	overworld_noise.frequency=.001
	overworld_noise.fractal_lacunarity=3
	overworld_noise.domain_warp_enabled=true
	overworld_noise.cellular_distance_function=FastNoiseLite.DISTANCE_HYBRID
	overworld_noise.seed = Time.get_unix_time_from_system();
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
