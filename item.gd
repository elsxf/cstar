extends Resource
class_name Item

@export var name : String

var container
var container_array : Array

var shape
var mat

@export var tile_id:int
@export var tile_coord:Vector2
@export var tile_alt = 0

var next_action

func _init(materialName:String,shapeName:String=""):
	if shapeName.is_empty():#predef item name
		self.name = materialName
		self.shape = DEF.item_dict[self.name]["shape"]
		self.mat = DEF.item_dict[self.name]["material"]
	else:
		self.name = shapeName
		self.shape = shapeName
		self.mat = materialName
	


func add_to_container(put_array:Array, container_obj):
	put_array.append(self)
	self.container_array = put_array
	self.container = container_obj
	
func free_from_container():
	self.container_array.erase(self)
	self.container = null

func _to_string():
	return "[color="+str(DEF.mDefs[self.mat]["color"])+"]"+self.name+"[/color] "

func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass
