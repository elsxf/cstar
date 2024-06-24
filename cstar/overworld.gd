extends Node2D

const _def = preload("res://defines.gd")
const _gen = preload("res://generation.gd")

var overworld_map = FastNoiseLite.new()
var subworld_map = FastNoiseLite.new()

enum {
	SAVE_OVERWORLD,
	SAVE_DUNGEONS,
}

var saveState ={
	SAVE_OVERWORLD:[],
	SAVE_DUNGEONS:{},
}

var tile_offset = Vector2(-32,-32)
var n_s = [0,2,6,8,10,14]#djecency codes
var dir_vec = [
	Vector3i(+1, 0, -1), Vector3i(+1, -1, 0), Vector3i(0, -1, +1), 
	Vector3i(-1, 0, +1), Vector3i(-1, +1, 0), Vector3i(0, +1, -1), 
]#start with right, ccw
var dir_str = {"Right"=0, "URight"=1, "ULeft"=2, "Left"=3, "DLeft"=4, "DRight"=5}

func axial_to_oddr(hex : Vector3i):
	var col = hex.x + (hex.y - abs(hex.y)%2) / 2
	var row = hex.y
	return Vector2(col, row)

func oddr_to_axial(hex: Vector2i):
	var q = hex.x -(hex.y - abs(hex.y)%2) / 2
	var r = hex.y
	var s = -q-r
	return Vector3(q, r, s)
	
func axial_round(frac:Vector3):
	var q = snapped(frac.x,1)
	var r = snapped(frac.y,1)
	var s = snapped(frac.z,1)

	var q_diff = abs(q - frac.x)
	var r_diff = abs(r - frac.y)
	var s_diff = abs(s - frac.z)

	if q_diff > r_diff and q_diff > s_diff:
		q = -r-s
	elif r_diff > s_diff:
		r = -q-s
	else:
		s = -q-r

	return Vector3i(q, r, s)	
	
func save_chunk():
	var result=[]
	for i in range(_def.chunk_size):
		result.append([])
		for j in range(_def.chunk_size):
			result[i].append($TileMap.get_cell_source_id(0, Vector2(i,j)))
	return result
			
func load_chunk(data):
	for i in range(_def.chunk_size):
		for j in range(_def.chunk_size):
			#print(data[i][j])
			$TileMap.set_cell(0, Vector2(i,j), data[i][j],Vector2i(0, 0))

func pathFind(start: Vector2i, goal: Vector2i):
	var frontier = []
	frontier.append(start)
	var came_from = {}
	var cost_so_far = {}
	var c_priority = {}
	came_from[start] = null
	cost_so_far[start] = 0
	
	var current
	while(not frontier.is_empty()):
		current = frontier.pop_back()

		if current == goal:
			break
	
		for next in $TileMap.get_surrounding_cells(current):
			var next_data = $TileMap.get_cell_tile_data(0, next)
			if(next_data==null):
				return null
			var cost_of_next = next_data.get_custom_data("M_Cost")
			if(cost_of_next==-1):
				continue
			var new_cost = cost_so_far[current] + cost_of_next#need tilemap data here
			if ((!cost_so_far.has(next)) or (new_cost < cost_so_far[next])):
				cost_so_far[next] = new_cost
				var priority = new_cost + cube_dist(oddr_to_axial(goal), oddr_to_axial(next)) -1
				c_priority[next] = priority
				#insert new node in frontier,smallest priority to back
				if(frontier.is_empty() or priority<=c_priority[frontier.back()]):
					frontier.append(next)
				else:
					for n in range(frontier.size()):
						if(c_priority[frontier[n]]<priority):
							frontier.insert(n, next)
							break;
				came_from[next] = current
		#$TileMap.clear_layer(1)
		#for n in frontier:
			#$TileMap.set_cell(1,n,1,Vector2i(0,0))
		#$TileMap.set_cell(1,frontier.back(),6,Vector2i(0,0))
		#await get_tree().create_timer(.1).timeout
		#print("size:"+str(frontier.size()))
	var result = []
	while(came_from[current]!=null):
		result.append(current)
		current = came_from[current]
	#print(result)
	return result
		
	

func scrnCnt():
	return get_viewport_rect().size / 2

func pixel_to_hex(point):
	var size = $TileMap.tile_set.tile_size.x*$TileMap.scale.x/2
	var q = (sqrt(3)/3 * point.x-1./3 * point.y) / size
	var r = (2./3 * point.y) / size
	return axial_round(Vector3(q, r,-q-r))
	
func hex_to_pixel(tile:Vector3i, center:Vector3i):
	var hex = Vector3(tile-center)
	var size = $TileMap.tile_set.tile_size.x*$TileMap.scale.x/2
	var x = size * (sqrt(3) * hex.x  +  sqrt(3)/2 * hex.y)
	var y = size * (1.5 * hex.y)
	return Vector2(x,y) + scrnCnt()
	
func cube_dist(a : Vector3i, b: Vector3i):
	var diff = abs(a-b)
	return (diff.x+diff.y+diff.z)/2
	
func inRange(center: Vector3i, n: int):
	var results = []
	for q in range(-n,n,1):
		for r in range(max(-n,-q-n),min(n,-q+n),1):
			results.append(center + Vector3i(q,r,-q-r))
	return results

func lerp(a,b,t):#floats
	return a+(b-a)*t
	
func cube_lerp(a, b, t): # for hexes
	return Vector3(lerp(a.x, b.x, t),lerp(a.y, b.y, t),lerp(a.z, b.z, t))

func inLine(start: Vector3i, end:Vector3i):
	var results = []
	var n = cube_dist(start,end)
	for i in range(n+1):
		results.append(axial_round(cube_lerp(start, end, 1.0/n * i)))
	return results
	
# Called when the node enters the scene tree for the first time.
func _ready():
	$TileMap.clear()
	
	subworld_map.frequency=.1
	subworld_map.fractal_lacunarity=5
	subworld_map.domain_warp_enabled=true
	subworld_map.cellular_distance_function=FastNoiseLite.DISTANCE_HYBRID
	subworld_map.seed = Time.get_unix_time_from_system();
	#await map.changed
	#var data = image.get_data()
	saveState[SAVE_OVERWORLD] = _gen.gen_overworld(Vector2(0,0))
	load_chunk(saveState[SAVE_OVERWORLD])
	$Player.world_c = Vector3i(oddr_to_axial(Vector2(_def.chunk_size/2,_def.chunk_size/2)))
	$Player.dun_c = Vector3i(oddr_to_axial(Vector2(_def.chunk_size/2,_def.chunk_size/2)))

	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
@warning_ignore("unused_parameter")
func _process(delta):

	pass
	
func _input(event):
	#print(parity)
	var next_move=null
	var next_move_cost
	if(event.is_action_pressed("Left")):
		next_move=dir_vec[3]
	if(event.is_action_pressed("Right")):
		next_move=dir_vec[0]
	if(event.is_action_pressed("URight")):
		next_move=dir_vec[1]
	if(event.is_action_pressed("DRight")):
		next_move=dir_vec[5]
	if(event.is_action_pressed("ULeft")):
		next_move=dir_vec[2]
	if(event.is_action_pressed("DLeft")):
		next_move=dir_vec[4]
	if(event.is_action_pressed("DLeft")):
		next_move=dir_vec[4]
	if(event.is_action_pressed("Down")):
		next_move=1
	if(event.is_action_pressed("Up")):
		next_move=-1
	
	if next_move!=null:
		if(typeof(next_move)==TYPE_VECTOR3I):#moving within level
			var next_tile = $TileMap.get_cell_tile_data(0,axial_to_oddr($Player.curr_c()+next_move))
			if(next_tile!=null):
				next_move_cost = next_tile.get_custom_data("M_Cost")
				if next_move_cost!=-1:
					if($Player.d_level==-1):
						$Player.world_c+=next_move
						print($Player.world_c)
					else:
						$Player.dun_c+=next_move
						print($Player.dun_c)
		if(typeof(next_move)==TYPE_INT):#movving up/down
			var curr_chunk = save_chunk()
			if $Player.d_level==-1:#SAVE OVERWORLD
				saveState[SAVE_OVERWORLD]=curr_chunk
			else:#SAVE SUBWORLD
				if(not saveState[SAVE_DUNGEONS].has($Player.world_c)):#create subworld at this chunk if not already exists
					saveState[SAVE_DUNGEONS][$Player.world_c]=[]
				if saveState[SAVE_DUNGEONS][$Player.world_c].size()-1<$Player.d_level:
					#saveState[SAVE_DUNGEONS][$Player.world_c].append([])
					#saveState[SAVE_DUNGEONS][$Player.world_c][$Player.d_level].append(curr_chunk)
					saveState[SAVE_DUNGEONS][$Player.world_c].append(curr_chunk)
				else:
					saveState[SAVE_DUNGEONS][$Player.world_c][$Player.d_level] = curr_chunk
			$Player.d_level+=next_move
			if($Player.d_level==-1):
				load_chunk(saveState[SAVE_OVERWORLD])
			else:
				if(saveState[SAVE_DUNGEONS].has($Player.world_c) and saveState[SAVE_DUNGEONS][$Player.world_c].size()>$Player.d_level):
					load_chunk(saveState[SAVE_DUNGEONS][$Player.world_c][$Player.d_level])
				else:
					var player2d = axial_to_oddr($Player.world_c)
					load_chunk(_gen.gen_dungeon())
			print("d_level: "+str($Player.d_level))

	var mapOffset = -axial_to_oddr($Player.curr_c())
	mapOffset.x-=float(absi(mapOffset.y)%2) /2
	mapOffset*=Vector2($TileMap.tile_set.tile_size)*$TileMap.scale
	mapOffset.y=(mapOffset.y*3)/4
	$TileMap.position=mapOffset + scrnCnt() + tile_offset
		
	$TileMap.clear_layer(1)
	var m_tile = $TileMap.local_to_map( $TileMap.to_local(get_viewport().get_mouse_position()))
	var hex_pix = $TileMap.to_global($TileMap.map_to_local(m_tile))
	#$TileMap.set_cell(1,m_tile,1,Vector2i(0,0))
	for i in inLine(oddr_to_axial(m_tile),$Player.curr_c()):
		$TileMap.set_cell(1,axial_to_oddr(i),1,Vector2i(0,0))
	$SightLine.clear_points()
	$SightLine.add_point(hex_pix,0)
	$SightLine.add_point(scrnCnt(),1)
	if event is InputEventMouseButton:
		#print(cube_dist(oddr_to_axial(m_tile),$Player.world_c))
		var path = pathFind(m_tile,axial_to_oddr($Player.curr_c()))
		if (path!=null):
			for i in path:
				$TileMap.set_cell(1,i,1,Vector2i(0,0))
