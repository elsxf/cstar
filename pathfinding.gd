extends Object

class_name PATH

enum Astar_modes{
	Normal,Agnostic,Tunnel
}

static func pathFind(start: Vector2i, goal: Vector2i, Map : Array, mode=Astar_modes.Normal) -> Array:
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
	
		for next in HEX.get_surround(current):
			next = Vector2i(next)
			if not DEF.isInChunk(next):
				#tried to go outside bounds, skip tile
				continue
			var next_tile = Map[next.x][next.y]
			var cost_of_next
			if mode == Astar_modes.Agnostic:
				cost_of_next = 1
			else:
				cost_of_next = next_tile.get_m_cost()
			if(cost_of_next==-1):
				if(mode==Astar_modes.Tunnel):
					cost_of_next = 5
				else:
					#impassable tile,continue
					continue
			var new_cost = cost_so_far[current] + cost_of_next#need tilemap data here
			if ((!cost_so_far.has(next)) or (new_cost < cost_so_far[next])):
				cost_so_far[next] = new_cost
				var priority = new_cost + HEX.cube_dist(HEX.oddr_to_axial(goal), HEX.oddr_to_axial(next)) -1
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
		#$TileMap.clear_layer(DEF.Layer_Names.Highlight)
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
