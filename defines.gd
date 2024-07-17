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

static var playerM

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
static var faction_dict = JSON.parse_string(FileAccess.get_file_as_string("factions.json"))
static var item_dict = JSON.parse_string(FileAccess.get_file_as_string("items.json"))
static var terrain_dict = JSON.parse_string(FileAccess.get_file_as_string("terrain.json"))
static var mDefs = JSON.parse_string(FileAccess.get_file_as_string("mat_defs.json"))
static var gameState = {"isdead":false,"focus":Focus.WORLD,"prevFocus":null}
static var textBuffer = ""

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
	gameState["prevFocus"] = gameState["focus"]
	gameState["focus"] = focus

static func prevFocus():
	var temp = gameState["prevFocus"]
	gameState["prevFocus"] = gameState["focus"]
	gameState["focus"] = temp
	
static func hasFlag(has:int,flags:int) -> bool:
	if(has&flags):
		return true
	return false
	
static func rollDice(num:int, dice:int) -> int:
	var sum = 0
	for i in range(num):
		sum+=randi_range(1,dice)
	return sum
	
static func isInChunk(coord:Vector2i) -> bool:
	return not (coord.x>=chunk_size or coord.y>=chunk_size or coord.x<0 or coord.y<0)
	
static func evtMatch(event:InputEvent,char:String):
	return char(event.unicode)==char


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
