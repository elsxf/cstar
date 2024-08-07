extends Resource
class_name Mob

@export var name : String

@export var world_c:Vector2i
@export var dun_c:Vector2i
@export var d_level : int
var list_of_mobs : Array
var FOV = []
@export var sight_range : int
@export var target_tile : Vector2i = Vector2i(-1,-1)

@export var time_u : int = 0
@export var speed : int = 100
@export var attributes:Dictionary = {}

@export var items : Array = []
@export var worn : Array = []
@export var wield : Item = null

@export var Hp_max : int
@export var Hp : int
@export var focus : int = 100

@export var factionStr : String
@export var faction : int
@export var hostile_to : int

@export var tile_id:int
@export var tile_coord:Vector2
@export var tile_alt = 0

var next_action = null
var current_activity = null

func _init(mob_name:String):
	self.name = mob_name
	self.Hp_max = DEF.mob_dict[mob_name]["hp"]
	self.Hp = self.Hp_max
	self.sight_range = DEF.getProperty(DEF.mob_dict,self.name,&"sightRange")
	for w in DEF.getProperty(DEF.mob_dict,self.name,&"wear"):
		var parsed = w.split(" ")
		if parsed.size()==1:
			Item.new(parsed[0]).add_to_container(worn,self)
		else:
			Item.new(parsed[0], parsed[1]).add_to_container(worn,self)
	if not DEF.getProperty(DEF.mob_dict,self.name,&"wield").is_empty():
		var parsed = DEF.getProperty(DEF.mob_dict,self.name,&"wield").split(" ")
		if parsed.size() == 1:
			wield = Item.new(parsed[0])
		else:
			wield = Item.new(parsed[0],parsed[1])
	self.speed = DEF.getProperty(DEF.mob_dict,self.name,&"speed")
	self.attributes = DEF.skill_dict[DEF.getProperty(DEF.mob_dict,self.name,&"skills")]
	self.tile_id = DEF.getProperty(DEF.mob_dict,self.name,&"source")
	self.tile_coord = Vector2i(DEF.getProperty(DEF.mob_dict,self.name,&"A_coord_x"),DEF.getProperty(DEF.mob_dict,self.name,&"A_coord_y"))
	self.factionStr = DEF.getProperty(DEF.mob_dict,self.name,&"faction")
	self.faction = DEF.faction_dict[factionStr]
	self.hostile_to = 0
	for i in  DEF.getProperty(DEF.mob_dict,self.name,&"hostile_to"):
		self.hostile_to = self.hostile_to |  int(DEF.faction_dict[i])

func serialize()->Dictionary:
	var serialStr = {}
	serialStr["Mob"]=[name,dun_c,time_u,target_tile,Hp,focus]
	
	var itemsSerialized = []
	itemsSerialized.resize(items.size())
	for i in items.size():
		itemsSerialized[i] = items[i].serialize()
	serialStr["Items"] = itemsSerialized
	
	var itemsWorn = []
	itemsWorn.resize(worn.size())
	for i in worn.size():
		itemsWorn[i] = worn[i].serialize()
	serialStr["Worn"] = itemsWorn
	
	serialStr["Wield"] = null if wield == null else wield.serialize()
	
	return serialStr

func deSerialize(serialized:Dictionary):
#deserializing
	var parsed = serialized
	_init(parsed["Mob"][0])
	dun_c = Vector2i(HEX.strToVec(parsed["Mob"][1]))
	time_u = int(parsed["Mob"][2])
	target_tile = Vector2i(HEX.strToVec(parsed["Mob"][3]))
	Hp = int(parsed["Mob"][4])
	focus = int(parsed["Mob"][5])
	
	var itemParsed = parsed["Items"]
	var itemList = []
	itemList.resize(itemParsed.size())
	for i in itemParsed.size():
		var newItem = Item.new("default")
		newItem.deSerialize(itemParsed[i])
		itemList[i]=newItem
	items=itemList
	
	var wornParsed = parsed["Worn"]
	var wornList = []
	wornList.resize(wornParsed.size())
	for i in wornParsed.size():
		var newItem = Item.new("default")
		newItem.deSerialize(wornParsed[i])
		wornList[i]=newItem
	worn=wornList
	
	if parsed.size()>9:
		var wieldParsed = parsed["Wield"]
		wield = null if wieldParsed==null else Item.new("defualt").deSerialize(wieldParsed[0])

func set_self(Map:TileMap):
	Map.set_cell(DEF.Layer_Names.Mobs,curr_c(),self.tile_id,self.tile_coord,self.tile_alt)
	
func change_hp(delta:int):
	set_hp(self.Hp+delta)	
	
func get_max_m_range():
	if self.wield ==null:
		return 1
	return DEF.getProperty(DEF.sDefs,self.wield.shape,&"m_range")
	
func set_hp(value:int):
	self.Hp = min(value,Hp_max)
	if self.Hp<=0:
		die()
		
func give_tu(turns:int):
	time_u += turns * speed
	#[turns] seconds pass
	var rest_focus = 100
	for i in turns:
		var focus_delta = pow(rest_focus-focus,.6) if focus<rest_focus else -pow(abs(rest_focus-focus),.6)
		focus += focus_delta

func add_to_data(mob_list:Array, world_coord:Vector2i,hieght:int, coord:Vector2i = Vector2i(DEF.chunk_size/2,DEF.chunk_size/2)):
	self.d_level = hieght
	self.world_c = world_coord
	self.dun_c = coord
	DEF.current_map[curr_c().x][curr_c().y].m_mob = self
	mob_list.append(self)
	self.list_of_mobs = mob_list
	
func free_from_data():
	DEF.current_map[curr_c().x][curr_c().y].m_mob = null
	self.list_of_mobs.erase(self)

func curr_c():
	if(d_level==-1):
		return world_c
	else:
		return dun_c

func can_act() -> bool:
	return time_u >= get_tu_cost()

func act():
	if next_action!=null:
		time_u -= next_action.call(false)
		next_action=null

func get_tu_cost() -> int:
	if next_action!=null:
		return next_action.call(true)
	return -1

func get_access_items(dist:int = 1):
	var valid_items = []
	valid_items.append_array(items)
	valid_items.append_array(worn)
	if wield!=null:
		valid_items.append(wield)
	for i in HEX.inRange(DEF.playerM.curr_c(),dist):
		valid_items.append_array(DEF.current_map[i.x][i.y].i_items)
	return valid_items

func getAttr(attr:String):
	return DEF.numToSkill(self.attributes[attr])

func trainAttr(attr:String, relDiff:float):
	if not DEF.EntryHasFlag(DEF.mob_dict,self.name,&"canTrain"):
		return
	var before = getAttr(attr)
	var exp_earned:int =  max(1,float(focus)/100 * 1.08**relDiff)
	focus -= 1
	self.attributes[attr]+=exp_earned
	if self == DEF.playerM and getAttr(attr)!=before:
		DEF.textBuffer += "[color=green] Your "+str(attr) +" has increased to "+str(getAttr(attr))+"![/color]"

func get_brain():
	if current_activity != null:
		next_action = current_activity
		return 
	for m in self.list_of_mobs:
		if m==self:
			continue
		if DEF.hasFlag(self.hostile_to,m.faction):
			#if hostile to mob
			if(HEX.oddr_dist(self.curr_c(),m.curr_c())<=self.sight_range):
				#if within sight range
				var cansee:bool = true
				#attempt sightLine
				for i in HEX.inLine(self.curr_c(),m.curr_c()):
					if DEF.current_map[i.x][i.y].get_v_cost()==-1:
						cansee = false
						break
				if cansee:
					target_tile = m.curr_c()
					break
	var attack_range = get_max_m_range()
	var target_dist = HEX.oddr_dist(self.curr_c(),target_tile)
	if target_tile == Vector2i(-1,-1):
		target_dist = 0
	var target_mob = DEF.current_map[target_tile.x][target_tile.y].m_mob
	if(target_dist==0):
		#TODO:return to routine
		next_action = func wait_lambda(_calc):
			return  ACT.wait()
		return
	elif(target_dist<=attack_range and target_mob!=null):
		#TODO:attack with shortest range attack possible
		next_action = func attack_lambda(calc):
			return  ACT.attack_phys_melee(self,target_tile,calc)
		return
	else:
		var next_step = PATH.pathFind(curr_c(),target_tile,DEF.current_map).back()
		
		next_action = func move_to_lambda(calc):
			return  ACT.move_horizontal(self,HEX.get_c_vector(next_step,curr_c()),0,calc)
		return
	
func get_action_str():
	if next_action!=null:
		return str(next_action)
	return "noAct"
	
func get_map():
	if self.d_level == DEF.current_level && (DEF.current_coords==null or self.world_c == DEF.current_coords):
		return DEF.current_map
	else:
		return [self.d_level, self.world_c]
	
func die():
	#drop loot
	for i in items:
		i.add_to_container(DEF.current_map[curr_c().x][curr_c().y].i_items,DEF.current_map[curr_c().x][curr_c().y])
	for i in worn:
		i.add_to_container(DEF.current_map[curr_c().x][curr_c().y].i_items,DEF.current_map[curr_c().x][curr_c().y])
	if wield!=null:
		wield.add_to_container(DEF.current_map[curr_c().x][curr_c().y].i_items,DEF.current_map[curr_c().x][curr_c().y])
	free_from_data()

func _to_string():
	return self.name + " at "+str(curr_c())

func _ready():
	pass # Replace with function body.

func LOS(setFov:bool = true):
	var canSee = []
	if DEF.debug_esp:
		for i in HEX.inRange(curr_c(),30):
			if DEF.isInChunk(i):
				canSee.append(i)
		return canSee
	for i in HEX.get_surround(curr_c()):
		if DEF.isInChunk(i):
			canSee.append(i)
	for i in HEX.inRing(curr_c(),sight_range):
		for j in HEX.inLine(curr_c(),i):
			if not DEF.isInChunk(j):
				break
			if not canSee.has(j):
				canSee.append(j)
			var tile = DEF.current_map[j.x][j.y]
			if tile.get_v_cost()==-1:
				break
	if setFov:
		FOV = canSee
	return canSee
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass
