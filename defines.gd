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
}

static var mob_dict = JSON.parse_string(FileAccess.get_file_as_string("mobs.json"))
static var faction_dict = JSON.parse_string(FileAccess.get_file_as_string("factions.json"))
static var item_dict = JSON.parse_string(FileAccess.get_file_as_string("items.json"))
static var terrain_dict = JSON.parse_string(FileAccess.get_file_as_string("terrain.json"))
static var mDefs = JSON.parse_string(FileAccess.get_file_as_string("mat_defs.json"))
static var gameState = {"isdead":false,"focus":Focus.WORLD}
static var textBuffer = ""

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
