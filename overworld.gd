extends Node2D

const hitSparkRes = preload("res://hitSpark.tscn")


var tile_offset = Vector2(-32,-32)#tilesize / 2 * scale
var zoomScale = 2.0
var zoomMin = .25
var zoomMax = 4


func hitSpark(tile:Vector2i):
	var inst = hitSparkRes.instantiate()
	inst.position = hex_to_pixel(tile)
	inst.emitting = true
	$HUD.add_child(inst)
	ACT.next_hit_spark=null

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
		DEF.current_map[i.x][i.y].known = DEF.vis_tile_names.Unseen
		#force redraw of tile contents
		$Map.set_cell(DEF.Layer_Names.Mobs,i,-1)
		$Map.set_cell(DEF.Layer_Names.Items,i,-1)
		DEF.current_map[i.x][i.y].draw_contents($Map, i)
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
			var tile = DEF.current_map[j.x][j.y]
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
	DEF.process_json()
	var h = get_viewport_rect().size.y
	$VP.size = Vector2(h*(1+1.6)/2,h)
	
	DEF.playerM = $Player.m
	Item.new("Wood","Sword").add_to_container($Player.m.items,$Player.m)
	Item.new("Stone","Sword").add_to_container($Player.m.items,$Player.m)
	Item.new("Metal","Sword").add_to_container($Player.m.items,$Player.m)
	Item.new("Wood","Spear").add_to_container($Player.m.items,$Player.m)
	Item.new("Stone","Spear").add_to_container($Player.m.items,$Player.m)
	Item.new("Metal","Spear").add_to_container($Player.m.items,$Player.m)
	GEN.init_random()
	
	$Map.clear()
	DEF.load_chunk(GEN.gen_overworld(Vector2(0,0)))
	DEF.saveState[DEF.SAVE_OVERWORLD] = DEF.save_chunk()
	#load_chunk(saveState[SAVE_OVERWORLD])
	
	DEF.current_coords=null
	DEF.current_level=-1
	
	$Player.m.add_to_data(DEF.current_map,DEF.current_mobs,Vector2i(DEF.chunk_size/2,DEF.chunk_size/2),-1)
	do_LOS()
	offset_map()

	Signals.Player_take_action.connect(_on_player_take_action)
	Signals.Player_action_taken.connect(_on_Player_action_taken)
	Signals.HUD_set_map.connect(_on_HUD_set_map)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass
	
func _unhandled_input(event: InputEvent) -> void:
	if DEF.gameState[&"focus"]!=DEF.Focus.WORLD or event.is_released() or not (event.is_action_type() or event is InputEventMouseButton):
		return
	get_viewport().set_input_as_handled()
	
	var next_action = null
	var horiz_vector = null
	var vert_vector = null
	
	match DEF.getEventAction(event):
		"OpenInventory":
			$HUD/menus/GMenu.enter_menu("Inventory")
		"keybindings":
			$HUD/menus/GMenu.enter_menu("Keybinds")
		"craft":
			$HUD/menus/GMenu.enter_menu("Craft")
		"construct":
			$HUD/menus/GMenu.enter_menu("Construct")
		"character":
			$HUD/menus/GMenu.enter_menu("Character")
		"zoom":
			zoomScale *=2
			if zoomScale>zoomMax:
				zoomScale=zoomMin
		"b_zoom":
			zoomScale = zoomScale / 2
			if zoomScale<zoomMin:
				zoomScale=zoomMax
		"save&quit":
			var Fopen = FileAccess.open("saveGame.json",FileAccess.WRITE)
			Fopen.store_string(JSON.stringify(inst_to_dict(DEF.playerM)))
			Fopen.close()
			$HUD/menus/Popup.popInput("Hello, saving")
			get_tree().quit()
		"Left":
			horiz_vector =HEX.dir_vec[3]
		"Right":
			horiz_vector =HEX.dir_vec[0]
		"URight":
			horiz_vector =HEX.dir_vec[1]
		"DRight":
			horiz_vector =HEX.dir_vec[5]
		"ULeft":
			horiz_vector =HEX.dir_vec[2]
		"DLeft":
			horiz_vector =HEX.dir_vec[4]
		"MDown":
			vert_vector=1
		"MUp":
			vert_vector=-1
		"Center":
			next_action = func wait_lambda(_calc):
					return ACT.wait()
		"apply":
			var onChoice = func onChoice_lambda(choice):
				Signals.emit_signal("Player_take_action", func apply_lambda(calc):
					return ACT.apply($Player.m,choice,calc))
			$HUD/menus/Popup.popChoice("Apply what?", $Player.m.get_access_items(), true, onChoice)
			pass
		"auto":
			for i in HEX.inRange($Player.m.curr_c(), $Player.m.get_max_m_range()):
				if DEF.current_map[i.x][i.y].m_mob==$Player.m:
					continue
				if DEF.current_map[i.x][i.y].m_mob!=null:
					if DEF.hasFlag(DEF.current_map[i.x][i.y].m_mob.hostile_to, $Player.m.faction):
						next_action = func attack_p_lambda(calc):
							return ACT.attack_phys($Player.m,i,calc)
						break
			if next_action == null:
				DEF.textBuffer+="[color=brown]Nothing to attack\n[/color]"
				next_action = func wait_lambda(_calc):
					return ACT.wait()
		"pickup":
			var valid_items = []
			for i in HEX.inRange($Player.m.curr_c(),1):
				valid_items.append_array(DEF.current_map[i.x][i.y].i_items)
			match valid_items.size():
				0:
					DEF.textBuffer+="nothing to pick up\n"
				1:
					next_action = func pickup_lambda(calc):
						return ACT.pickup($Player.m,valid_items[0],calc)
				_:
					var onChoice = func onChoice_lambda(choice, num:int = -1):
						if num == -1 or num > choice.count:
							valid_items.erase(choice)
						Signals.emit_signal("Player_take_action",func action_lambda(calc):return ACT.pickup($Player.m,choice,calc,num))
					$HUD/menus/Popup.popChoice("Pickup what?", valid_items, false,onChoice)
		"drop":
			#TODO:select tile to drop on
			var onChoice = func onChoice_lambda(choice, num = -1):
				Signals.emit_signal("Player_take_action",func drop_lambda(calc):return ACT.drop($Player.m,choice,calc, num))
			$HUD/menus/Popup.popChoice("Drop what?", $Player.m.items, false, onChoice)
			#var choice =  await Signal($HUD/menus,'choiceMade')
			#next_action = func drop_lambda(calc):
						#return ACT.drop($Player.m,choice,calc)
		"wear":
			var possible_items = $Player.m.get_access_items()
			var valid_items = []
			for i in possible_items:
				if DEF.hasFlag(DEF.getProperty(DEF.sDefs,i.shape,&"flags"), DEF.sDefs[&"Flags"][&"wearable"]):
					valid_items.append(i)
			if valid_items.size() == 0:
				DEF.textBuffer += "[color=brown]Nothing to wear![/color]\n"
			else:
				var onChoice = func onChoice_lambda(choice):
					Signals.emit_signal("Player_take_action", func wear_lambda(calc):
						valid_items.erase(choice)
						return ACT.wear($Player.m,choice,calc))
				$HUD/menus/Popup.popChoice("wear what?",valid_items, true, onChoice)
		"wield":
			var onChoice = func onChoice_lambda(choice):
				Signals.emit_signal("Player_take_action", func wield_lambda(calc):
					return ACT.wield($Player.m,choice,calc))
			$HUD/menus/Popup.popChoice("wield what?", $Player.m.get_access_items(), true, onChoice)
		"Harvest":
			var validTiles = []
			for i in HEX.inRange($Player.m.curr_c(),1):
				if not DEF.isInChunk(i):
					continue
				if not DEF.current_map[i.x][i.y].f_name.is_empty():
					validTiles.append(i)
			match validTiles.size():
				0:
					DEF.textBuffer+="[color=brown]nothing to harvest![/color]\n"
				1:
					var toHarvest = DEF.current_map[validTiles[0].x][validTiles[0].y]
					next_action= func harvest_lambda(calc):
						return ACT.harvest(toHarvest, calc)
				_:
					for i in validTiles:
						$Map.set_cell(DEF.Layer_Names.Highlight,i, 22, Vector2i(0, 0))
					var choice = await $HUD/menus/Popup.popVector("Harvest Where?")
					if choice!=null:
						var target = HEX.add_2_3($Player.m.curr_c(),choice)
						next_action = func Harvest_lambda(calc):
							return ACT.harvest(DEF.current_map[target.x][target.y],calc)
		"smash":
			var choice = await $HUD/menus/Popup.popVector("Smash Where?")
			if choice!=null:
				var target =HEX.add_2_3($Player.m.curr_c(),choice)
				next_action = func onChoice_lambda(calc):
					var result = ACT.smash(DEF.current_map[target.x][target.y],calc)
					DEF.current_map[target.x][target.y].set_self($Map,target)
					return result

	$Map.clear_layer(DEF.Layer_Names.Highlight)
	if(horiz_vector!=null):
		var target_loc =Vector2i(HEX.add_2_3($Player.m.curr_c(),horiz_vector))
		var target_tile
		if(DEF.isInChunk(target_loc) or DEF.playerM.d_level==-1):
			target_tile = DEF.current_map[target_loc.x%DEF.chunk_size][target_loc.y%DEF.chunk_size]
			if(target_tile.m_mob==null):
				next_action = func move_horizontal_lambda(calc):
					return ACT.move_horizontal($Player.m,DEF.current_map,horiz_vector,0,calc)
			else:
				next_action = func attack_p_lambda(calc):
					return ACT.attack_phys($Player.m,target_loc,calc)
					
	if(vert_vector!=null):
		next_action = func move_vertical_lambda(calc):
			return ACT.move_vertical($Player.m,DEF.current_map,vert_vector,0,calc)

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
		$Map.clear_layer(DEF.Layer_Names.Highlight)
		var path = PATH.pathFind(m_tile,$Player.m.curr_c(),DEF.current_map)
		if (path!=null):
			for i in path:
				$Map.set_cell(DEF.Layer_Names.Highlight,i,1,Vector2i(0,0))
	$Map.scale = DEF.tile_scale*zoomScale
	offset_map()


func _on_player_take_action(Action_Lambda) -> void:
	$Player.m.next_action=Action_Lambda
	$Map.clear_layer(DEF.Layer_Names.Highlight)
	#timekeeping
	while($Player.m.Hp>0):
		if $Player.m.can_act():
			$HUD.last_action_cost=$Player.m.get_tu_cost()
			$HUD.last_action_name=$Player.m.get_action_str()
			$Player.m.act()
			if(ACT.next_hit_spark!=null):
				hitSpark(ACT.next_hit_spark)
			break
		else:
			DEF.world_time+=1
			for m in DEF.current_mobs:
				m.give_tu(1)
				if(m!=$Player.m):
					while(m.can_act()):
						if m.next_action==null:
							m.get_brain()
						m.act()
						if(ACT.next_hit_spark!=null):
							hitSpark(ACT.next_hit_spark)


	if($Player.m.Hp<=0):
		await %Popup.popInput("You died!")
		get_tree().root.add_child(preload("res://game_over.tscn").instantiate())
		queue_free()
	
	#$HUD/Label.text = "Dungeon Level: "+str($Player.m.d_level)+"\nTime cost: " + str(tu_delta)+"\nHp: "+str($Player.m.Hp)
	
	#check if map needs to change
	if($Player.m.d_level!=DEF.current_level or (DEF.current_coords!=null and $Player.m.world_c!=DEF.current_coords)):
		DEF.change_map()
		$Map.clear()
		
	#update seen/unseen los stuff
	#set all known to unseen

	#move map
	$Map.scale = DEF.tile_scale*zoomScale
	offset_map()
	do_LOS()
	
	Signals.emit_signal("Player_action_taken")
	
func _on_Player_action_taken():
	if DEF.playerM.current_activity!=null:
		Signals.emit_signal("Player_take_action", DEF.playerM.current_activity)

func _on_HUD_set_map(mapArray:Array):
	for i in $Map.get_used_cells(0):
		$Map.set_cell(DEF.Layer_Names.Vis,i,DEF.vis_t_dat[DEF.vis_tile_names.Unknown][DEF.T_data_cols.Scource],Vector2i(0,0),DEF.vis_t_dat[DEF.vis_tile_names.Unknown][DEF.T_data_cols.Alt])
	for i in range(DEF.chunk_size):
		for j in range(DEF.chunk_size):
			mapArray[i][j].set_self(%Map,Vector2i(i,j))
	BetterTerrain.update_terrain_area($Map, DEF.Layer_Names.Terrain, Rect2i(0,0,DEF.chunk_size,DEF.chunk_size), true)
