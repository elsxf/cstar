extends Item
class_name Recipie

var Into_item : Item
var Ing :Array = []
var tu_left : int = -1
var tu_total : int = -1
var num_results : int = 1#number of Into_item to make

func _init(Into:Item, Reagents:Array, num_of = 1):
	shape = &"Recipie"
	mat = Into.mat

	weight = 0
	for i in Ing:
		weight+=i.weight

	to_hit = -100
	blunt = 0
	cut = 0
	pierce = 0
	Into_item = Into
	Ing = Reagents
	for i in Ing:
		i.free_from_container()
	num_results = num_of
	var item_mat_difficulty = DEF.getProperty(DEF.mDefs,Into.mat,&"hardness")/2 * DEF.getProperty(DEF.mDefs,Into.mat,&"strength") / DEF.getProperty(DEF.mDefs,Into.mat,&"toughness")
	tu_left = item_mat_difficulty * Into.weight * 50 / 1000
	tu_total = tu_left

func work_on(time_u:int):
	tu_left -= time_u
	if tu_left<=0:
		Into_item.count = num_results
		Into_item.add_to_container(container_array,container)
		free_from_container()
		return true
	return false
		
func cancel_craft():
	for i in Ing:
		i.add_to_container(container_array,container)
	free_from_container()

func _to_string(_wght:bool = false,_vol:bool=false):
	return "In progress "+str(Into_item)+" ("+str(100 * float(tu_left)/tu_total)+"%)"

func _to_string_verbose():
	return _to_string() +"\n"+DEF.listStr(Ing)


func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass
