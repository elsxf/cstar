extends Resource
class_name Tile

@export var dataSet : Array
@export var t_name : StringName
@export var f_name : StringName
@export var m_mob : Mob
@export var i_items : Array
@export var known : int = DEF.vis_tile_names.Unknown
#@export var i_items : Array

func _init(terrain_name:StringName = &"Deep_Water", feature:StringName = &"",mob:Mob=null,items : Array = []):
	self.t_name = terrain_name
	self.f_name = feature
	self.m_mob = mob
	self.i_items = items
	#self.i_items = items
	
func set_self(Map:TileMap, coord:Vector2i):#call only once and before terrain connect
	var Acoord = Vector2i(DEF.terrain_dict[t_name][&"A_coord_x"],DEF.terrain_dict[t_name][&"A_coord_y"])
	Map.set_cell(DEF.Layer_Names.Terrain,coord,DEF.terrain_dict[t_name][&"source"],Acoord,0)
	Map.set_cell(DEF.Layer_Names.Vis,coord,DEF.vis_t_dat[self.known][DEF.T_data_cols.Scource],DEF.vis_t_dat[self.known][DEF.T_data_cols.Coord],DEF.vis_t_dat[self.known][DEF.T_data_cols.Alt])
	draw_contents(Map, coord)
	
func draw_contents(Map:TileMap, coord:Vector2i):
	if(not self.f_name.is_empty()):
		var Acoord = Vector2i(DEF.terrain_dict[f_name][&"A_coord_x"],DEF.terrain_dict[f_name][&"A_coord_y"])
		Map.set_cell(DEF.Layer_Names.Features,coord,DEF.terrain_dict[self.f_name][&"source"],Acoord)
	else:
		#erase feature layer if no feature
		Map.set_cell(DEF.Layer_Names.Features,coord,-1)
	if i_items.size()>0:#if items, display first
		var source = DEF.mDefs[self.i_items[0].shape][&"source"]
		var AtlasCoord = Vector2i(DEF.mDefs[self.i_items[0].shape][&"A_coord_x"],DEF.mDefs[self.i_items[0].shape][&"A_coord_y"])
		Map.set_cell(DEF.Layer_Names.Items,coord,source,AtlasCoord)
	else:#no items, erase item layer 
		Map.set_cell(DEF.Layer_Names.Items,coord,-1)
	if(self.m_mob!=null):
		m_mob.set_self(Map)
	
func get_m_cost():
	return DEF.terrain_dict[t_name][&"m_cost"]

func get_v_cost():
	return DEF.terrain_dict[t_name][&"v_cost"]

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass
