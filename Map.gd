extends TileMap



func _tile_data_runtime_update(layer: int, coords: Vector2i, tile_data: TileData):
	var currTile = DEF.current_map[coords.x][coords.y]
	match layer:
		DEF.Layer_Names.Mobs:
			var tileMob = currTile.m_mob
			if tileMob==null:
				return
			tile_data.modulate = Color(DEF.mob_dict[tileMob.name][&"color"])
		DEF.Layer_Names.Items:
			var tileItem = currTile.i_items[0]
			tile_data.modulate = Color(DEF.getProperty(DEF.mDefs,tileItem.mat,&"color"))
	
func _use_tile_data_runtime_update(layer: int, _coords: Vector2i):
	if layer == DEF.Layer_Names.Mobs or layer == DEF.Layer_Names.Items:
		return true
	return false

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass
