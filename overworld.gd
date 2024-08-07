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
	for i in DEF.playerM.FOV:
		$Map.set_cell(DEF.Layer_Names.Vis,i,vis_hex,Vector2(0,0),unseen_hex)
		$Map.set_cell(DEF.Layer_Names.Mobs,i,-1)
		$Map.set_cell(DEF.Layer_Names.Items,i,-1)
	#set visible to seen
	DEF.playerM.LOS()
	for i in DEF.playerM.FOV:
		DEF.current_map[i.x][i.y].known = DEF.vis_tile_names.Unseen
		#force redraw of tile contents
		$Map.set_cell(DEF.Layer_Names.Mobs,i,-1)
		$Map.set_cell(DEF.Layer_Names.Items,i,-1)
		DEF.current_map[i.x][i.y].draw_contents($Map, i)
		$Map.set_cell(DEF.Layer_Names.Vis,i,vis_hex,Vector2(0,0),seen_hex)
		

		

func offset_map():#centers map on player
	var mapOffset = Vector2(-DEF.playerM.curr_c())
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
	
	Signals.Player_take_action.connect(_on_player_take_action)
	Signals.Player_action_taken.connect(_on_Player_action_taken)
	Signals.HUD_set_map.connect(_on_HUD_set_map)
	
	$Map.clear()
	
	DEF.change_map()
	#load_chunk(saveState[SAVE_OVERWORLD])
	
	
	offset_map()
	do_LOS()

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
			DEF.change_map()
			DEF.save_to_file()
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
					return ACT.apply(DEF.playerM,choice,calc))
			$HUD/menus/Popup.popChoice("Apply what?", DEF.playerM.get_access_items(), true, onChoice)
			pass
		"auto":
			for i in HEX.inRange(DEF.playerM.curr_c(), DEF.playerM.get_max_m_range()):
				if DEF.current_map[i.x][i.y].m_mob==DEF.playerM:
					continue
				if DEF.current_map[i.x][i.y].m_mob!=null:
					if DEF.hasFlag(DEF.current_map[i.x][i.y].m_mob.hostile_to, DEF.playerM.faction):
						next_action = func attack_p_lambda(calc):
							return ACT.attack_phys_melee(DEF.playerM,i,calc)
						break
			if next_action == null:
				DEF.textBuffer+="[color=brown]Nothing to attack\n[/color]"
				next_action = func wait_lambda(_calc):
					return ACT.wait()
		"fire","Force_fire":
			if DEF.getProperty(DEF.sDefs,DEF.playerM.wield.shape,"r_range")==0:
				DEF.textBuffer += "[color=BROWN]can't fire current weapon!\n[/color]"
			else:
				var choices = ACT.get_aim_mob_tiles(DEF.playerM)
				match choices.size():
					0:
						DEF.textBuffer += "[color=BROWN]nothing to fire at!\n[/color]"
					1:
						next_action = func fire_lambda(calc):
							return ACT.attack_phys_ranged(DEF.playerM,choices[0],calc)
					_:
						pass
		"pickup":
			var valid_items = []
			for i in HEX.inRange(DEF.playerM.curr_c(),1):
				valid_items.append_array(DEF.current_map[i.x][i.y].i_items)
			match valid_items.size():
				0:
					DEF.textBuffer+="nothing to pick up\n"
				1:
					next_action = func pickup_lambda(calc):
						return ACT.pickup(DEF.playerM,valid_items[0],calc)
				_:
					var onChoice = func onChoice_lambda(choice, num:int = -1):
						if num == -1 or num > choice.count:
							valid_items.erase(choice)
						Signals.emit_signal("Player_take_action",func action_lambda(calc):return ACT.pickup(DEF.playerM,choice,calc,num))
					$HUD/menus/Popup.popChoice("Pickup what?", valid_items, false,onChoice)
		"drop":
			#TODO:select tile to drop on
			var onChoice = func onChoice_lambda(choice, num = -1):
				Signals.emit_signal("Player_take_action",func drop_lambda(calc):return ACT.drop(DEF.playerM,choice,calc, num))
			$HUD/menus/Popup.popChoice("Drop what?", DEF.playerM.items, false, onChoice)
			#var choice =  await Signal($HUD/menus,'choiceMade')
			#next_action = func drop_lambda(calc):
						#return ACT.drop(DEF.playerM,choice,calc)
		"wear":
			var possible_items = DEF.playerM.get_access_items()
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
						return ACT.wear(DEF.playerM,choice,calc))
				$HUD/menus/Popup.popChoice("wear what?",valid_items, true, onChoice)
		"wield":
			var onChoice = func onChoice_lambda(choice):
				Signals.emit_signal("Player_take_action", func wield_lambda(calc):
					return ACT.wield(DEF.playerM,choice,calc))
			$HUD/menus/Popup.popChoice("wield what?", DEF.playerM.get_access_items(), true, onChoice)
		"Harvest":
			var validTiles = []
			for i in HEX.inRange(DEF.playerM.curr_c(),1):
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
						var target = HEX.add_2_3(DEF.playerM.curr_c(),choice)
						next_action = func Harvest_lambda(calc):
							return ACT.harvest(DEF.current_map[target.x][target.y],calc)
		"smash":
			var choice = await $HUD/menus/Popup.popVector("Smash Where?")
			if choice!=null:
				var target =HEX.add_2_3(DEF.playerM.curr_c(),choice)
				next_action = func onChoice_lambda(calc):
					var result = ACT.smash(DEF.current_map[target.x][target.y],calc)
					DEF.current_map[target.x][target.y].set_self($Map,target)
					return result

	$Map.clear_layer(DEF.Layer_Names.Highlight)
	if(horiz_vector!=null):
		var target_loc =Vector2i(HEX.add_2_3(DEF.playerM.curr_c(),horiz_vector))
		var target_tile
		if(DEF.isInChunk(target_loc) or DEF.playerM.d_level==-1):
			target_tile = DEF.current_map[target_loc.x%DEF.chunk_size][target_loc.y%DEF.chunk_size]
			if(target_tile.m_mob==null):
				next_action = func move_horizontal_lambda(calc):
					return ACT.move_horizontal(DEF.playerM,horiz_vector,0,calc)
			else:
				next_action = func attack_p_lambda(calc):
					return ACT.attack_phys_melee(DEF.playerM,target_loc,calc)
					
	if(vert_vector!=null):
		next_action = func move_vertical_lambda(calc):
			return ACT.move_vertical(DEF.playerM,vert_vector,0,calc)

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
	if event is InputEventMouseButton:
		$Map.clear_layer(DEF.Layer_Names.Highlight)
		var path = PATH.pathFind(m_tile,DEF.playerM.curr_c(),DEF.current_map)
		if (path!=null):
			for i in path:
				$Map.set_cell(DEF.Layer_Names.Highlight,i,1,Vector2i(0,0))
	$Map.scale = DEF.tile_scale*zoomScale
	offset_map()


func _on_player_take_action(Action_Lambda) -> void:
	DEF.playerM.next_action=Action_Lambda
	$Map.clear_layer(DEF.Layer_Names.Highlight)
	#timekeeping
	while(DEF.playerM.Hp>0):
		if DEF.playerM.can_act():
			$HUD.last_action_cost=DEF.playerM.get_tu_cost()
			$HUD.last_action_name=DEF.playerM.get_action_str()
			DEF.playerM.act()
			if(ACT.next_hit_spark!=null):
				hitSpark(ACT.next_hit_spark)
			break
		else:
			DEF.world_time+=1
			for m in DEF.current_mobs:
				m.give_tu(1)
				if(m!=DEF.playerM):
					while(m.can_act()):
						if m.next_action==null:
							m.get_brain()
						m.act()
						if(ACT.next_hit_spark!=null):
							hitSpark(ACT.next_hit_spark)


	if(DEF.playerM.Hp<=0):
		await $HUD/menus/Popup.popInput("You died!")
		get_tree().root.add_child(preload("res://game_over.tscn").instantiate())
		queue_free()
	
	#$HUD/Label.text = "Dungeon Level: "+str(DEF.playerM.d_level)+"\nTime cost: " + str(tu_delta)+"\nHp: "+str(DEF.playerM.Hp)
	
	#check if map needs to change
	if(DEF.playerM.d_level!=DEF.current_level or (DEF.current_coords!=null and DEF.playerM.world_c!=DEF.current_coords)):
		pass
		#$Map.clear()
		#DEF.change_map()
		
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

func _on_HUD_set_map(mapArray):
	$Map.clear()
	#for i in $Map.get_used_cells(0):
		#print("hello")
		#$Map.set_cell(DEF.Layer_Names.Vis,i,DEF.vis_t_dat[DEF.vis_tile_names.Unknown][DEF.T_data_cols.Scource],Vector2i(0,0),DEF.vis_t_dat[DEF.vis_tile_names.Unknown][DEF.T_data_cols.Alt])
	for i in range(DEF.chunk_size):
		for j in range(DEF.chunk_size):
			mapArray[i][j].set_self(%Map,Vector2i(i,j))
	BetterTerrain.update_terrain_area($Map, DEF.Layer_Names.Terrain, Rect2i(0,0,DEF.chunk_size,DEF.chunk_size), true)
