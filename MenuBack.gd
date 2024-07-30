extends Panel

var left_idx:int = 0
var right_idx:int = 0
enum{
	LEFT=0,
	RIGHT=1,
}
var active_panel:int = LEFT
var Panel2_enabled:bool = false

var left_elements = {}
var left_array = []
var right_elements = {}
var right_array = []

var panel_line_count: int = -1
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	panel_line_count = $Panel1.size.y/32
	pass # Replace with function body.

func enter_menu(menuName:String):
	left_idx = 0
	right_idx = 0
	DEF.changeFocus(DEF.Focus.GAME_MENU)
	self.visible = true
	for i in $Pages.tab_count:
		if $Pages.get_tab_title(i) == menuName:
			$Pages.current_tab = i
			break
	draw_panel()
	
			
func close_menu():
	self.visible = false
	DEF.prevFocus()

func draw_elements(elements:Dictionary, panel:RichTextLabel, lambda=func foo(bar):return bar):
	for names in elements.keys():
		if not names.is_empty():
			panel.text += "[color=pink][u]"+names+"[/u][/color] "
		if(typeof(elements[names])==TYPE_ARRAY):
			panel.text += "\n"+DEF.listStr(elements[names])
		elif(typeof(elements[names])==TYPE_DICTIONARY):
			panel.text += "\n"
			draw_elements(elements[names], panel,lambda)
		else:
			panel.text += str(lambda.call(elements[names]))+"\n"
		
func arrayFromDict(elements:Dictionary)->Array:
	var result = []
	for v in elements.values():
		if typeof(v)==TYPE_ARRAY:
			result.append_array(unNestArray(v))
		else:
			result.append(v)
	return result
		
func unNestArray(nested:Array)->Array:
	if nested.all(func(e): return typeof(e)!=TYPE_ARRAY):
		return nested
	var result = []
	for i in nested:
		if typeof(i)==TYPE_ARRAY:
			result.append_array(unNestArray(i))
		else:
			result.append(i)
	return result
			
				
func linesFromTop(idx:int,elements:Dictionary):
	var lines = idx
	var offset:int = 0
	for v in elements.values():
		offset+= 0 if elements.find_key(v).is_empty() else 1
		idx -= (v.size() if typeof(v)==TYPE_ARRAY else 1)
		if(idx<0):
			break;
	return lines+offset

func draw_panel():
	left_elements.clear()
	right_elements.clear()
	var left_lambda = func foo(bar):return bar
	var right_lambda = func foo(bar):return bar
	match $Pages.get_tab_title($Pages.current_tab):
		"Inventory":
			left_elements["Items Carried"] = DEF.playerM.items
			left_array = arrayFromDict(left_elements)
			if(DEF.playerM.wield!=null):
				right_elements[""] = DEF.playerM.wield
			right_elements["Items Worn"] = DEF.playerM.worn
			right_array = arrayFromDict(right_elements)
			Panel2_enabled = true
		"Keybinds":
			left_elements["Actions"] = DEF.actionBinds.keys()
			left_array = DEF.actionBinds.keys()
			right_elements["Controls"] = DEF.actionBinds.values()
			right_array = DEF.actionBinds.values()
			Panel2_enabled = false
			active_panel = LEFT
			right_idx=left_idx
			#$Panel2.get_v_scroll_bar().value=$Panel1.get_v_scroll_bar().value
		"Character":
			left_elements["Attributes"]= DEF.playerM.attributes
			left_array = left_elements["Attributes"].keys()
			left_lambda = func toSkill(skill):return DEF.numToSkill(skill,true)
			Panel2_enabled = false
			pass
		"Construct":
			left_elements["Constuctions"] = DEF.construct_dict.keys()
			left_array = DEF.construct_dict.keys()
			right_elements["Needs"] = DEF.construct_dict[left_array[left_idx]]
			right_array = []
			Panel2_enabled = false
			active_panel = LEFT
		"Craft":
			left_elements["Crafts"] = CRAFT.get_craftable_list()
			left_array = left_elements["Crafts"]
			#display selected recipie recipie
			right_elements["Needs"] = CRAFT.get_recipie(left_array[left_idx],DEF.playerM)
			right_array = []
			Panel2_enabled = false
			active_panel = LEFT
	$Panel1.text = ""
	$Panel2.text = ""
	draw_elements(left_elements,$Panel1,left_lambda)
	draw_elements(right_elements,$Panel2,right_lambda)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if not visible:
		return
	if DEF.gameState[&"focus"]!=DEF.Focus.GAME_MENU:
		return
	
	#TODO: only update when called, not every frame
	
	
	if active_panel==LEFT:
		$Highlight.position.y = $Panel1.position.y + linesFromTop(left_idx,left_elements)*32 - $Panel1.get_v_scroll_bar().value
		$Highlight.position.x = $Panel1.position.x
	else:
		$Highlight.position.y = $Panel1.position.y + linesFromTop(right_idx,right_elements)*32 - $Panel2.get_v_scroll_bar().value
		$Highlight.position.x = $Panel1.size.x + $Panel1.position.x
	pass
	

func _unhandled_key_input(event: InputEvent) -> void:
	if DEF.gameState[&"focus"]!=DEF.Focus.GAME_MENU or event.is_released():
		return
	get_viewport().set_input_as_handled()
	draw_panel()
	if(event.is_action("ui_down")):
		if active_panel==LEFT:
			left_idx +=1
		else:
			right_idx+=1
		pass
	if(event.is_action("ui_up")):
		if active_panel==LEFT:
			left_idx -=1
		else:
			right_idx-=1
			
		pass
	if(left_idx<0):
		left_idx = left_array.size()-1
	if(right_idx<0):
		right_idx = right_array.size()-1
	if(left_idx>=left_array.size()):
		left_idx = 0
	if(right_idx>=right_array.size()):
		right_idx = 0

		
	if(event.is_action("ui_left") or event.is_action("ui_right")):
		active_panel = 1^active_panel
		if(right_array.size()==0):
			active_panel = LEFT

		
	match DEF.getEventAction(event):
		"auto":
			if $Pages.current_tab==$Pages.tab_count-1:
				$Pages.current_tab = 0
			else:
				$Pages.current_tab+=1
			left_idx=0
			right_idx=0
		"b_auto":
			if $Pages.current_tab==0:
				$Pages.current_tab = $Pages.tab_count - 1
			else:
				$Pages.current_tab-=1
			left_idx=0
			right_idx=0
		"OpenInventory":
			if $Pages.get_tab_title($Pages.current_tab)=="Inventory":
				close_menu()
			else:
				enter_menu("Inventory")
		"keybindings":
			if $Pages.get_tab_title($Pages.current_tab)=="Keybinds":
				close_menu()
			else:
				enter_menu("Keybinds")
		"craft":
			if $Pages.get_tab_title($Pages.current_tab)=="Craft":
				close_menu()
			else:
				enter_menu("Craft")
		"construct":
			if $Pages.get_tab_title($Pages.current_tab)=="Construct":
				close_menu()
			else:
				enter_menu("Construct")
	draw_panel()
	$Panel1.scroll_to_line(left_idx-1)
	$Panel2.scroll_to_line(right_idx-1)
	if(event.is_action("ui_select")):
		match $Pages.get_tab_title($Pages.current_tab):
			"Inventory":
				if active_panel==LEFT:
					%Popup.popInput(left_array[left_idx]._to_string_verbose())
				else:
					%Popup.popInput(right_array[right_idx]._to_string_verbose())
			"Keybinds":
				DEF.actionBinds[left_array[left_idx]] = await %Popup.popInput("Enter a new key:")
				DEF.keyBinds = DEF.reverseDict(DEF.actionBinds)
			"Craft":
				var recepie = null
				var chosen_shape = left_array[left_idx]
				if right_elements["Needs"].has("Materials"):
					#if made from raw, get material
					var chosen_material
					#TODO:filter out materials of which there arn't enough of
					var material_choices = right_elements["Needs"]["Materials"]
					match material_choices.size():
						0:
							await %Popup.popInput("Nothing to make it from!")
							return
						1:
							chosen_material = material_choices[0]
						_:
							chosen_material = await %Popup.popChoice("Make From:", material_choices)
					if chosen_material == null:
						return
					#get all items of given material
					var valid_items = []
					for i in DEF.playerM.get_access_items():
						if i.mat == chosen_material and i.subItems.is_empty():
							valid_items.append(i)
					var volume_needed = DEF.getProperty(DEF.sDefs,chosen_shape,"m_count")
					var volume_has = 0
					var reagent_choices = []
					while(volume_has<volume_needed):
						var chosen_reagent =  await %Popup.popChoice("need "+ DEF.dispLiter(volume_needed-volume_has) + " more of", valid_items)
						if chosen_reagent==null:
							return
						volume_has += chosen_reagent.volume
						reagent_choices.append(chosen_reagent)
						valid_items.erase(chosen_reagent)
					var result = Item.new(chosen_material,chosen_shape)
					recepie = Recipie.new(result,reagent_choices,volume_has/volume_needed)
				elif right_elements["Needs"].has("Items"):#subitem craft
					var reagent_choices = []
					for shape in right_elements["Needs"]["Items"]:
						#get all items of shape
						var valid_items = []
						for item in DEF.playerM.get_access_items():
							if item.shape == shape:
								valid_items.append(item)
						if valid_items.size()==0:
							await %Popup.popInput("Missing Ingredients!")
							return
						var chosen_reagent =  await %Popup.popChoice("need "+str(shape)+":", valid_items)
						if chosen_reagent==null:
							return
						reagent_choices.append(chosen_reagent)
					var result = Item.new(reagent_choices,chosen_shape)
					#print(result._to_string_verbose())
					recepie = Recipie.new(result,reagent_choices)
				if recepie != null:
					recepie.add_to_container(DEF.playerM.items,DEF.playerM)
				Signals.emit_signal("Player_take_action", func craft_lambda(calc):
					return ACT.craft(DEF.playerM,recepie,calc))
			"Construct":
				close_menu()
				var tile_coords = HEX.add_2_3(DEF.playerM.curr_c(),await %Popup.popVector("construct where?"))
				var tile_to_place:Tile = DEF.playerM.map[tile_coords.x][tile_coords.y]
				if not tile_to_place.f_name.is_empty() or tile_to_place.get_m_cost()==-1:
					await %Popup.popInput("Something is there!")
					return
				var reagents = {}
				for entry in DEF.construct_dict[left_array[left_idx]]["Ingredients"]:
					var valid_choices = []#items the player has enough of
					for item in entry.keys():
						var num_needed = entry[item]
						if DEF.numOfItem(DEF.playerM.items,item) >= num_needed:
							valid_choices.append(item)
					match valid_choices.size():
						0:
							await %Popup.popInput("Nothing to make it from")
							return
						1:
							reagents[valid_choices[0]]=entry[valid_choices[0]]
						_:
							var item_choice = await %Popup.popChoice("Use Which?", valid_choices)
							reagents[item_choice]=entry[item_choice]
				#if player has enough in inventory, remove items
				for entry in reagents:
					var num_needed = reagents[entry]
					for item in DEF.playerM.items:
						if DEF.isItemByName(item,entry):
							var count = item.count
							item.free_from_container(num_needed)
							num_needed -= count
							if num_needed<=0:
								break
				#place constuction
				tile_to_place.f_name="Constuction"
				var into = left_array[left_idx]
				var time_u = DEF.construct_dict[left_array[left_idx]]["Time"]
				tile_to_place.feature_data = {"work_total":time_u,"work_left":time_u,"feature_into":into}
				Signals.Player_take_action.emit(func construct_lambda(calc):
					return ACT.construct(DEF.playerM,tile_to_place,calc))
						
					
		#TODO: the thing
		pass
	draw_panel()
	if(event.is_action("ui_cancel")):
		close_menu()
