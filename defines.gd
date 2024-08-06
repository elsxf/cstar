extends Object

class_name DEF

enum {RIGHT,LEFT}

enum Layer_Names{
	Terrain,Features,Items,Mobs,Highlight,Vis
}
enum T_data_cols{
	Scource,Coord,Alt,M_Cost,V_Cost
}

static var chunk_size = 64
static var tile_scale = Vector2i(2,2)

static var json_was_processed : bool = false

static var world_time = 0

static var playerM : Mob

static var debug_esp = false
static var debug_coords = false
static var debug_sightLine = false

enum vis_tile_names{
	Unknown,Unseen,Seen
}

static var vis_t_dat = [
	[10, Vector2(0,0),0],
	[10, Vector2(0,0),1],
	[10, Vector2(0,0),2],
]

enum Focus{
	WORLD,
	GAME_MENU,
	POPUP_MENU,
}

static var keyBinds = JSON.parse_string(FileAccess.get_file_as_string("keybind.json"))
static var actionBinds = reverseDict(keyBinds)
static var mob_dict = JSON.parse_string(FileAccess.get_file_as_string("mobs.json"))
static var skill_dict = JSON.parse_string(FileAccess.get_file_as_string("skills.json"))
static var faction_dict = JSON.parse_string(FileAccess.get_file_as_string("factions.json"))
static var item_dict = JSON.parse_string(FileAccess.get_file_as_string("items.json"))
static var terrain_dict = JSON.parse_string(FileAccess.get_file_as_string("terrain.json"))
static var construct_dict = JSON.parse_string(FileAccess.get_file_as_string("construction.json"))
static var mDefs = JSON.parse_string(FileAccess.get_file_as_string("mat_defs.json"))
static var sDefs = JSON.parse_string(FileAccess.get_file_as_string("shape_defs.json"))
		
static var gameState = {"isdead":false,&"focus":Focus.WORLD,&"prevFocus":null}
static var textBuffer = ""

static var SAVE_OVERWORLD="o"
static var SAVE_DUNGEONS="d"
static var PLAYER="p"

static var saveState ={
	SAVE_OVERWORLD:[],
	SAVE_DUNGEONS:{},
	PLAYER:{},
}


static var current_level:int = -1
static var current_coords = Vector2i(32,32)
static var current_map = []
static var current_mobs = []
	
static func save_chunk():
	##clear player FOV and save unknown/unseen TODO:lots of optimization posibilities here( only 0 and 1 )
	var save = {}
	playerM.free_from_data()
	var savingMap = current_map.duplicate(true)
	var savingMobs = current_mobs.duplicate(true)
	for i in savingMap.size():
		for j in savingMap[i].size():
			savingMap[i][j]= savingMap[i][j].serialize()
	for i in savingMobs.size():
		savingMobs[i] = savingMobs[i].serialize()
	save["Map"]=(savingMap)
	save["Mobs"]=(savingMobs)
	return save

static func load_chunk(data):
	for i in data["Map"].size():
		for j in data["Map"][i].size():
			current_map[i][j].deSerialize(data["Map"][i][j])
	current_mobs = []
	for i in data["Mobs"]:
		var m = Mob.new("default")
		m.deSerialize(i)
		m.add_to_data(current_mobs,playerM.world_c,playerM.d_level,m.dun_c)
		
	playerM.add_to_data(current_mobs,playerM.world_c,playerM.d_level,playerM.dun_c)
	Signals.HUD_set_map.emit(current_map)

static func change_map():
#save current stuff
	var curr_chunk = save_chunk()
	if current_level==-1:#SAVE OVERWORLD
		saveState[SAVE_OVERWORLD]=curr_chunk
		print("saving overworld")
	else:#SAVE SUBWORLD
		if(not saveState[SAVE_DUNGEONS].has(str(current_coords))):#create subworld at this chunk if not already exists
			saveState[SAVE_DUNGEONS][str(current_coords)]=[]
		if saveState[SAVE_DUNGEONS][str(current_coords)].size()-1<current_level:
			#saveState[SAVE_DUNGEONS][$Player.world_c].append([])
			#saveState[SAVE_DUNGEONS][$Player.world_c][$Player.d_level].append(curr_chunk)
			saveState[SAVE_DUNGEONS][str(current_coords)].append(curr_chunk)
		else:
			#already exists, replace with updated version
			saveState[SAVE_DUNGEONS][str(current_coords)][current_level] = curr_chunk
	
	#load stuff
	playerM.FOV.clear()#dont let previous seen be replaced with unseen, all are unknown to start
	if(playerM.d_level==-1):
		print("loading overworld")
		load_chunk(saveState[SAVE_OVERWORLD])
	else:
		if(saveState[SAVE_DUNGEONS].has(str(playerM.world_c)) and saveState[SAVE_DUNGEONS][str(playerM.world_c)].size()>playerM.d_level):
			#area already generated, load from save
			print("loading area at", playerM.world_c," ",playerM.d_level)
			load_chunk(saveState[SAVE_DUNGEONS][str(playerM.world_c)][playerM.d_level])
		else:
			print("generating area at ", playerM.curr_c())
			#need to generate area
			if(playerM.d_level==0):
				current_mobs = GEN.gen_surface(playerM.world_c,current_map[playerM.world_c.x][playerM.world_c.y])[1]
			else:
				current_mobs = GEN.gen_dungeon(playerM.world_c,playerM.curr_c())[1]
			load_chunk(save_chunk())
	#build terrain
	#update map location
	current_level=playerM.d_level
	if(current_level==-1):
		current_coords=null
	else:
		current_coords=playerM.world_c

static func save_to_file():
	var Fopen = FileAccess.open("saveGame.sav",FileAccess.WRITE)
	saveState[PLAYER]["mobSerial"] = playerM.serialize()
	saveState[PLAYER]["attr"] = playerM.attributes
	saveState[PLAYER]["world"] = {}
	saveState[PLAYER]["world"]["curr_c"] = playerM.dun_c
	saveState[PLAYER]["world"]["world_c"] = playerM.world_c
	saveState[PLAYER]["world"]["curr_level"] =  playerM.d_level
	saveState["seed"] = GEN.save_seed
	Fopen.store_string(JSON.stringify(DEF.saveState))
	Fopen.close()

static func load_from_file():
	saveState = JSON.parse_string(FileAccess.get_file_as_string("saveGame.sav"))
	DEF.playerM = Mob.new("Player")
	playerM.deSerialize(saveState[PLAYER]["mobSerial"])
	playerM.attributes = saveState[PLAYER]["attr"]
	playerM.d_level = saveState[PLAYER]["world"]["curr_level"]
	playerM.dun_c = HEX.strToVec(saveState[PLAYER]["world"]["curr_c"])
	playerM.world_c = HEX.strToVec(saveState[PLAYER]["world"]["world_c"])
	GEN.init_random(saveState["seed"])
	DEF.current_coords= playerM.dun_c if playerM.d_level!=-1 else null
	DEF.current_level=playerM.d_level
	DEF.current_map.resize(DEF.chunk_size)
	for i in current_map.size():
		current_map[i]=[]
		current_map[i].resize(DEF.chunk_size)
		for j in current_map[i].size():
			current_map[i][j] = Tile.new()
	if playerM.d_level==-1:
		load_chunk(saveState[SAVE_OVERWORLD])
	else:
		print(saveState[SAVE_DUNGEONS].keys())
		print(saveState[SAVE_DUNGEONS][str(playerM.world_c)].size())
		load_chunk(saveState[SAVE_DUNGEONS][str(playerM.world_c)][playerM.d_level])

static func process_json():
	if json_was_processed:
		return
	json_was_processed = true
	#|**************************************|
	#|ALERT Call this only and excatly ONCE!|
	#|**************************************|
	# resolves flags into ints, go from human readable string arrays to bitwize ints
	#TODO:see if prefab weapon/armor values is a good idea
	var excludes = [&"Surface_order",&"Under_order", &"Feature_order"]
	for dict in [mDefs,sDefs,mob_dict,terrain_dict]:
		for entry in dict:
			if entry in excludes:
				continue
			var flagsToInt = 0
			if dict[entry].has(&"flags"):
				for flag in dict[entry][&"flags"]:
					flagsToInt = flagsToInt | int(dict[&"Flags"][flag])
			dict[entry][&"flags"] = flagsToInt
			
static func reverseDict(dict:Dictionary)->Dictionary:
	#NOTE: DO NOT use if the dict can contain data arrays
	var result = {}
	for key in dict:
		var value = dict[key]
		if typeof(value)==TYPE_ARRAY:
			for v in value:
				if result.has(v):
					if typeof(result[v]) == TYPE_ARRAY:
						result[v].append(key)
					else:
						result[v]	= [result[v],key]
				else:
					result[v]=key
		else:
			if result.has(value):
				if typeof(result[value]) == TYPE_ARRAY:
					result[value].append(key)
				else:
					result[value] = [result[value],key]
			else:
				result[value]=key
	return result

static func changeFocus(focus:int):
	gameState[&"prevFocus"] = gameState[&"focus"]
	gameState[&"focus"] = focus

static func prevFocus():
	if gameState[&"prevFocus"]==null:
		gameState[&"prevFocus"] = gameState[&"focus"]
		gameState[&"focus"] = Focus.WORLD
		return false
	gameState[&"focus"] = gameState[&"prevFocus"]
	gameState[&"prevFocus"] = null
	return true
	
static func hasFlag(has:int,flags:int) -> bool:
	return (has&flags)

static func EntryHasFlag(dict:Dictionary,item:StringName,flag:StringName)->bool:
	return hasFlag(getProperty(dict,item,&"flags"),dict[&"Flags"][flag])

static func flagtoString(flag:int, dict:Dictionary) ->Array:
	var result = []
	for i in dict["Flags"]:
		if hasFlag(flag,dict["Flags"][i]):
			result.append(StringName(i))
	return result
	
static func isItemByName(item:Item, item_string:String)->bool:
	var parsed = item_string.split(" ")
	var item_mat = null
	var item_name
	if parsed.size()==0:
		item_name=parsed[0]
	else:
		item_mat = parsed[0]
		item_name=parsed[1]
	if item_name==item.name and (item_mat == null or item_mat==item.mat):
		return true
	return false
	
static func numOfItem(arr:Array, item:String):
	var count = 0
	for i in arr:
		if isItemByName(i,item):
			count +=i.count
	return count
	
static func dispKg(weight:int):
	if weight < 1000:
		return str(weight)+ "g"
	return str(float(weight)/1000)+"Kg"
	
static func dispLiter(volume:int):
	if volume < 1000:
		return str(volume)+ "mL"
	return str(float(volume)/1000)+"L"
	
static func getProperty(dict:Dictionary,item:StringName,property:StringName):
	if dict[item].has(property):
		return dict[item][property]
	if dict[item].has(&"inherits"):
		return getProperty(dict,dict[item][&"inherits"],property)
	return dict[&"default"][property]

static func rollDice(num:int, dice:int) -> int:
	if num<1 or dice<1:
		return 0
	var sum = 0
	for i in range(num):
		sum+=randi_range(1,dice)
	return sum

static func numToSkill(num:float, asFloat:bool = false):
	var result = num/100 ** (1.0/1.2)
	if asFloat:
		return snapped(result,.01)
	return int(result)

static func contest(stat1,stat2)->int:
	#returns negative if stat1 wins, positive if stat2 wins, 0 if tie
	var stat1roll = rollDice(3,6)
	var stat2roll = rollDice(3,6)
	var result
	if (stat1roll==18 and stat2roll!=18) or (stat1roll!=3 and stat2roll==3):
		#stat1 crit
		result = -18 - stat1
	elif (stat2roll==18 and stat1roll!=18) or (stat2roll!=3 and stat1roll==3):
		#stat2 crit
		result = 18 + stat2
	else:
		result = (stat2roll+stat2)-(stat1roll+stat1)
	return result

static func stdDist():
	return (float(rollDice(3,6))-3)/15

static func toBar(part, total, numchars:int = 2, color:bool = true):
	var percent:float = max(0,float(part)/total)
	var colors = ["DARK_RED","red","yellow","green","forest_green"]
	var result = "[b]"
	if color:
		result += "[color="+colors[lerp(0,colors.size()-1,percent)]+"] "
	for i in range(numchars):
		if i<percent*numchars:
			result += "|"
		elif i<percent*numchars+1:
			result+="\\"
		else:
			result+="."
	if color:
		result += "[/color]"
	result+="[/b]"
	return result

static func listStr(itemList:Array, recurse:int = 0)->String:
	var result = ""
	for i in itemList:
		if typeof(i)==TYPE_ARRAY:
			result += listStr(i,recurse+1)
		else:
			for num in recurse:
				result+="\t"
			result+=str(i)+"\n"
	return result.left(result.length()-1)
	
static func lambdaStr(itemList:Array, ListLambda)->String:
	var result = ""
	for i in itemList:
		result+=str(ListLambda.call(i))+"\n"
	return result

static func isInChunk(coord:Vector2i) -> bool:
	return not (coord.x>=chunk_size or coord.y>=chunk_size or coord.x<0 or coord.y<0)
	
static func evtMatch(event:InputEvent,character:String):
	return char(event.unicode)==character

static func getEventAction(event:InputEvent):
	if event is InputEventKey:
		var keyStr = getEventStr(event)
		if DEF.keyBinds.has(keyStr):
			return DEF.keyBinds[keyStr]

static var keyExceptions = ["Tab", "Shift+Tab"]
static func getEventStr(event:InputEvent)->String:
	var result
	if event is InputEventKey:
		if keyExceptions.has(event.as_text_keycode()):
			result = event.as_text_keycode()
		else:
			result = char(event.unicode)
		return result
	return "NoKey"
