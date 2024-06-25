extends Object

static var n_s = [0,2,6,8,10,14]#djecency codes
static var dir_vec = [
	Vector3i(+1, 0, -1), Vector3i(+1, -1, 0), Vector3i(0, -1, +1), 
	Vector3i(-1, 0, +1), Vector3i(-1, +1, 0), Vector3i(0, +1, -1), 
]#start with right, ccw
static var dir_str = {"Right"=0, "URight"=1, "ULeft"=2, "Left"=3, "DLeft"=4, "DRight"=5}

static func axial_to_oddr(hex : Vector3i):
	var col = hex.x + (hex.y - abs(hex.y)%2) / 2
	var row = hex.y
	return Vector2(col, row)

static func oddr_to_axial(hex: Vector2i):
	var q = hex.x -(hex.y - abs(hex.y)%2) / 2
	var r = hex.y
	var s = -q-r
	return Vector3(q, r, s)
	
static func axial_round(frac:Vector3):
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
	
static func oddr_dist(a : Vector2i, b: Vector2i):#same result as sube_dist but takes oddr cords
	return cube_dist(oddr_to_axial(a),oddr_to_axial(b))	
	
static func cube_dist(a : Vector3i, b: Vector3i):#taxicab distance between two tiles
	var diff = abs(a-b)
	return (diff.x+diff.y+diff.z)/2
	
static func inRange(center: Vector3i, n: int):#every tile(coord) within n steps
	var results = []
	for q in range(-n,n+1,1):
		for r in range(max(-n,-q-n),min(n,-q+n)+1,1):
			results.append(center + Vector3i(q,r,-q-r))
	return results

static func lerp(a,b,t):#floats
	return a+(b-a)*t
	
static func cube_lerp(a, b, t): # for hexes
	return Vector3(lerp(a.x, b.x, t),lerp(a.y, b.y, t),lerp(a.z, b.z, t))

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
