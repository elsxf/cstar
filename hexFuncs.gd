extends Object

class_name HEX

static var n_s = [0,2,6,8,10,14]#djecency codes
static var dir_vec = [
	Vector3i(+1, 0, -1), Vector3i(+1, -1, 0), Vector3i(0, -1, +1), 
	Vector3i(-1, 0, +1), Vector3i(-1, +1, 0), Vector3i(0, +1, -1), 
]#start with right, ccw
static var dir_str = {"Right":0, "URight":1, "ULeft":2, "Left":3, "DLeft":4, "DRight":5}

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
	
static func inRange(src: Vector2i, n: int):#every tile(coord) within n steps
	var center = Vector3i(oddr_to_axial(src))
	var results = []
	for q in range(-n,n+1,1):
		for r in range(max(-n,-q-n),min(n,-q+n)+1,1):
			results.append(axial_to_oddr(center + Vector3i(q,r,-q-r)))
	return results
	
static func get_surround(src:Vector2i):
	var result = []
	for i in dir_vec:
		result.append(add_2_3(src,i))
	return result	
	
static func add_2_3(v2:Vector2,v3:Vector3) -> Vector2:
	return axial_to_oddr(oddr_to_axial(v2)+v3)

static func get_c_vector(to:Vector2,from:Vector2) -> Vector3:
	return oddr_to_axial(to)-oddr_to_axial(from)
	
static func cube_lerp(a, b, t): # for hexes
	return Vector3(lerp(a.x, b.x, t),lerp(a.y, b.y, t),lerp(a.z, b.z, t))

	
static func inRing(center: Vector2i, rad: int):#ring of tiles(coord)
	var results = []
	if rad==0:
		results.append(center)
		return results
	
	var hex = axial_to_oddr(Vector3i(oddr_to_axial(center)) + dir_vec[4]*rad)
	for i in range(6):
		for j in range(rad):
			results.append(hex)
			hex = get_surround(hex)[i]
	return results

static func inLine(start: Vector2i, end:Vector2i):#tiles(coord) in line
	var a = oddr_to_axial(start)
	var b = oddr_to_axial(end)
	var results = []
	var n = cube_dist(a,b)
	for i in range(n+1):
		results.append(axial_to_oddr(axial_round(cube_lerp(a, b, 1.0/n * i))))
	return results
