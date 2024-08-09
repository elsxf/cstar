extends Object

class_name HEX

static var n_s = [0,2,6,8,10,14]#djecency codes
static var dir_vec = [
	Vector3i(+1, 0, -1), Vector3i(+1, -1, 0), Vector3i(0, -1, +1), 
	Vector3i(-1, 0, +1), Vector3i(-1, +1, 0), Vector3i(0, +1, -1), 
	Vector3i(0,0,0)
]#start with right, ccw, 6 is center, ignore in most cases
static var dir_str = {"Right":0, "URight":1, "ULeft":2, "Left":3, "DLeft":4, "DRight":5, "Center":6}

static func axial_to_oddr(hex : Vector3i)->Vector2i:
	var col = hex.x + (hex.y - abs(hex.y)%2) / 2
	var row = hex.y
	return Vector2i(col, row)

static func oddr_to_axial(hex: Vector2i)->Vector3i:
	var q = hex.x -(hex.y - abs(hex.y)%2) / 2
	var r = hex.y
	var s = -q-r
	return Vector3i(q, r, s)

static func axial_to_oddrF(hex : Vector3)->Vector2:
	var col = hex.x + (hex.y - fmod(abs(hex.y),2)) / 2
	var row = hex.y
	return Vector2(col, row)

static func oddr_to_axialF(hex: Vector2)->Vector3:
	var q = hex.x -(hex.y - fmod(abs(hex.y),2)) / 2
	var r = hex.y
	var s = -q-r
	return Vector3(q, r, s)

static func strToVec(vecStr):
	if not vecStr is String and not vecStr is StringName:
		return vecStr
	var split = vecStr.replace("(","").split(",")
	match split.size():
		2:
			return Vector2i(int(split[0]),int(split[1]))
		3:
			return Vector3i(int(split[0]),int(split[1]),int(split[2]))
		4:
			return Vector4i(int(split[0]),int(split[1]),int(split[2]),int(split[3]))
		_:
			return vecStr

static func axial_round(frac:Vector3)->Vector3i:
	var q = snapped(frac.x,1)
	var r = snapped(frac.y,1)
	var s = snapped(frac.z,1)

	var q_diff = abs(q - frac.x)
	var r_diff = abs(r - frac.y)
	var s_diff = abs(s - frac.z)
	#all cube coords must be on the x+y+z=0 plane
	if q_diff > r_diff and q_diff > s_diff:
		q = -r-s
	elif r_diff > s_diff:
		r = -q-s
	else:
		s = -q-r

	return Vector3i(q, r, s)	

static func oddr_dist(a : Vector2i, b: Vector2i)->int:#same result as sube_dist but takes oddr cords
	return cube_dist(oddr_to_axial(a),oddr_to_axial(b))	

static func cube_dist(a : Vector3i, b: Vector3i)->int:#taxicab distance between two tiles
	var diff = abs(a-b)
	return (diff.x+diff.y+diff.z)/2

static func inRange(src: Vector3i, n: int)->Array:#every tile(coord) within n steps, same contents as inSpiral but unordered
	var center = src
	var results = []
	for q in range(-n,n+1,1):
		for r in range(max(-n,-q-n),min(n,-q+n)+1,1):
			results.append(axial_to_oddr(center + Vector3i(q,r,-q-r)))
	return results

static func get_surround(src:Vector3i)->Array:
	var result = []
	for i in dir_vec:
		result.append(src+i)
	return result

static func add_2_3(v2:Vector2i,v3:Vector3i) -> Vector2:
	return axial_to_oddr(oddr_to_axial(v2)+v3)

static func get_c_vector(to:Vector2i,from:Vector2i) -> Vector3i:
	return oddr_to_axial(to)-oddr_to_axial(from)

static func cube_lerp(a:Vector3, b:Vector3, t:float)->Vector3: # for hexes
	return Vector3(lerp(a.x, b.x, t),lerp(a.y, b.y, t),lerp(a.z, b.z, t))

static func cube_rotate(radians:float, magnitude:int = 1, from:int = 4)->Vector3i:#rotate [radians] from dir_vec[from] (+ccw)
	var signOf:int = sign(radians)
	var toSixes:float = radians*3/PI
	var sixes:int = floori(toSixes)#num of 1/6th rotations
	var base:int = (from+sixes)%6#new cardinal base after 1/6 circle rotations
	var remains:float = toSixes - sixes
	var steps:int = lerp(0,signOf*magnitude,remains)#number of 1-tile steps off cardinal
	
	return dir_vec[base]*magnitude + dir_vec[(base+2*signOf)%6] * steps

static func cube_angle_to(vec:Vector3i, from:Vector3=dir_vec[4])->float:#returns degrees from dir_vec[from] 
	#		vec>*<---
	#				  \
	#	  *			  *
	#				  |
	#from>*			  *
	#	   \		 /
	#		----*----
	var angle:float = (Vector3(vec).angle_to(from))
	if vec.z>0:
		#correct godot's angle_to
		angle = 2*PI-angle
	return fmod(angle,2*PI)

static func vec3_to_index(vec:Vector3i)->int:
	var radius:int = cube_dist(Vector3i(0,0,0),vec)
	var angle:float = cube_angle_to(vec)
	var inner:int = numSpiral(radius-1)
	var outer:int = numRing(radius)
	var steps:int = roundi(outer * angle/(2*PI))
	return inner + steps

static func index_to_vec3(idx:int)->Vector3i:
	var raw:float = idx_to_rad(idx)
	var radius:int = floori(raw)
	var delta:float = radius - raw
	var rotated:Vector3i = cube_rotate(-delta*2*PI,radius)	
	return rotated

static func index_to_vec2(idx:int)->Vector2i:
	return axial_to_oddr(index_to_vec3(idx))

static func vec2_to_index(vec2:Vector2i)->int:
	return vec3_to_index(oddr_to_axial(vec2))

static func idx_to_rad(num:int)->float:#inverse of numSpiral, given index returns radius + offset
	return  sqrt( float(num-1) / 3 + .25) + .5

static func numRing(radius:int)->int:
	if radius == 0:
		return 1
	return 6*radius

static func numSpiral(radius:int)->int:
	if radius<0:
		return 0
	return 1 + 3 * radius * (radius+1)

static func inRing(center: Vector3i, radius: int)->Array:#ring of tiles(coord)
	var results = []
	if radius==0:
		results.append(center)
		return results
	
	var hex = center + dir_vec[4]*radius
	for i in range(6):
		for j in range(radius):
			results.append(hex)
			hex = get_surround(hex)[i]
	return results

static func inSpiral(center:Vector3i, radius:int)->Array:
	var results = []
	for i in range(0,radius+1,1):
		results.append_array(inRing(center, i))
	return results

static func inLine(start: Vector3i, end:Vector3i)->Array:#tiles(coord) in line
	var a = start
	var b = end
	var results = []
	var n = cube_dist(a,b)
	for i in range(n+1):
		results.append(axial_to_oddr(axial_round(cube_lerp(a, b, 1.0/n * i))))
	return results
