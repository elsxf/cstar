extends Item
class_name RawMat

func _init(materialName, vol):
	self.mat = materialName
	self.shape = DEF.getProperty(DEF.mDefs,self.mat,"raw")
	super(self.mat,self.shape)
	self.volume = vol
	self.weight = self.volume * self.density
	self.to_hit = -10
	self.blunt = 0
	self.pierce = 0
	self.cut = 0
	
func _to_string(wght:bool = false,vol:bool=true):
	return super(wght,vol)
	
func _to_string_verbose():
	var verboseString = _to_string(true,true)+"\n"
	verboseString += "\n[color=DARK_GRAY]Raw "+self.mat+" "+self.shape+" for crafting"+ "[/color]"
	return verboseString

func add_to_container(put_array:Array, container_obj, num_to_add:int = -1):
	for i in put_array:
		if i.mat==self.mat and i is RawMat:
			i.volume += self.volume
			i.weight += self.weight
			return
	put_array.append(self)
	self.container_array = put_array
	self.container = container_obj
