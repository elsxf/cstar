extends Resource
class_name Item

@export var name : StringName

var container
var container_array : Array

var shape : StringName
var mat : StringName

var weight : float

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
	self.to_hit = DEF.getProperty(DEF.sDefs,self.shape,&"to_hit")
	
	#damage values calcualtion
	self.weight = DEF.getProperty(DEF.mDefs,self.mat,&"density") * 2#DEF.getProperty(DEF.sDefs,self.shape,&"m_count")
	self.blunt = weight
	var edge = DEF.getProperty(DEF.mDefs,self.mat,&"hardness")/DEF.getProperty(DEF.mDefs,self.mat,&"toughness")
	if DEF.hasFlag(DEF.getProperty(DEF.sDefs,self.shape,&"flags"), DEF.sDefs[&"Flags"][&"hasEdge"]):
		self.cut = min(self.blunt,max(1,weight * edge))
		self.blunt -= self.cut
	if DEF.hasFlag(DEF.getProperty(DEF.sDefs,self.shape,&"flags"), DEF.sDefs[&"Flags"][&"hasPoint"]):
		self.pierce = min(self.blunt,max(1,weight * edge/2))
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
	return str(weight)+"# [color="+str(DEF.getProperty(DEF.mDefs,self.mat,&"color"))+"]"+self.name+"[/color]"

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
