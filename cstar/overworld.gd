extends Node2D

const _def = preload("res://defines.gd")
const _gen = preload("res://generation.gd")
const _hex = preload("res://hexFuncs.gd")
const _path = preload("res://pathfinding.gd")

enum {
	SAVE_OVERWORLD,
	SAVE_DUNGEONS,
}

var saveState ={
	SAVE_OVERWORLD:[],
	SAVE_DUNGEONS:{},
}

var tile_offset = Vector2(-32,-32)#tilesize / 2 * scale
	
func save_chunk():
	var chunk = []
	var used = $TileMap.get_used_cells(_def.Layer_Names.Terrain)
	chunk.append($TileMap.get_pattern(_def.Layer_Names.Terrain, used))
	chunk.append($TileMap.get_pattern(_def.Layer_Names.Features, used))
	#clear player FOV and save unknown/unseen TODO:lots of optimization posibilities here( only 0 and 1 )
	var vis_hex = _def.vis_t_dat[0][_def.T_data_cols.Scource]
	var unseen_hex = _def.vis_t_dat[_def.vis_tile_names.Unseen][_def.T_data_cols.Alt]
	for i in $Player.FOV:
		$TileMap.set_cell(_def.Layer_Names.Vis,i,vis_hex,Vector2(0,0),unseen_hex)
	chunk.append($TileMap.get_pattern(_def.Layer_Names.Vis, used))
	#TODO: save known/unknown
	
	return chunk
			
func load_chunk(data):
	$TileMap.set_pattern(_def.Layer_Names.Terrain, Vector2i(0,0), data[0])
	$TileMap.set_pattern(_def.Layer_Names.Features, Vector2i(0,0), data[1])
	$TileMap.set_pattern(_def.Layer_Names.Vis, Vector2i(0,0), data[2])

func do_LOS():
	var vis_hex = _def.vis_t_dat[0][_def.T_data_cols.Scource]
	var unknown_hex =  _def.vis_t_dat[_def.vis_tile_names.Unknown][_def.T_data_cols.Alt]
	var unseen_hex = _def.vis_t_dat[_def.vis_tile_names.Unseen][_def.T_data_cols.Alt]
	var seen_hex = _def.vis_t_dat[_def.vis_tile_names.Seen][_def.T_data_cols.Alt]
	for i in $Player.FOV:
		$TileMap.set_cell(_def.Layer_Names.Vis,i,vis_hex,Vector2(0,0),unseen_hex)
					#set visible to seen
	$Player.FOV = LOS($Player.curr_c(),$Player.sight_range)
	for i in $Player.FOV:
		$TileMap.set_cell(_def.Layer_Names.Vis,i,vis_hex,Vector2(0,0),seen_hex)
	$TileMap.set_cell(_def.Layer_Names.Vis,$Player.curr_c(),$Player.tile_id,Vector2(0,0))

func LOS(src: Vector2i, n:int):
	#$SightLine.clear_points()
	var canSee = []
	for i in $TileMap.get_surrounding_cells(src):
		canSee.append(i)
	for i in inRing(src,n):
		for j in inLine(src,i):
			if not canSee.has(j):
				canSee.append(j)
			var tile = $TileMap.get_cell_tile_data(_def.Layer_Names.Terrain,j)
			if tile==null or tile.get_custom_data("V_cost")==-1:
				break
		#$SightLine.add_point(hex_to_pixel(axial_to_oddr(src)))
		#$SightLine.add_point(hex_to_pixel(axial_to_oddr(canSee.back())))
	return canSee
		

func offset_map():#centers map on player
	var mapOffset = Vector2(-$Player.curr_c())
	mapOffset.x-=float(absi(mapOffset.y)%2) /2
	mapOffset*=Vector2($TileMap.tile_set.tile_size)*$TileMap.scale
	mapOffset.y=(mapOffset.y*3)/4
	$TileMap.position=mapOffset + scrnCnt() + tile_offset

func scrnCnt():
	return get_viewport_rect().size / 2

func pixel_to_hex(point):#get tilemap cell from pixel
	return $TileMap.local_to_map( $TileMap.to_local(point))
	
func hex_to_pixel(tile):#gets center pixel of tilemap cell
	return $TileMap.to_global($TileMap.map_to_local(tile))
	
func inRing(center: Vector2i, rad: int):#ring of tiles(coord)
	var results = []
	if rad==0:
		results.append(center)
		return results
	
	var hex = _hex.axial_to_oddr(Vector3i(_hex.oddr_to_axial(center)) + _hex.dir_vec[2]*rad)
	for i in range(6):
		for j in range(rad):
			results.append(hex)
			hex = $TileMap.get_surrounding_cells(hex)[i]
	return results

func inLine(start: Vector2i, end:Vector2i):#tiles(coord) in line
	var a = _hex.oddr_to_axial(start)
	var b = _hex.oddr_to_axial(end)
	var results = []
	var n = _hex.cube_dist(a,b)
	for i in range(n+1):
		results.append(_hex.axial_to_oddr(_hex.axial_round(_hex.cube_lerp(a, b, 1.0/n * i))))
	return results
# Called when the node enters the scene tree for the first time.
func _ready():
	
	_gen.init_random()
	
	$TileMap.clear()
	$Player.world_c = Vector2i(_def.chunk_size/2,_def.chunk_size/2)
	$Player.dun_c = Vector2i(_def.chunk_size/2,_def.chunk_size/2)
	_gen.gen_overworld(Vector2(0,0),$TileMap)
	saveState[SAVE_OVERWORLD] = save_chunk()
	load_chunk(saveState[SAVE_OVERWORLD])
	do_LOS()
	offset_map()

	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
@warning_ignore("unused_parameter")
func _process(delta):

	pass
	
func _input(event):
	$TileMap.clear_layer(_def.Layer_Names.Highlight)
	var next_move=null
	var next_move_cost
	if(event.is_action_pressed("Left")):
		next_move=_hex.dir_vec[3]
	if(event.is_action_pressed("Right")):
		next_move=_hex.dir_vec[0]
	if(event.is_action_pressed("URight")):
		next_move=_hex.dir_vec[1]
	if(event.is_action_pressed("DRight")):
		next_move=_hex.dir_vec[5]
	if(event.is_action_pressed("ULeft")):
		next_move=_hex.dir_vec[2]
	if(event.is_action_pressed("DLeft")):
		next_move=_hex.dir_vec[4]
	if(event.is_action_pressed("DLeft")):
		next_move=_hex.dir_vec[4]
	if(event.is_action_pressed("Down")):
		next_move=1
	if(event.is_action_pressed("Up")):
		next_move=-1
	
	if next_move!=null:
		if(typeof(next_move)==TYPE_VECTOR3I):#moving within level
			var next_tile = $TileMap.get_cell_tile_data(0,_hex.axial_to_oddr(Vector3i(_hex.oddr_to_axial($Player.curr_c()))+next_move))
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
						
		if(typeof(next_move)==TYPE_INT):#movving up/down
			var curr_feature = $TileMap.get_cell_source_id(_def.Layer_Names.Features,$Player.curr_c())
			var stair_down = _def.feature_t_dat[_def.feature_tile_names.sDown][_def.T_data_cols.Scource]
			var stair_up = _def.feature_t_dat[_def.feature_tile_names.sUp][_def.T_data_cols.Scource]
			if( ((curr_feature==stair_down or $Player.d_level==-1) and next_move==1) or ((curr_feature==stair_up or $Player.d_level==0) and next_move==-1)):
				var curr_chunk = save_chunk()
				if $Player.d_level==-1:#SAVE OVERWORLD
					saveState[SAVE_OVERWORLD]=curr_chunk
				else:#SAVE SUBWORLD
					if(not saveState[SAVE_DUNGEONS].has($Player.world_c)):#create subworld at this chunk if not already exists
						saveState[SAVE_DUNGEONS][$Player.world_c]=[]
					if saveState[SAVE_DUNGEONS][$Player.world_c].size()-1<$Player.d_level:
						#saveState[SAVE_DUNGEONS][$Player.world_c].append([])
						#saveState[SAVE_DUNGEONS][$Player.world_c][$Player.d_level].append(curr_chunk)
						saveState[SAVE_DUNGEONS][$Player.world_c].append(curr_chunk)
					else:
						saveState[SAVE_DUNGEONS][$Player.world_c][$Player.d_level] = curr_chunk
				$Player.d_level+=next_move
				#$Player.FOV = []
				if($Player.d_level==-1):
					$TileMap.scale = _def.tile_scale * 2
					load_chunk(saveState[SAVE_OVERWORLD])
					$Player.dun_c= Vector2i(_def.chunk_size/2,_def.chunk_size/2)
				else:
					$TileMap.scale = _def.tile_scale
					if(saveState[SAVE_DUNGEONS].has($Player.world_c) and saveState[SAVE_DUNGEONS][$Player.world_c].size()>$Player.d_level):
						#area already generated, load from save
						load_chunk(saveState[SAVE_DUNGEONS][$Player.world_c][$Player.d_level])
					else:
						#need to generate area
						if($Player.d_level==0):
							_gen.gen_surface($Player.world_c,$TileMap)
						else:
							_gen.gen_dungeon($Player.curr_c(), $TileMap)
						do_LOS()
						for i in $TileMap.get_used_cells(0):
							$TileMap.set_cell(_def.Layer_Names.Vis,i,_def.vis_t_dat[_def.vis_tile_names.Unknown][_def.T_data_cols.Scource],Vector2i(0,0),_def.vis_t_dat[_def.vis_tile_names.Unknown][_def.T_data_cols.Alt])
				BetterTerrain.update_terrain_area($TileMap, _def.Layer_Names.Terrain, Rect2i(0,0,_def.chunk_size,_def.chunk_size), true)
				print("d_level: "+str($Player.d_level))
		#update seen/unseen los stuff
		#set all known to unseen
		do_LOS()


	#move map
	offset_map()
	var m_tile = pixel_to_hex(get_viewport().get_mouse_position())
	var hex_pix = pixel_to_hex(m_tile)
	#$TileMap.set_cell(1,m_tile,1,Vector2i(0,0))
	#for i in inLine(m_tile,_hex.axial_to_oddr($Player.curr_c())):
		#$TileMap.set_cell(1,i,1,Vector2i(0,0))
		#if $TileMap.get_cell_tile_data(_def.Layer_Names.Terrain,i).get_custom_data("V_cost")==-1:
			#$TileMap.set_cell(1,i,6,Vector2i(0,0))
	#$SightLine.clear_points()
	#$SightLine.add_point(hex_pix,0)
	#$SightLine.add_point(scrnCnt(),1)
	#for i in inRing($Player.curr_c(),cube_dist(oddr_to_axial(m_tile), $Player.curr_c())):
		#$TileMap.set_cell(_def.Layer_Names.Highlight,axial_to_oddr(i),1,Vector2i(0,0))
	if event is InputEventMouseButton:
		#print(cube_dist(oddr_to_axial(m_tile),$Player.world_c))
		var path = _path.pathFind(m_tile,$Player.curr_c(),$TileMap)
		if (path!=null):
			for i in path:
				$TileMap.set_cell(_def.Layer_Names.Highlight,i,1,Vector2i(0,0))
