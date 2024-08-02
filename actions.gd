extends Object

class_name ACT

enum Move_Modes{WALK,HOVER,TELEPORT}

static var next_hit_spark = null

static func move_horizontal(mob:Mob,move_vector:Vector3i,_move_mode:int = Move_Modes.WALK,calc:bool = false)->int:
	var next_coord = Vector2i(HEX.add_2_3(mob.curr_c(),move_vector))

	if(DEF.isInChunk(next_coord) or mob.d_level==-1):
		next_coord.x = (next_coord.x+DEF.chunk_size)%DEF.chunk_size
		next_coord.y = (next_coord.y+DEF.chunk_size)%DEF.chunk_size
		var next_tile = mob.get_map()[next_coord.x][next_coord.y]
		var next_tile_cost = next_tile.get_m_cost()
		if next_tile_cost>=0:
			if next_tile.m_mob==null:#TODO: switch with friendly
				if not calc:
					DEF.textBuffer+=(str(mob)+" moved to "+str(next_coord)+"\n")
					#actually move mob
					#remove old tile assignment
					mob.get_map()[mob.curr_c().x][mob.curr_c().y].m_mob=null
					if(mob.d_level==-1):
						mob.world_c=next_coord
						#print($Player.world_c)
					else:
						mob.dun_c=next_coord
						#print($Player.dun_c)
					mob.get_map()[mob.curr_c().x][mob.curr_c().y].m_mob=mob
					match mob.get_map()[mob.curr_c().x][mob.curr_c().y].i_items.size():
						0:
							pass
						1:
							DEF.textBuffer+="You see here"+str( mob.get_map()[mob.curr_c().x][mob.curr_c().y].i_items[0])
						_:
							DEF.textBuffer+="You see here"+str( mob.get_map()[mob.curr_c().x][mob.curr_c().y].i_items[0]) + " and many more items"
				#TU cost of action
			return next_tile_cost * 50
	return 0#cant move there, fix this later
	
static func move_vertical(mob:Mob,move_vector:int,_move_mode:int = Move_Modes.WALK,calc:bool = false)->int:	
	var curr_feature = mob.get_map()[mob.curr_c().x][mob.curr_c().y].f_name
	if( ((curr_feature==&"DownStair" or mob.d_level==-1) and move_vector==1) or ((curr_feature==&"UpStair" or mob.d_level==0) and move_vector==-1)):
		if not calc:
			mob.get_map()[mob.curr_c().x][mob.curr_c().y].m_mob=null
			mob.d_level+=move_vector
			DEF.change_map()
			#$Player.FOV = []
			if(mob.d_level==-1):
				mob.dun_c= Vector2i(DEF.chunk_size/2,DEF.chunk_size/2)
		return 50
	return 0#cant move there, fix this later
	
static func attack_phys(mob:Mob, target:Vector2i, calc:bool):
	if not calc:
		var targetMob = mob.get_map()[target.x][target.y].m_mob
		if targetMob==null:
			return 0#no longer a target, refund
		#TODO:calculate attack cost
		var attack_cost:int = 25
		
		var toHit:int = mob.getAttr("melee") + (0 if mob.wield==null else mob.wield.to_hit)
		var DV:int = targetMob.getAttr("dodge")+ targetMob.getAttr("agility")
		DEF.textBuffer+= str(toHit)+" vs "+str(DV)+"\n"
		
		mob.trainAttr("melee",DV-toHit)
		targetMob.trainAttr("dodge",toHit-DV)
		if DEF.contest(toHit,DV)>0:
			#attack missed, do miss handling
			if(targetMob==DEF.playerM):
				DEF.textBuffer+="[color=brown]"
			elif(mob==DEF.playerM):
				DEF.textBuffer+="[color=yellow]"
			else:
				DEF.textBuffer+="[color=BEIGE]"
			DEF.textBuffer+=(str(mob)+" Misses the "+str(targetMob)+"[/color]\n")
			return attack_cost / 2
			
			
		#damage calculation on hit
		var blunt:int = 0
		var cut:int = 0
		var pierce:int = 0
		var skill:int = DEF.numToSkill(mob.attributes["melee"])
		var attr:int = mob.attributes["strength"]
		if(mob.wield==null):
			blunt = attr * skill
			pierce = attr * (skill/5)
			cut = attr * (skill/10)
		else:
			blunt = mob.wield.blunt
			cut = mob.wield.cut
			pierce = mob.wield.pierce
		var layerTough = 0
		var layerHard = 0
		var layerStrength = 0
		for c in targetMob.worn:
			layerTough += DEF.getProperty(DEF.mDefs,c.mat,&"toughness")
			layerHard += DEF.getProperty(DEF.mDefs,c.mat,&"hardness")
			layerStrength += DEF.getProperty(DEF.mDefs,c.mat,&"strength")
		
		var bluntDamage = DEF.stdDist() * blunt
		var pierceDamage = DEF.stdDist() * pierce
		var cutDamage = DEF.stdDist() * cut
		
		if blunt:
			#blunt bypasses hardness stop
			if DEF.contest(bluntDamage,layerStrength)>0:
				bluntDamage*=.5
		if pierce:
			#hardness stop blocks 100%
			if DEF.contest(pierceDamage,layerHard)>0:
				pierceDamage = 0
			if DEF.contest(pierceDamage,layerStrength)>0:
				pierceDamage *= .7
		if cut:
			#hardnes stop block 50%
			if DEF.contest(cutDamage,layerHard)>0:
				cutDamage *= .5
			if DEF.contest(cutDamage,layerStrength)>0:
				cutDamage *= .5
			#TODO: cut causes bleed and clothing damage to less hard
		var damageTotal = bluntDamage + pierceDamage + cutDamage
		targetMob.change_hp(-damageTotal)
		if(targetMob==DEF.playerM):
			DEF.textBuffer+="[color=dark_red]"
		elif(mob==DEF.playerM):
			DEF.textBuffer+="[color=Forest_green]"
		else:
			DEF.textBuffer+="[color=BEIGE]"
		DEF.textBuffer+=(str(mob)+" dealt "+str(bluntDamage)+"/"+str(cutDamage)+"/"+str(pierceDamage)+"damage to "+str(targetMob)+"[/color]\n")
		next_hit_spark = targetMob.curr_c()
	return 5

static func pickup(mob:Mob,toPickUp:Item, calc:bool, num = -1):
	if not calc:
		toPickUp.transfer_to_container(mob,mob.items,num)
	return 50
	
static func drop(mob:Mob,toDrop:Item,calc:bool, num = -1):
	if not calc:
		var tile:Tile = mob.get_map()[mob.curr_c().x][mob.curr_c().y]
		toDrop.transfer_to_container(tile,tile.i_items,num)
	return 10

static func wear(mob:Mob,toWear:Item,calc:bool):
	if not DEF.hasFlag(DEF.getProperty(DEF.sDefs,toWear.shape,&"flags"),DEF.sDefs[&"Flags"][&"wearable"]):
		return 0
	if not calc:
		if mob.worn.has(toWear):
			toWear.free_from_container()
			toWear.add_to_container(mob.items,mob)
		else:
			toWear.free_from_container()
			toWear.add_to_container(mob.worn,mob)
	return 50

static func wield(mob:Mob,toWield:Item,calc:bool):
	if not calc:
		if mob.wield == toWield:#item is already wielded, unwield
			toWield.free_from_container()
			mob.wield = null
			toWield.add_to_container(mob.items,mob)
		else:#wield as normal
			if mob.wield!=null:#if already wielding something, unwield it first
				Signals.emit_signal("Player_take_action",func wield_lambda(calc1):
					return wield(mob,mob.wield,calc1))
			toWield.free_from_container()
			toWield.container = mob
			mob.wield=toWield
	return 25

static func apply(mob:Mob,toApply:Item,calc:bool):
	if toApply is Recipie:
		return craft(mob,toApply,calc)
	else:
		if not calc:
			DEF.textBuffer+="[color=brown]can't do anything with that![/color]\n"
	return 0

static func harvest(tile:Tile, calc:bool):
	if tile.f_name.is_empty() or not DEF.terrain_dict[tile.f_name].has("harvest"):
		return 0
	if not calc:
		var harvest_data = DEF.terrain_dict[tile.f_name]["harvest"]
		for entry in harvest_data:
			#TODO: chance outputs
			var itemData = entry.split(" ")
			var i:Item = Item.new(itemData[0],itemData[1])
			i.add_to_container(tile.i_items,tile)
		tile.f_name = ""
	return 600

static func smash(tile:Tile, calc:bool):
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

static func craft(mob:Mob,recipie:Recipie,calc:bool):
	if not calc:
		if not recipie.work_on(500):
			mob.current_activity = func craft_lambda(calc1):
				mob.current_activity = null
				var result = craft(mob,recipie,calc1)
				return result
	return 500

static func construct(mob:Mob,tile:Tile,calc:bool):
	if not calc:
		tile.feature_data["work_left"]-=500
		print(tile.feature_data["work_left"])
		if tile.feature_data["work_left"]>0:
			mob.current_activity = func construct_lambda(calc1):
				mob.current_activity = null
				var result = construct(mob,tile,calc1)
				return result
		else:
			tile.f_name = tile.feature_data["feature_into"]
			tile.feature_data = null
	return 500
	
static func wait() -> int:
	return 50
