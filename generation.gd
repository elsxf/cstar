extends Object

class_name GEN

static var save_seed
static var land_noise = FastNoiseLite.new()
static var height_noise = FastNoiseLite.new()
static var water_level = -.3

static func value_to_terrain(value:float)->int:
	var wl_value = value+water_level
	var terrainRange = DEF.terrain_dict["Surface_order"].size()
	var t_value = clamp(int((wl_value+1) * (terrainRange)/2),0,terrainRange-2)
	return t_value

static func gen_overworld(chunk_coord: Vector2i):
	#var stair_down = DEF.feature_t_dat[DEF.feature_tile_names.sDown][DEF.T_data_cols.Scource]
	#chunk.clear()
	var chunk = []
	for i in range(DEF.chunk_size):
		chunk.append([])
		for j in range(DEF.chunk_size):
			#var coord = chunkCoords * DEF.chunk_size + Vector2(i,j)
			var coord = Vector2(i,j)
			var isLand = land_noise.get_noise_2dv(coord)>water_level
			var value
			var tName
			if isLand:
				value = height_noise.get_noise_2dv(coord) + water_level
				tName = DEF.terrain_dict["Surface_order"][value_to_terrain(value)]
			else:
				tName = DEF.terrain_dict["Surface_order"].back()
			#chunk.set_cell(DEF.Layer_Names.Terrain,Vector2(i,j),DEF.over_t_dat[value][0],Vector2(0,0))
			var feature = ""
			if(randi_range(0,100)==0):
				feature =&"DownStair"
				#chunk.set_cell(DEF.Layer_Names.Features,Vector2(i,j),stair_down,Vector2(0,0))
			var t = Tile.new(tName,feature)
			chunk[i].append(t)
			#chunk.set_cell(DEF.Layer_Names.Vis,Vector2(i,j),DEF.vis_t_dat[0][0],Vector2(0,0))
	var result = [chunk,[]]
	return result
	
static func gen_surface(over_coord: Vector2i, over_tile : Tile):
	height_noise.domain_warp_enabled=true
	#var over_tile = chunk.get_cell_source_id(DEF.Layer_Names.Features,over_coord)
	#chunk.clear()
	var chunk = []
	chunk.resize(DEF.chunk_size)
	for i in range(DEF.chunk_size):
		chunk[i] = []
		chunk[i].resize(DEF.chunk_size)
		for j in range(DEF.chunk_size):
			#var coord = chunkCoords * DEF.chunk_size + Vector2(i,j)
			var coord = Vector2(float(i-DEF.chunk_size/2)/DEF.chunk_size,float(j-DEF.chunk_size/2)/DEF.chunk_size)
			var value = height_noise.get_noise_2dv(coord+Vector2(over_coord))
			value = StringName(DEF.terrain_dict["Surface_order"][value_to_terrain(value)])
			var feature = ""
			if(value==&"Forest"):
				value=&"Plains"
				#chunk.set_cell(DEF.Layer_Names.Features,Vector2(i,j),DEF.feature_t_dat[DEF.feature_tile_names.tree][0],Vector2(0,0))
				feature = &"Tree"
			if(value==&"Hills"):
				value=&"Cave_Wall"
			#chunk.set_cell(DEF.Layer_Names.Terrain,Vector2(i,j),DEF.over_t_dat[value][0],Vector2(0,0))
			var t = Tile.new(value,feature)
			chunk[i][j]=t
	#chunk.set_cell(DEF.Layer_Names.Features,Vector2i(32,32),over_tile,Vector2(0,0))
	chunk[32][32].f_name=over_tile.f_name
	var result = [chunk,[]]
	height_noise.domain_warp_enabled=false
	return result

static func gen_dungeon(world_c:Vector2i, entry:Vector2i):
	#chunk.clear()
	var chunk = []
	chunk.resize(64)
	var mobs = []
	for i in range(DEF.chunk_size):
		chunk[i]=[]
		chunk[i].resize(DEF.chunk_size)
		for j in range(DEF.chunk_size):
			var t = Tile.new(&"Cave_Wall")
			chunk[i][j]=t
	var num_rooms = randi_range(5,17)
	var room_loc=[]
	var room_size=[]
	for i in range(num_rooms):#generate room sizes
		room_size.append(randi_range(3,5))
	for i in range(num_rooms):#generate room locations
		var maxRange = DEF.chunk_size-room_size[i]-2
		var x = randi_range(room_size[i]+2, maxRange)
		var y = randi_range(room_size[i]+2, maxRange)
		room_loc.append(Vector2i(x,y))
	room_loc[0] = Vector2i(entry.x - room_size[0]/2,entry.y-room_size[0]/2)
	#place rooms
	for v in range(num_rooms):
		for i in HEX.inRange(room_loc[v],room_size[v]):
			var toPlace = i
			if not DEF.isInChunk(toPlace):
				continue
			#chunk.set_cell(DEF.Layer_Names.Terrain,room_loc[v]+Vector2i(i,j),floor_hex,Vector2(0,0))
			chunk[toPlace.x][toPlace.y] = Tile.new(&"Cave_Floor")
	#connect rooms
	for i in range(num_rooms):
		var path = PATH.pathFind(room_loc[i],room_loc[(i+1)%num_rooms],chunk, PATH.Astar_modes.Tunnel)
		for j in path:
			for k in HEX.get_surround(j):
				#chunk.set_cell(DEF.Layer_Names.Terrain,j,floor_hex,Vector2(0,0))
				if chunk[k.x][k.y].get_m_cost()==-1:
					chunk[k.x][k.y] = Tile.new(&"Cave_Floor")
	#up stair at entry
	chunk[entry.x][entry.y].f_name = &"UpStair"
	var my_item = Item.new("Stone","Cube")
	my_item.add_to_container(chunk[entry.x][entry.y].i_items,chunk[entry.x][entry.y])
	#chunk.set_cell(DEF.Layer_Names.Features,entry,stair_up,Vector2(0,0))
	#down stair in random room
	var rand_room = randi_range(1,num_rooms-1)
	var size = room_size[rand_room] -1
	var vec = room_loc[rand_room] + Vector2i(randi_range(0,size),randi_range(0,size))
	chunk[vec.x][vec.y].f_name = &"DownStair"
	#chunk.set_cell(DEF.Layer_Names.Features,room_loc[randi_range(1,num_rooms-1)],stair_down,Vector2(0,0))
	
	var numMobs = randi_range(8,15)
	for i in range(numMobs):
		var room_idx = randi_range(0,num_rooms-1)
		var space = room_size[room_idx]-2
		var m = Mob.new("Guy")
		var mobLoc = room_loc[room_idx] + Vector2i(randi_range(-space,space),randi_range(-space,space))
		m.add_to_data(chunk,mobs,world_c,1,mobLoc)
	var result = [chunk,mobs]
	return result
	


# Called when the node enters the scene tree for the first time.

static func init_random(init_seed=Time.get_unix_time_from_system()):
	seed(init_seed)
	save_seed=init_seed
	land_noise.frequency=.01
	land_noise.fractal_lacunarity=3
	land_noise.domain_warp_enabled=false
	land_noise.cellular_distance_function=FastNoiseLite.DISTANCE_HYBRID
	land_noise.seed = randi();
	height_noise.frequency=.03
	height_noise.fractal_lacunarity=3
	height_noise.domain_warp_enabled=false
	height_noise.domain_warp_frequency=1
	height_noise.cellular_distance_function=FastNoiseLite.DISTANCE_HYBRID
	height_noise.seed = randi();
