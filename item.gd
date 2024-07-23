extends Resource
class_name Item

@export var name : StringName

var container
var container_array : Array

var shape : StringName
var mat : StringName

var to_hit : int = 0
var blunt : int = 0
var cut : int = 0
var pierce : int = 0

@export var tile_id:int
@export var tile_coord:Vector2
@export var tile_alt = 0

var next_action

func _init(materialName:String,shapeName:String=""):
	if shapeName.is_empty():#predef item name
		self.name = materialName
		self.shape = DEF.item_dict[self.name][&"shape"]
		self.mat = DEF.item_dict[self.name][&"material"]
	else:
		self.name = shapeName
		self.shape = shapeName
		self.mat = materialName
	
	
		
	#tohit calculation
	if DEF.sDefs[self.shape].has(&"to_hit"):
		self.to_hit = DEF.sDefs[self.shape][&"to_hit"]
	else:
		self.to_hit = DEF.sDefs[&"default_shape"][&"to_hit"]
	
	#damage values calcualtion
	self.blunt = DEF.mDefs[self.mat][&"density"]
	var edge = 0
	if DEF.hasFlag(DEF.sDefs[self.shape][&"flags"], DEF.sDefs[&"Flags"][&"hasEdge"]):
		edge = DEF.mDefs[self.mat][&"max_edge"]
	self.cut = DEF.mDefs[self.mat][&"density"] * edge
	self.blunt -= self.cut
	if DEF.hasFlag(DEF.sDefs[self.shape][&"flags"], DEF.sDefs[&"Flags"][&"hasPoint"]):
		self.pierce = DEF.mDefs[self.mat][&"density"] * edge
		self.blunt -= self.pierce
	self.blunt = max(self.blunt,0)

	
		
	
	


func add_to_container(put_array:Array, container_obj):
	put_array.append(self)
	self.container_array = put_array
	self.container = container_obj
	
func free_from_container():
	self.container_array.erase(self)
	self.container = null

func _to_string():
	return "[color="+str(DEF.mDefs[self.mat][&"color"])+"]"+self.name+"[/color]"

func _to_string_verbose():
	var verboseString = _to_string()+"\nto hit:"+str(self.to_hit)
	if self.blunt>0:
		verboseString +=" blunt:"+str(self.blunt)
	if self.cut>0:
		verboseString+=" cut:"+str(self.cut)
	if self.pierce>0:
		verboseString+=" pierce:"+str(self.pierce)
	verboseString += "\n[color=DARK_GRAY]A "+self.shape+" made of "+self.mat+ "[/color]"
	return verboseString

func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass
