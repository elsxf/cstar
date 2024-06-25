extends Object

const _def = preload("res://defines.gd")
const _hex = preload("res://hexFuncs.gd")

enum Astar_modes{
	Normal,Agnostic,Tunnel
}

static func pathFind(start: Vector2i, goal: Vector2i, tilemap : TileMap, mode=Astar_modes.Normal):
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
	
		for next in tilemap.get_surrounding_cells(current):
			var next_data = tilemap.get_cell_tile_data(0, next)
			if(next_data==null):#tried to go outside bounds, skip tile
				print("tile null at:"+str(next))
				continue
				#return null
			var cost_of_next
			if mode == Astar_modes.Agnostic:
				cost_of_next = 1
			else:
				cost_of_next = next_data.get_custom_data("M_Cost")
			if(cost_of_next==-1):
				if(mode==Astar_modes.Tunnel):
					cost_of_next = 5
				else:
					continue
			var new_cost = cost_so_far[current] + cost_of_next#need tilemap data here
			if ((!cost_so_far.has(next)) or (new_cost < cost_so_far[next])):
				cost_so_far[next] = new_cost
				var priority = new_cost + _hex.cube_dist(_hex.oddr_to_axial(goal), _hex.oddr_to_axial(next)) -1
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
	return result


# Called when the node enters the scene tree for the first time.
func _ready():

	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
