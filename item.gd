extends Resource
class_name Item

@export var name : StringName

@export var container : Resource
@export var container_array : Array

@export var shape : StringName
@export var mat : StringName

@export var weight : int = 0#in grams
@export var volume : int = 0#in mL
@export var density : float = 1#in g/mL
@export var count : int = 1

@export var to_hit : int = 0
@export var blunt : int = 0
@export var cut : int = 0
@export var pierce : int = 0

@export var tile_id:int
@export var tile_coord:Vector2

func _init(materialName,shapeName:String="", num_of:int=1):
	count = num_of
	if materialName is Item:
		self.name = materialName.name
		self.shape = materialName.shape
		self.mat = materialName.mat
		self.weight = int(materialName.weight)
		self.volume = int(materialName.volume)
		self.density = float(materialName.density)
	elif shapeName.is_empty() and materialName is String:#predef item
		#predef item name, get defs from item.jons
		self.name = materialName
		self.shape = DEF.item_dict[self.name][&"shape"]
		self.mat = DEF.item_dict[self.name][&"material"]
		self.volume = DEF.getProperty(DEF.sDefs,self.shape,&"m_count")
		self.density = DEF.getProperty(DEF.mDefs,self.mat,&"density")
		self.weight = self.density * self.volume
	elif DEF.getProperty(DEF.sDefs,shapeName,&"m_count") is Array:#multipart item
		self.shape = shapeName
		self.name = shapeName
		for shapes in range(DEF.getProperty(DEF.sDefs,shapeName,&"m_count").size()):
			var subItemMat
			var subItemShape
			if materialName is Array:
				subItemMat = materialName[shapes]
			else:
				subItemMat = materialName
			subItemShape = DEF.getProperty(DEF.sDefs,shapeName,&"m_count")[shapes]
			var tempItem = Item.new(subItemMat,subItemShape)
			self.volume += tempItem.volume
			self.weight += tempItem.weight
		self.mat =  materialName[0].mat if materialName is Array else materialName
		self.density = DEF.getProperty(DEF.mDefs,self.mat,&"density")
	else:#material/shape definition
		self.name = shapeName
		self.shape = shapeName
		self.mat = materialName
		self.volume = DEF.getProperty(DEF.sDefs,self.shape,&"m_count")
		self.density = DEF.getProperty(DEF.mDefs,self.mat,&"density")
		self.weight = self.density*self.volume
		
	#tohit calculation
	self.to_hit = DEF.getProperty(DEF.sDefs,self.shape,&"to_hit")
	
	#damage values calcualtion
	self.blunt = sqrt(weight/1000)
	var edge = DEF.getProperty(DEF.mDefs,self.mat,&"hardness")/DEF.getProperty(DEF.mDefs,self.mat,&"toughness")
	if DEF.hasFlag(DEF.getProperty(DEF.sDefs,self.shape,&"flags"), DEF.sDefs[&"Flags"][&"hasEdge"]):
		self.cut = max(1,density * sqrt(edge))
		self.blunt -= self.cut
	if DEF.hasFlag(DEF.getProperty(DEF.sDefs,self.shape,&"flags"), DEF.sDefs[&"Flags"][&"hasPoint"]):
		self.pierce = max(1,self.density * sqrt(edge/2))
		self.blunt -= self.pierce
	self.blunt = max(self.blunt,0)

func add_to_container(put_array:Array, container_obj, num_to_add:int = -1):
	if num_to_add == -1 or num_to_add>=count:
		put_array.append(self)
		self.container_array = put_array
		self.container = container_obj
	else:
		var to_put = Item.new(self)
		to_put.count = num_to_add
		put_array.append(to_put)
		to_put.container_array = put_array
		to_put.container = container_obj
	
func serialize()->Dictionary:
	var serialStr = {}
	serialStr["Item"] = [name, mat, shape, weight, volume, density]
	return serialStr
	
func deSerialize(serialized : Dictionary):
	self.name = serialized["Item"][0]
	self.mat = serialized["Item"][1]
	self.shape = serialized["Item"][2]
	self.weight = serialized["Item"][3]
	self.volume = serialized["Item"][4]
	self.density = serialized["Item"][5]

func free_from_container(num_to_free:int = -1):
	if num_to_free == -1 or num_to_free>=count:
		self.container_array.erase(self)
		self.container = null
	else:
		count -= num_to_free
		
func transfer_to_container(to_container, to_container_array:Array, num_to_transfer:int = -1):
	free_from_container(num_to_transfer)
	add_to_container(to_container_array,to_container,num_to_transfer)

func _to_string(wght:bool = false,vol:bool=false):
	var returnStr = ""
	
	if container is Mob:
		if container.wield == self:
			returnStr += "[color=pink][u]Wielded [/u][/color]"
		if container.worn.has(self):
			returnStr += "[color=pink][u]Worn [/u][/color]"
		if wght:
			returnStr += DEF.dispKg(weight)+" "
		if vol:
			returnStr += DEF.dispLiter(volume)+" "
	returnStr += " [color="+str(DEF.getProperty(DEF.mDefs,self.mat,&"color"))+"]"+self.name+"[/color]"
	if count>1:
		returnStr+=" ("+str(count)+")"
	return returnStr

func _to_string_verbose():
	var verboseString = _to_string(true,true)+"\nto hit:"+str(self.to_hit)
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
