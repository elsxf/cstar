extends Node2D

const hitSparkRes = preload("res://hitSpark.tscn")

enum {
	SAVE_OVERWORLD,
	SAVE_DUNGEONS,
}

var saveState ={
	SAVE_OVERWORLD:[],
	SAVE_DUNGEONS:{},
}


var tile_offset = Vector2(-32,-32)#tilesize / 2 * scale

var current_level
var current_coords
var current_map = []
var current_mobs = []
	
func save_chunk():
	#var chunk = []
	#var used = $Map.get_used_cells(DEF.Layer_Names.Terrain)
	#chunk.append($Map.get_pattern(DEF.Layer_Names.Terrain, used))
	#chunk.append($Map.get_pattern(DEF.Layer_Names.Features, used))
	##clear player FOV and save unknown/unseen TODO:lots of optimization posibilities here( only 0 and 1 )
	#var vis_hex = DEF.vis_t_dat[0][DEF.T_data_cols.Scource]
	#var unseen_hex = DEF.vis_t_dat[DEF.vis_tile_names.Unseen][DEF.T_data_cols.Alt]
	#for i in $Player.m.FOV:
		#$Map.set_cell(DEF.Layer_Names.Vis,i,vis_hex,Vector2(0,0),unseen_hex)
	#chunk.append($Map.get_pattern(DEF.Layer_Names.Vis, used))
	#TODO: save known/unknown
	var save = []
	save.append(current_map)
	$Player.m.free_from_data()
	save.append(current_mobs)
	return save

func hitSpark(tile:Vector2i):
	var inst = hitSparkRes.instantiate()
	inst.position = hex_to_pixel(tile)
	inst.emitting = true
	$HUD.add_child(inst)
	ACT.next_hit_spark=null

func load_chunk(data):
	current_map = data[0]
	current_mobs = data[1]
	$Player.m.add_to_data(current_map,current_mobs,$Player.m.world_c,$Player.m.d_level,$Player.m.dun_c)
	
	for i in range(DEF.chunk_size):
		for j in range(DEF.chunk_size):
			current_map[i][j].set_self($Map,Vector2i(i,j))
	#$Map.set_pattern(DEF.Layer_Names.Terrain, Vector2i(0,0), data[0])
	#$Map.set_pattern(DEF.Layer_Names.Features, Vector2i(0,0), data[1])
	#$Map.set_pattern(DEF.Layer_Names.Vis, Vector2i(0,0), data[2])
	#$Player.m.set_self($Map)

func do_LOS():
	var vis_hex = DEF.vis_t_dat[0][DEF.T_data_cols.Scource]
	#var unknown_hex =  DEF.vis_t_dat[DEF.vis_tile_names.Unknown][DEF.T_data_cols.Alt]
	var unseen_hex = DEF.vis_t_dat[DEF.vis_tile_names.Unseen][DEF.T_data_cols.Alt]
	var seen_hex = DEF.vis_t_dat[DEF.vis_tile_names.Seen][DEF.T_data_cols.Alt]
	for i in $Player.m.FOV:
		$Map.set_cell(DEF.Layer_Names.Vis,i,vis_hex,Vector2(0,0),unseen_hex)
		$Map.set_cell(DEF.Layer_Names.Mobs,i,-1)
		$Map.set_cell(DEF.Layer_Names.Items,i,-1)
	#set visible to seen
	$Player.m.FOV = LOS($Player.m.curr_c(),$Player.m.sight_range)
	for i in $Player.m.FOV:
		current_map[i.x][i.y].known = DEF.vis_tile_names.Unseen
		#force redraw of tile contents
		$Map.set_cell(DEF.Layer_Names.Mobs,i,-1)
		$Map.set_cell(DEF.Layer_Names.Items,i,-1)
		current_map[i.x][i.y].draw_contents($Map, i)
		$Map.set_cell(DEF.Layer_Names.Vis,i,vis_hex,Vector2(0,0),seen_hex)
		
func LOS(src: Vector2i, n:int):
	if(DEF.debug_sightLine):
		$SightLine.clear_points()
	var canSee = []
	if DEF.debug_esp:
		for i in HEX.inRange(src,30):
			if DEF.isInChunk(i):
				canSee.append(i)
		return canSee
	for i in HEX.get_surround(src):
		if DEF.isInChunk(i):
			canSee.append(i)
	for i in HEX.inRing(src,n):
		for j in HEX.inLine(src,i):
			if not DEF.isInChunk(j):
				break
			if not canSee.has(j):
				canSee.append(j)
			var tile = current_map[j.x][j.y]
			if tile.get_v_cost()==-1:
				break
		if(DEF.debug_sightLine):
			$SightLine.add_point(hex_to_pixel(src))
			$SightLine.add_point(hex_to_pixel(canSee.back()))
	return canSee
		

func offset_map():#centers map on player
	var mapOffset = Vector2(-$Player.m.curr_c())
	mapOffset.x-=float(absi(mapOffset.y)%2) /2
	mapOffset*=Vector2($Map.tile_set.tile_size)*$Map.scale
	mapOffset.y=(mapOffset.y*3)/4
	$Map.position=mapOffset + scrnCnt() + tile_offset

func scrnCnt():
	return $VP.size / 2

func pixel_to_hex(point):#get tilemap cell from pixel
	return $Map.local_to_map( $Map.to_local(point))
	
func hex_to_pixel(tile):#gets center pixel of tilemap cell
	return $Map.to_global($Map.map_to_local(tile))


					
	
# Called when the node enters the scene tree for the first time.
func _ready():
	
	var h = get_viewport_rect().size.y
	$VP.size = Vector2(h*(1+1.6)/2,h)
	
	DEF.playerM = $Player.m
	
	GEN.init_random()
	
	$Map.clear()
	load_chunk(GEN.gen_overworld(Vector2(0,0)))
	saveState[SAVE_OVERWORLD] = save_chunk()
	#load_chunk(saveState[SAVE_OVERWORLD])
	
	current_coords=null
	current_level=-1
	
	$Player.m.add_to_data(current_map,current_mobs,Vector2i(DEF.chunk_size/2,DEF.chunk_size/2),-1)
	do_LOS()
	offset_map()

	Signals.Player_take_action.connect(_on_player_take_action)
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
@warning_ignore("unused_parameter")
func _process(delta):

	pass
	
func _unhandled_input(event: InputEvent) -> void:
	if DEF.gameState["focus"]!=DEF.Focus.WORLD or event.is_released() or not event.is_action_type():
		return
	$Map.clear_layer(DEF.Layer_Names.Highlight)
	
	if(event.is_action("OpenInventory")):
		$HUD/menus.display("Inventory", $Player.m.items)
	
	var next_action
	var horiz_vector = null
	if(event.is_action("Left")):
		horiz_vector =HEX.dir_vec[3]
	if(event.is_action("Right")):
		horiz_vector =HEX.dir_vec[0]
	if(event.is_action("URight")):
		horiz_vector =HEX.dir_vec[1]
	if(event.is_action("DRight")):
		horiz_vector =HEX.dir_vec[5]
	if(event.is_action("ULeft")):
		horiz_vector =HEX.dir_vec[2]
	if(event.is_action("DLeft")):
		horiz_vector =HEX.dir_vec[4]
	if(horiz_vector!=null):
		var target_tile =HEX.add_2_3($Player.m.curr_c(),horiz_vector)
		if(DEF.isInChunk(target_tile)):
			if(current_map[target_tile.x][target_tile.y].m_mob==null):
				next_action = func move_horizontal_lambda(calc):
					return ACT.move_horizontal($Player.m,current_map,horiz_vector,0,calc)
			else:
				next_action = func attack_p_lambda(calc):
					return ACT.attack_phys($Player.m,target_tile,calc)
					
	var vert_vector = null
	if(event.is_action("Down")):
		vert_vector=1
	if(event.is_action("Up")):
		vert_vector=-1
	if(vert_vector!=null):
		next_action = func move_vertical_lambda(calc):
			return ACT.move_vertical($Player.m,current_map,vert_vector,0,calc)

	
	
	if(event.is_action("Center")):
		next_action = func wait_lambda(_calc):
				return ACT.wait()
	if(event.is_action("ui_focus_next")):
		for i in HEX.get_surround($Player.m.curr_c()):
			if current_map[i.x][i.y].m_mob!=null:
				if DEF.hasFlag(current_map[i.x][i.y].m_mob.hostile_to, $Player.m.faction):
					next_action = func attack_p_lambda(calc):
						return ACT.attack_phys($Player.m,i,calc)
					break
		if next_action == null:
			DEF.textBuffer+="[color=brown]Nothing to attack\n[/color]"
			next_action = func wait_lambda(_calc):
				return ACT.wait()
	if(event.is_action("pickup")):
		var valid_items = []
		for i in HEX.inRange($Player.m.curr_c(),1):
			valid_items.append_array(current_map[i.x][i.y].i_items)
		match valid_items.size():
			0:
				DEF.textBuffer+="nothing to pick up\n"
			1:
				next_action = func pickup_lambda(calc):
					return ACT.pickup($Player.m,valid_items[0],calc)
			_:
				var onChoice = func onChoice_lambda(choice, calc):
					return ACT.pickup($Player.m,choice,calc)
				$HUD/menus.choiceOf("Pickup", valid_items, onChoice)
	if(event.is_action("drop")):
		#TODO:select tile to drop on
		var onChoice = func onChoice_lambda(choice, calc):
			return ACT.drop($Player.m,choice,calc)
		$HUD/menus.choiceOf("Drop", $Player.m.items, onChoice)
		#var choice =  await Signal($HUD/menus,'choiceMade')
		#next_action = func drop_lambda(calc):
					#return ACT.drop($Player.m,choice,calc)
	if(event.is_action("Harvest",true)):
		var validTiles = []
		for i in HEX.inRange($Player.m.curr_c(),1):
			if current_map[i.x][i.y].f_feature!=-1:
				validTiles.append(i)
		match validTiles.size():
			0:
				DEF.textBuffer+="[color=brown]nothing to harvest![/color]"
			1:
				var toHarvest = current_map[validTiles[0].x][validTiles[0].y]
				next_action= func harvest_lambda(calc):
					return ACT.harvest(toHarvest, calc)
			_:
				for i in validTiles:
					$Map.set_cell(DEF.Layer_Names.Highlight,i, 22, Vector2i(0, 0))
					$HUD/menus.choiceTile()

	if(next_action!=null):
		Signals.emit_signal("Player_take_action",next_action)
	
	var m_tile = pixel_to_hex(get_viewport().get_mouse_position())
	var hex_pix = hex_to_pixel(m_tile)
	if DEF.debug_coords:
		$HUD/HEX.position=hex_pix
		$HUD/HEX.text=str(m_tile)
	#if(DEF.debug_sightLine):
		#print($SightLine.points)
		#$SightLine.clear_points()
		#$SightLine.add_point(hex_pix,0)
		#$SightLine.add_point(scrnCnt(),1)
	#for i in inRing($Player.curr_c(),cube_dist(oddr_to_axial(m_tile), $Player.curr_c())):
		#$Map.set_cell(DEF.Layer_Names.Highlight,axial_to_oddr(i),1,Vector2i(0,0))
	if event is InputEventMouseButton:
		var path = PATH.pathFind(m_tile,$Player.m.curr_c(),current_map)
		if (path!=null):
			for i in path:
				$Map.set_cell(DEF.Layer_Names.Highlight,i,1,Vector2i(0,0))


func _on_player_take_action(Action_Lambda) -> void:
	$Player.m.next_action=Action_Lambda
	#timekeeping
	while(1):
		if $Player.m.can_act():
			$HUD.last_action_cost=$Player.m.get_tu_cost()
			$HUD.last_action_name=$Player.m.get_action_str()
			$Player.m.act()
			if(ACT.next_hit_spark!=null):
				hitSpark(ACT.next_hit_spark)
			break
		else:
			for m in current_mobs:
				m.give_tu(1)
				if(m!=$Player.m):
					while(m.can_act()):
						if m.next_action==null:
							m.get_brain()
						m.act()
						if(ACT.next_hit_spark!=null):
							hitSpark(ACT.next_hit_spark)
					
	
	if($Player.m.Hp<=0):
		get_tree().root.add_child(preload("res://game_over.tscn").instantiate())
		queue_free()
	
	#$HUD/Label.text = "Dungeon Level: "+str($Player.m.d_level)+"\nTime cost: " + str(tu_delta)+"\nHp: "+str($Player.m.Hp)
	
	#check if map needs to change
	if($Player.m.d_level!=current_level or (current_coords!=null and $Player.m.world_c!=current_coords)):
		#save current stuff
		var curr_chunk = save_chunk()
		if current_level==-1:#SAVE OVERWORLD
			saveState[SAVE_OVERWORLD]=curr_chunk
		else:#SAVE SUBWORLD
			if(not saveState[SAVE_DUNGEONS].has(current_coords)):#create subworld at this chunk if not already exists
				saveState[SAVE_DUNGEONS][current_coords]=[]
			if saveState[SAVE_DUNGEONS][current_coords].size()-1<current_level:
				#saveState[SAVE_DUNGEONS][$Player.world_c].append([])
				#saveState[SAVE_DUNGEONS][$Player.world_c][$Player.d_level].append(curr_chunk)
				saveState[SAVE_DUNGEONS][current_coords].append(curr_chunk)
			else:
				#already exists, replace with updated version
				saveState[SAVE_DUNGEONS][current_coords][current_level] = curr_chunk
		
		#load stuff
		$Map.clear()
		if($Player.m.d_level==-1):
			$Map.scale = DEF.tile_scale * 2
			load_chunk(saveState[SAVE_OVERWORLD])
		else:
			$Map.scale = DEF.tile_scale
			if(saveState[SAVE_DUNGEONS].has($Player.m.world_c) and saveState[SAVE_DUNGEONS][$Player.m.world_c].size()>$Player.m.d_level):
				#area already generated, load from save
				load_chunk(saveState[SAVE_DUNGEONS][$Player.m.world_c][$Player.m.d_level])
			else:
				#need to generate area
				if($Player.m.d_level==0):
					load_chunk(GEN.gen_surface($Player.m.world_c,current_map[$Player.m.world_c.x][$Player.m.world_c.y]))
				else:
					load_chunk(GEN.gen_dungeon($Player.m.world_c,$Player.m.curr_c()))
				for i in $Map.get_used_cells(0):
					$Map.set_cell(DEF.Layer_Names.Vis,i,DEF.vis_t_dat[DEF.vis_tile_names.Unknown][DEF.T_data_cols.Scource],Vector2i(0,0),DEF.vis_t_dat[DEF.vis_tile_names.Unknown][DEF.T_data_cols.Alt])
			$Player.m.FOV.clear()#dont let previous seen be replaced with unseen, all are unknown to start
		#build terrain
		BetterTerrain.update_terrain_area($Map, DEF.Layer_Names.Terrain, Rect2i(0,0,DEF.chunk_size,DEF.chunk_size), true)
		#update map location
		current_level=$Player.m.d_level
		if(current_level==-1):
			current_coords=null
		else:
			current_coords=$Player.m.world_c
		
	#update seen/unseen los stuff
	#set all known to unseen

	#move map
	offset_map()
	do_LOS()
	
	Signals.emit_signal("Player_action_taken")
