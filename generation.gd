extends Object

class_name GEN

static var save_seed
static var land_noise = FastNoiseLite.new()
static var height_noise = FastNoiseLite.new()
static var water_level = -.27

static func value_to_terrain(value:float)->int:
	var wl_value = value+water_level
	var terrainRange = DEF.terrain_dict["Surface_order"].size()
	var t_value = clamp(int((wl_value+1) * (terrainRange)/2),0,terrainRange-1)
	return t_value

static func gen_overworld(_chunk_coord: Vector3i):
	#var stair_down = DEF.feature_t_dat[DEF.feature_tile_names.sDown][DEF.T_data_cols.Scource]
	#chunk.clear()
	var spiral = HEX.inSpiral(Vector3i(0,0,0),DEF.chunk_size)
	for i in spiral.size():
		#var coord = chunkCoords * DEF.chunk_size + Vector2(i,j)
		var coord = HEX.axial_to_oddrF(spiral[i])
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
		DEF.current_map[i]=t
		#chunk.set_cell(DEF.Layer_Names.Vis,Vector2(i,j),DEF.vis_t_dat[0][0],Vector2(0,0))
	var result = [DEF.current_map,[]]
	return result
	
static func gen_surface(over_coord: Vector3i, over_tile : Tile):
	height_noise.domain_warp_enabled=true
	#chunk.clear()
	var spiral = HEX.inSpiral(Vector3i(0,0,0),DEF.chunk_size)
	for i in spiral.size():
		var coord = HEX.axial_to_oddrF(Vector3(spiral[i])/DEF.chunk_size + Vector3(over_coord))
		var value = height_noise.get_noise_2dv(coord)
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
		DEF.current_map[i]=t
	#chunk.set_cell(DEF.Layer_Names.Features,Vector2i(32,32),over_tile,Vector2(0,0))
	DEF.current_map[0].f_name=over_tile.f_name
	var result = [DEF.current_map,[]]
	height_noise.domain_warp_enabled=false
	return result

static func gen_dungeon(world_c:Vector3i, entry:Vector3i):
	#chunk.clear()
	var mobs = []
	for i in HEX.numSpiral(DEF.chunk_size):
		var t = Tile.new(&"Cave_Wall")
		DEF.current_map[i]=t
	var num_rooms = randi_range(5,17)
	var room_loc=[]
	var room_size=[]
	for i in range(num_rooms):#generate room sizes
		room_size.append(randi_range(3,5))
	for i in range(num_rooms):#generate room locations
		var maxRange = DEF.chunk_size-room_size[i]-2
		var q = randi_range(-maxRange, maxRange)
		var r = randi_range(-maxRange, maxRange)
		var s = randi_range(-maxRange, maxRange)
		room_loc.append(Vector3i(q,r,s))
	room_loc[0] = Vector3i(entry.x,entry.y,entry.z)
	#place rooms
	for v in range(num_rooms):
		for i in HEX.inRange(room_loc[v],room_size[v]):
			var toPlace = i
			if not DEF.isInChunk(toPlace):
				continue
			#chunk.set_cell(DEF.Layer_Names.Terrain,room_loc[v]+Vector2i(i,j),floor_hex,Vector2(0,0))
			DEF.current_map[HEX.vec3_to_index(toPlace)] = Tile.new(&"Cave_Floor")
	#connect rooms
	for i in range(num_rooms):
		var path = PATH.pathFind(room_loc[i],room_loc[(i+1)%num_rooms],DEF.current_map, PATH.Astar_modes.Tunnel)
		for j in path:
			for k in HEX.get_surround(j):
				var current_index = HEX.vec3_to_index(k)
				#chunk.set_cell(DEF.Layer_Names.Terrain,j,floor_hex,Vector2(0,0))
				if DEF.current_map[current_index].get_m_cost()==-1:
					DEF.current_map[current_index] = Tile.new(&"Cave_Floor")
	#up stair at entry
	var entry_idx = HEX.vec3_to_index(entry)
	DEF.current_map[entry_idx].f_name = &"UpStair"
	var my_item = Item.new("Stone","Cube")
	my_item.add_to_container(DEF.current_map[entry_idx].i_items,DEF.current_map[entry_idx])
	#chunk.set_cell(DEF.Layer_Names.Features,entry,stair_up,Vector2(0,0))
	#down stair in random room
	var rand_room = randi_range(1,num_rooms-1)
	var size = room_size[rand_room] -1
	var vec = room_loc[rand_room] + Vector3i(randi_range(0,size),randi_range(0,size),randi_range(0,size))
	DEF.current_map[HEX.vec3_to_index(vec)].f_name = &"DownStair"
	#chunk.set_cell(DEF.Layer_Names.Features,room_loc[randi_range(1,num_rooms-1)],stair_down,Vector2(0,0))
	
	var numMobs = randi_range(8,15)
	for i in range(numMobs):
		var room_idx = randi_range(0,num_rooms-1)
		var space = room_size[room_idx]-2
		var m = Mob.new("Guard")
		var mobLoc = room_loc[room_idx] + Vector2i(randi_range(-space,space),randi_range(-space,space))
		m.add_to_data(mobs,world_c,1,mobLoc)
	var result = [DEF.current_map,mobs]
	return result
	


# Called when the node enters the scene tree for the first time.

static func init_random(init_seed=Time.get_unix_time_from_system()):
	seed(init_seed)
	save_seed=init_seed
	land_noise.frequency=.03
	land_noise.fractal_lacunarity=3
	land_noise.domain_warp_enabled=false
	land_noise.cellular_distance_function=FastNoiseLite.DISTANCE_HYBRID
	land_noise.seed = randi();
	height_noise.frequency=.05
	height_noise.fractal_lacunarity=3
	height_noise.domain_warp_enabled=false
	height_noise.domain_warp_frequency=1
	height_noise.cellular_distance_function=FastNoiseLite.DISTANCE_HYBRID
	height_noise.seed = randi();
