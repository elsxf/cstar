extends Node

static func astar(start: Vector3i, goal: Vector3i):
	node *initial = (node *)malloc(sizeof(node));
  init_node(start, goal, initial, NULL, 0);
  pQ *frontier = (pQ *)malloc(sizeof(pQ));
  frontier->next = NULL;
  frontier->prev = NULL;
  frontier->n = initial;
  frontier->closed = false;
  pQ *tail = frontier;
  pQ *head = frontier;
  pQ *temp;

  while (tail->closed != true) {
	if (tail->n->c.x == goal.x && tail->n->c.y == goal.y) {
	  // found goal
	  // free pQ
	  temp = head;
	  pQ *next;

	  int dist = tail->n->g;

	  // build path
	  node *start_node = tail->n;
	  int idx = 0;
	  while (1) {
		path[idx] = start_node->c;
		idx++;
		if (start_node->parent != NULL) {
		  start_node = start_node->parent;
		} else {
		  break;
		}
	  }

	  // free everything
	  while (1) {
		if (temp->next == NULL) {
		  free_pq(temp);
		  break;
		}
		next = temp->next;
		free_pq(temp);
		temp = next;
	  }

	  return dist;
	}

	coord n_s[6];

	get_near(tail->n->c, n_s);
	pQ *to_head = tail;
	// close tail and move it to head
	if (tail->prev != NULL) {

	  tail = tail->prev;
	  tail->next = NULL;

	  to_head->next = head;
	  to_head->prev = NULL;
	  to_head->next->prev = to_head;

	  head = to_head;
	}
	head->closed = true;
	// scource node is now head

	for (int i = 0; i < 6; i++) {
	  int cost_of_next = terrainData[1][world[n_s[i].y][n_s[i].x]];
	  if(cost_of_next==-1){
		if(mode==ASTAR_TUNNEL){
		  cost_of_next = ASTAR_CAP;
		}
		else{
		  continue;
		}
	  }
	  switch (mode) {
	  case ASTAR_AGNOSTIC:
		cost_of_next = 1;
		break;
	  case ASTAR_CAPPED:
		cost_of_next = MIN(cost_of_next, ASTAR_CAP);
	  }

	  
	  int newH = simple_dist(n_s[i], goal);
	  node *next = (node *)malloc(sizeof(node));

	  init_node(n_s[i], goal, next, to_head->n, cost_of_next);
	  add_to_pQ(&head, &tail, next);
	}
	// printf("tailed: %d %d\n", tail->n->c.x, tail->n->c.y);
	//  close old tail pQ and remove it from frontier

	// printf("closing tail: %d %d\n", to_close->n->c.x, to_close->n->c.y);
	// to_close->closed=true;
  }
  return -1;
}

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
