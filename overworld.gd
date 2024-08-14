extends Node2D

const hitSparkRes = preload("res://hitSpark.tscn")


var tile_offset = Vector2(-32,-32)#tilesize / 2 * scale
var zoomScale = .5
var zoomMin = .25
var zoomMax = 4


func hitSpark(tile:Vector3i):
	var inst = hitSparkRes.instantiate()
	inst.position = hex_to_pixel(HEX.axial_to_oddr(tile))
	inst.emitting = true
	$HUD.add_child(inst)
	ACT.next_hit_spark=null

func do_LOS():
	var vis_hex = DEF.vis_t_dat[0][DEF.T_data_cols.Scource]
	#var unknown_hex =  DEF.vis_t_dat[DEF.vis_tile_names.Unknown][DEF.T_data_cols.Alt]
	var unseen_hex = DEF.vis_t_dat[DEF.vis_tile_names.Unseen][DEF.T_data_cols.Alt]
	var seen_hex = DEF.vis_t_dat[DEF.vis_tile_names.Seen][DEF.T_data_cols.Alt]
	for i in DEF.playerM.FOV:
		var tMapCoord = HEX.axial_to_oddr(i)
		$Map.set_cell(DEF.Layer_Names.Vis,tMapCoord,vis_hex,Vector2(0,0),unseen_hex)
		$Map.set_cell(DEF.Layer_Names.Mobs,tMapCoord,-1)
		$Map.set_cell(DEF.Layer_Names.Items,tMapCoord,-1)
	#set visible to seen
	DEF.playerM.LOS()
	for i in DEF.playerM.FOV:
		var tileIdx = HEX.vec3_to_index(i)
		var tMapCoord = HEX.axial_to_oddr(i)
		DEF.current_map[tileIdx].known = DEF.vis_tile_names.Unseen
		#force redraw of tile contents
		$Map.set_cell(DEF.Layer_Names.Mobs,tMapCoord,-1)
		$Map.set_cell(DEF.Layer_Names.Items,tMapCoord,-1)
		DEF.current_map[tileIdx].draw_contents($Map, i)
		$Map.set_cell(DEF.Layer_Names.Vis,tMapCoord,vis_hex,Vector2(0,0),seen_hex)
		

		

func offset_map():#centers map on player
	var mapOffset = Vector2(-HEX.axial_to_oddr(DEF.playerM.curr_c()))
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
	Signals.HUD_highlight_tiles.connect(_on_HUD_highlight_tiles)
	Signals.HUD_clear_highlight.connect(_on_HUD_clear_highlight)
	
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
			Signals.enter_menu.emit("Inventory")
		"keybindings":
			Signals.enter_menu.emit("Keybinds")
		"craft":
			Signals.enter_menu.emit("Craft")
		"construct":
			Signals.enter_menu.emit("Construct")
		"character":
			Signals.enter_menu.emit("Character")
		"MagicMenu":
			Signals.enter_menu.emit("Magic")
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
			Signals.popChoice.emit("Apply what?", DEF.playerM.get_access_items(), true, onChoice)
			pass
		"auto":
			for i in HEX.inRange(DEF.playerM.curr_c(), DEF.playerM.get_max_melee_range()):
				var tileIdx = HEX.vec3_to_index(i)
				if DEF.current_map[tileIdx].m_mob==DEF.playerM:
					continue
				if DEF.current_map[tileIdx].m_mob!=null:
					if DEF.hasFlag(DEF.current_map[tileIdx].m_mob.hostile_to, DEF.playerM.faction):
						next_action = func attack_p_lambda(calc):
							return ACT.attack_phys_melee(DEF.playerM,DEF.current_map[tileIdx].m_mob,calc)
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
				var chosen:Mob
				if choices.size()==0:
					DEF.textBuffer += "[color=BROWN]nothing to fire at!\n[/color]"
				elif DEF.getEventAction(event)=="Force_fire":
					chosen = choices[0].m_mob
					next_action = func fire_lambda(calc):
						return ACT.attack_phys_ranged(DEF.playerM,chosen,calc)
				else:
					var primeTarget = choices[0].coord
					var targetIdx = DEF.playerM.FOV.find(primeTarget)
					
					var temp = DEF.playerM.FOV[0]
					DEF.playerM.FOV[0] = primeTarget
					DEF.playerM.FOV[targetIdx] = temp
					
					Signals.popTile.emit("AIMING",DEF.playerM.FOV)
					var vec = await Signal(Signals,'popValidResponse')
					chosen = DEF.current_map[HEX.vec3_to_index(vec)].m_mob
					next_action = func fire_lambda(calc):
						return ACT.attack_phys_ranged(DEF.playerM,chosen,calc)
		"cast":
			if DEF.playerM.last_spell.is_empty():
				Signals.enter_menu.emit("Magic")
			else:
				var spellName = DEF.playerM.last_spell
				var spell = DEF.magic_dict[spellName]
				var target
				match DEF.getProperty(DEF.magic_dict,spellName,"range"):
					-1:
						#self-targeting
						target = DEF.playerM
					0:
						#TODO: melee spells
						pass
					_:
						#ranged spells
						Signals.popTile.emit("AIMING",DEF.playerM.FOV)
						var vec = await Signal(Signals,'popValidResponse')
						target = DEF.current_map[HEX.vec3_to_index(vec)]
						next_action = func cast_lambda(calc):
							return ACT.cast_spell(DEF.playerM,target,DEF.playerM.last_spell,calc)
			pass
		"pickup":
			var valid_items = []
			for i in HEX.inRange(DEF.playerM.curr_c(),1):
				valid_items.append_array(DEF.current_map[HEX.vec3_to_index(i)].i_items)
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
					Signals.popChoice.emit("Pickup what?", valid_items, false,onChoice)
		"drop":
			#TODO:select tile to drop on
			var valid_items = []
			valid_items.append_array(DEF.playerM.items)
			if DEF.playerM.wield != null:
				valid_items.append(DEF.playerM.wield)
			var onChoice = func onChoice_lambda(choice, num = -1):
				if num == -1 or num > choice.count:
					valid_items.erase(choice)
				Signals.emit_signal("Player_take_action",func drop_lambda(calc):
					return ACT.drop(DEF.playerM,choice,calc, num)
				)
			Signals.popChoice.emit("Drop what?", valid_items, false, onChoice)
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
						return ACT.wear(DEF.playerM,choice,calc)
						)
				Signals.popChoice.emit("wear what?",valid_items, true, onChoice)
		"wield":
			var onChoice = func onChoice_lambda(choice):
				Signals.emit_signal("Player_take_action", func wield_lambda(calc):
					return ACT.wield(DEF.playerM,choice,calc)
					)
			Signals.popChoice.emit("wield what?", DEF.playerM.get_access_items(), true, onChoice)
		"Harvest":
			var validTiles = []
			for i in HEX.inRange(DEF.playerM.curr_c(),1):
				if not DEF.isInChunk(i):
					continue
				if not DEF.current_map[HEX.vec3_to_index(i)].f_name.is_empty():
					validTiles.append(i)
			match validTiles.size():
				0:
					DEF.textBuffer+="[color=brown]nothing to harvest![/color]\n"
				1:
					var toHarvest = DEF.current_map[HEX.vec3_to_index(validTiles[0])]
					next_action= func harvest_lambda(calc):
						return ACT.harvest(toHarvest, calc)
				_:
					for i in validTiles:
						$Map.set_cell(DEF.Layer_Names.Highlight,HEX.axial_to_oddr(i), 22, Vector2i(0, 0))
					Signals.popVector.emit("Harvest Where?")
					var choice = await Signal(Signals,'popValidResponse')
					if choice!=null:
						var target = DEF.playerM.curr_c()+choice
						next_action = func Harvest_lambda(calc):
							return ACT.harvest(DEF.current_map[HEX.vec3_to_index(target)],calc)
		"smash":
			Signals.popVector.emit("Smash Where?")
			var choice = await Signal(Signals,'popValidResponse')
			if choice!=null:
				var target = DEF.playerM.curr_c()+choice
				next_action = func onChoice_lambda(calc):
					var tileIdx = HEX.vec3_to_index(target)
					var result = ACT.smash(DEF.current_map[tileIdx],calc)
					DEF.current_map[tileIdx].set_self($Map,target)
					return result

	$Map.clear_layer(DEF.Layer_Names.Highlight)
	if(horiz_vector!=null):
		var target_loc = DEF.playerM.curr_c()+horiz_vector
		if(DEF.isInChunk(target_loc) or DEF.playerM.d_level==-1):
			if not DEF.isInChunk(target_loc):#wraparound
				print(target_loc)
				target_loc.x = -DEF.chunk_size * sign(target_loc.x) if abs(target_loc.x)>DEF.chunk_size else target_loc.x
				target_loc.y = -DEF.chunk_size * sign(target_loc.y) if abs(target_loc.y)>DEF.chunk_size else target_loc.y
				target_loc.z = -DEF.chunk_size * sign(target_loc.z) if abs(target_loc.z)>DEF.chunk_size else target_loc.z
			var targetIdx = HEX.vec3_to_index(target_loc)
			var target_tile = DEF.current_map[targetIdx]
			if(target_tile.m_mob==null):
				next_action = func move_horizontal_lambda(calc):
					return ACT.move_horizontal(DEF.playerM,target_tile,0,calc)
			else:
				next_action = func attack_p_lambda(calc):
					return ACT.attack_phys_melee(DEF.playerM,target_tile.m_mob,calc)
					
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
		var path = PATH.pathFind(HEX.oddr_to_axial(m_tile),DEF.playerM.curr_c(),DEF.current_map)
		if (path!=null):
			for i in path:
				$Map.set_cell(DEF.Layer_Names.Highlight,HEX.axial_to_oddr(i),1,Vector2i(0,0))
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
		Signals.popVector.emit("You died!")
		await Signal(Signals,'popValidResponse')
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
	var rad = HEX.idx_to_rad(mapArray.size())-1
	var spiral = HEX.inSpiral(Vector3i(0,0,0),rad)
	for i in spiral.size():
		mapArray[i].set_self(%Map,spiral[i])
	BetterTerrain.update_terrain_cells($Map, DEF.Layer_Names.Terrain, %Map.get_used_cells(DEF.Layer_Names.Terrain), true)

func _on_HUD_highlight_tiles(vecArray, mode=DEF.Highlight_types.TILE):
	#$Map.clear_layer(DEF.Layer_Names.Highlight)
	for i in vecArray:
		match mode:
			DEF.Highlight_types.TILE:
				$Map.set_cell(DEF.Layer_Names.Highlight,HEX.axial_to_oddr(i), 22, Vector2i(0, 0))
			DEF.Highlight_types.DOT:
				$Map.set_cell(DEF.Layer_Names.Highlight,HEX.axial_to_oddr(i), 26, Vector2i(0, 0))
				
func _on_HUD_clear_highlight():
	$Map.clear_layer(DEF.Layer_Names.Highlight)
		
