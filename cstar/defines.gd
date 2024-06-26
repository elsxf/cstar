extends Object

enum Layer_Names{
	Terrain,Features,Mobs,Highlight,Vis
}

enum Over_tile_names{
	Hills,Forest,Water,Deep_Water
}
enum T_data_cols{
	Scource,Coord,Alt
}

static var chunk_size = 64
static var tile_scale = Vector2i(4,4)

static var over_t_dat = [
	#highest to lowest, no features
	#tile scource, tile coord, m_cost, v_cost(unimplemented)
	[4, Vector2(0,0),0],
	[16, Vector2(0,0),0],
	[3, Vector2(0,0),0],
	[18, Vector2(0,0),0],
	[5, Vector2(0,0),0],
	[2, Vector2(0,0),0],
]

enum Under_tile_names{
	Cave_Wall,Cave_Floor
}
static var dun_t_dat = [
	[8, Vector2(0,0),0],
	[7, Vector2(0,0),0],
]

enum vis_tile_names{
	Unknown,Unseen,Seen
}

static var vis_t_dat = [
	[10, Vector2(0,0),0],
	[10, Vector2(0,0),1],
	[10, Vector2(0,0),2],
]

enum feature_tile_names{
	sUp,sDown,tree,
}
static var feature_t_dat = [
	[14, Vector2(0,0),0],
	[13, Vector2(0,0),0],
	[9, Vector2(0,0),0],
]

static func hasFlag(has:int,flags:int):
	if(has&flags):
		return true
	return false
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
