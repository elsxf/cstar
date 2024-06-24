extends Object

enum Over_tile_names{
	Hills,Forest,Water,Deep_Water
}
enum T_data_cols{
	Scource,Coord,m_cost,v_cost
}

static var chunk_size = 64

static var over_t_dat = [
	#highest to lowest, no features
	#tile scource, tile coord, m_cost, v_cost(unimplemented)
	[4, Vector2(0,0),2,0],
	[3, Vector2(0,0),1,0],
	[5, Vector2(0,0),4,0],
	[2, Vector2(0,0),-1,0],
]

enum Under_tile_names{
	Cave_Wall,Cave_Floor
}
static var dun_t_dat = [
	[8, Vector2(0,0),-1,-1],
	[7, Vector2(0,0),1,0],
]
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
