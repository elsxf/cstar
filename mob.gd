extends Resource
class_name Mob

@export var name : String

var world_c:Vector2i
var dun_c:Vector2i
var d_level : int
var map : Array
var list_of_mobs : Array
var FOV = []
var sight_range : int
var target_tile : Vector2i = Vector2i(-1,-1)

var time_u : int = 0
var speed : int = 100

var items : Array = []
var worn : Array = []
var wield : Item = null

@export var Hp_max : int
var Hp : int

var factionStr : String
@export var faction : int
@export var hostile_to : int

@export var tile_id:int
@export var tile_coord:Vector2
@export var tile_alt = 0

var next_action

func _init(mob_name:String):
	self.name = mob_name
	self.Hp_max = DEF.mob_dict[mob_name]["hp"]
	self.Hp = self.Hp_max
	self.sight_range = DEF.mob_dict[mob_name]["sightRange"]
	if DEF.mob_dict[mob_name].has("wear"):
		for w in DEF.mob_dict[mob_name]["wear"]:
			var parsed = w.split(" ")
			if parsed.size()==1:
				Item.new(parsed[0]).add_to_container(worn,self)
			else:
				Item.new(parsed[0], parsed[1]).add_to_container(worn,self)
	if DEF.mob_dict[mob_name].has("wield"):
		var parsed = DEF.mob_dict[mob_name]["wield"].split(" ")
		if parsed.size() == 1:
			wield = Item.new(parsed[0])
		else:
			wield = Item.new(parsed[0],parsed[1])
	self.speed = DEF.mob_dict[mob_name]["speed"]
	self.tile_id = DEF.mob_dict[mob_name]["source"]
	self.tile_coord = Vector2i(DEF.mob_dict[mob_name]["A_coord_x"],DEF.mob_dict[mob_name]["A_coord_y"])
	self.factionStr = DEF.mob_dict[mob_name]["faction"]
	self.faction = DEF.faction_dict[factionStr]
	self.hostile_to = 0
	for i in DEF.mob_dict[mob_name]["hostile_to"]:
		self.hostile_to = self.hostile_to |  int(DEF.faction_dict[i])

func set_self(Map:TileMap):
	Map.set_cell(DEF.Layer_Names.Mobs,curr_c(),self.tile_id,self.tile_coord,self.tile_alt)
	
func change_hp(delta:int):
	set_hp(self.Hp+delta)	
	
func set_hp(value:int):
	self.Hp = min(value,Hp_max)
	if self.Hp<=0:
		die()
		
func give_tu(turns:int):
	time_u += turns * speed

func add_to_data(map_array:Array,mob_list:Array, world_coord:Vector2i,hieght:int, coord:Vector2i = Vector2i(DEF.chunk_size/2,DEF.chunk_size/2)):
	self.d_level = hieght
	self.world_c = world_coord
	self.dun_c = coord
	map_array[curr_c().x][curr_c().y].m_mob = self
	self.map = map_array
	mob_list.append(self)
	self.list_of_mobs = mob_list
	
func free_from_data():
	self.map[curr_c().x][curr_c().y].m_mob = null
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

func get_brain():
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
					if self.map[i.x][i.y].get_v_cost()==-1:
						cansee = false
						break
				if cansee:
					target_tile = m.curr_c()
					break
	var attack_range = 1
	var target_dist = HEX.oddr_dist(self.curr_c(),target_tile)
	if target_tile == Vector2i(-1,-1):
		target_dist = 0
	var target_mob = map[target_tile.x][target_tile.y].m_mob
	if(target_dist==0):
		#TODO:return to routine
		next_action = func wait_lambda(_calc):
			return  ACT.wait()
		return
	elif(target_dist<=attack_range and target_mob!=null):
		#TODO:attack with shortest range attack possible
		next_action = func attack_lambda(calc):
			return  ACT.attack_phys(self,target_tile,calc)
		return
	else:
		var next_step = PATH.pathFind(curr_c(),target_tile,map).back()
		
		next_action = func move_to_lambda(calc):
			return  ACT.move_horizontal(self,map,HEX.get_c_vector(next_step,curr_c()),0,calc)
		return
	
func get_action_str():
	if next_action!=null:
		return str(next_action)
	return "noAct"
	
func die():
	#drop loot
	for i in items:
		i.add_to_container(self.map[curr_c().x][curr_c().y].i_items,self.map[curr_c().x][curr_c().y])

	free_from_data()

func _to_string():
	return self.name + " at "+str(curr_c())

func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass
