extends Object

class_name ACT

enum Move_Modes{WALK,HOVER,TELEPORT}

static var next_hit_spark = null

static func move_horizontal(mob,Map:Array,move_vector:Vector3i,move_mode:int = Move_Modes.WALK,calc:bool = false)->int:
	var next_coord = Vector2i(HEX.add_2_3(mob.curr_c(),move_vector))

	if(DEF.isInChunk(next_coord)):
		var next_tile = Map[next_coord.x][next_coord.y]
		var next_tile_cost = next_tile.get_m_cost()
		if next_tile_cost>=0:
			if next_tile.m_mob==null:#TODO: switch with friendly
				if not calc:
					DEF.textBuffer+=(str(mob)+" moved to "+str(next_coord)+"\n")
					#actually move mob
					#remove old tile assignment
					Map[mob.curr_c().x][mob.curr_c().y].m_mob=null
					if(mob.d_level==-1):
						mob.world_c=next_coord
						#print($Player.world_c)
					else:
						mob.dun_c=next_coord
						#print($Player.dun_c)
					Map[mob.curr_c().x][mob.curr_c().y].m_mob=mob
					#if Map.get_cell_source_id(DEF.Layer_Names.Vis,mob.curr_c())==DEF.vis_t_dat[DEF.vis_tile_names.Seen][0]:
						#Map.set_cell(DEF.Layer_Names.Mobs,mob.curr_c(),mob.tile_id,mob.tile_coord,mob.tile_alt)
				#TU cost of action
			return next_tile_cost * 50
	return 0#cant move there, fix this later
	
static func move_vertical(mob:Mob,Map:Array,move_vector:int,move_mode:int = Move_Modes.WALK,calc:bool = false)->int:	
	var curr_feature = Map[mob.curr_c().x][mob.curr_c().y].f_name
	if( ((curr_feature==&"DownStair" or mob.d_level==-1) and move_vector==1) or ((curr_feature==&"UpStair" or mob.d_level==0) and move_vector==-1)):
		if not calc:
			mob.d_level+=move_vector
			#$Player.FOV = []
			if(mob.d_level==-1):
				mob.dun_c= Vector2i(DEF.chunk_size/2,DEF.chunk_size/2)
		return 50
	return 0#cant move there, fix this later
	
static func attack_phys(mob:Mob, target:Vector2i, calc:bool):
	if not calc:
		var targetMob = mob.map[target.x][target.y].m_mob
		if targetMob==null:
			return 0#no longer a target, refund
		#TODO:hit/miss calc
		var damage = DEF.rollDice(mob.attack,mob.sides)
		targetMob.change_hp(-damage)
		if(targetMob==DEF.playerM):
			DEF.textBuffer+="[color=red]"
		elif(mob==DEF.playerM):
			DEF.textBuffer+="[color=green]"
		else:
			DEF.textBuffer+="[color=yellow]"
		DEF.textBuffer+=(str(mob)+" dealt "+str(damage)+" damage to "+str(targetMob)+"[/color]\n")
		next_hit_spark = targetMob.curr_c()
	return 25

static func pickup(mob:Mob,toPickUp:Item, calc:bool):
	if not calc:
		toPickUp.free_from_container()
		toPickUp.add_to_container(mob.items,mob)
	return 50
	
static func drop(mob:Mob,toDrop:Item,calc:bool):
	if not calc:
		var tile = mob.map[mob.curr_c().x][mob.curr_c().y]
		toDrop.free_from_container()
		toDrop.add_to_container(tile.i_items,tile)
	return 10

static func harvest(tile:Tile, calc):
	if not calc:
		var harvest_data = DEF.terrain_dict[tile.f_name]["harvest"]
		for entry in harvest_data:
			#TODO: chance outputs
			var itemData = entry.split(" ")
			var i:Item = Item.new(itemData[0],itemData[1])
			i.add_to_container(tile.i_items,tile)
		tile.f_name = ""
	return 600

static func smash(tile:Tile, calc):
	if not calc:
		var feature = tile.f_name
		if not feature.is_empty() and DEF.terrain_dict[feature].has("destroy_f"):
			tile.t_name = DEF.terrain_dict[feature]["destroy_f"]
		elif DEF.terrain_dict[tile.t_name].has("destroy_t"):
			if DEF.terrain_dict[tile.t_name].has("destroy_f"):
				tile.f_name = DEF.terrain_dict[tile.t_name]["destroy_f"]
			tile.t_name = DEF.terrain_dict[tile.t_name]["destroy_t"]
		else:
			DEF.textBuffer+= "[color=brown]nothing to smash![/color]"
	return 100


static func wait() -> int:
	return 50
