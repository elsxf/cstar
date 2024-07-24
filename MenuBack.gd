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
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
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
	
			
func close_menu():
	self.visible = false
	DEF.prevFocus()

func draw_elements(elements:Dictionary, panel:RichTextLabel):
	for names in elements.keys():
		if not names.is_empty():
			panel.text += "[color=pink][u]"+names+"[/u][/color]\n"
		if(typeof(elements[names])==TYPE_ARRAY):
			panel.text += DEF.listStr(elements[names])
		elif(typeof(elements[names])==TYPE_DICTIONARY):
			draw_elements(elements[names], panel)
		else:
			panel.text += str(elements[names])+"\n"
		
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
		offset+=1
		idx -= (v.size() if typeof(v)==TYPE_ARRAY else 1)
		if(idx<0):
			break;
	return lines+offset


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not visible:
		return
	if DEF.gameState[&"focus"]!=DEF.Focus.GAME_MENU:
		return
	
	#TODO: only update when called, not every frame
	left_elements.clear()
	right_elements.clear()
	match $Pages.get_tab_title($Pages.current_tab):
		"Inventory":
			left_elements["Items Carried"] = DEF.playerM.items
			left_array = arrayFromDict(left_elements)
			if(DEF.playerM.wield!=null):
				right_elements["Wielded"] = DEF.playerM.wield
			right_elements["Items Worn"] = DEF.playerM.worn
			right_array = arrayFromDict(right_elements)
		"Keybinds":
			left_elements["Actions"] = DEF.actionBinds.keys()
			left_array = DEF.actionBinds.keys()
			right_elements["Controls"] = DEF.actionBinds.values()
			right_array = DEF.actionBinds.values()
			Panel2_enabled = false
			active_panel = LEFT
		"Character":
			pass
		"Construct":
			left_elements["Constuctions"] = DEF.construct_dict.keys()
			left_array = DEF.construct_dict.keys()
			right_elements["Needs"] = DEF.construct_dict[left_array[left_idx]]
			right_array = []
			Panel2_enabled = false
			active_panel = LEFT
		"Craft":
			left_elements["Crafts"] = DEF.sDefs.keys().slice(2)
			left_array = DEF.sDefs.keys()
			#build recipie
			var recipie = {}
			var item = left_array[left_idx]
			var itemFlags = DEF.getProperty(DEF.sDefs,item,&"flags")
			var reqFlag = 0
			reqFlag |= int(DEF.mDefs[&"Flags"][&"isShapeable"]) if DEF.hasFlag(itemFlags, DEF.sDefs[&"Flags"][&"needsShapeable"]) else 0
			reqFlag |= int(DEF.mDefs[&"Flags"][&"isCloth"]) if DEF.hasFlag(itemFlags, DEF.sDefs[&"Flags"][&"needsClothLike"]) else 0
			recipie["Count"] = str(DEF.getProperty(DEF.sDefs,item,&"m_count")) + "# of:"
			#TODO: get surrounding items too
			var player_mats = []
			for i in DEF.playerM.items:
				if reqFlag & DEF.mDefs[i.mat][&"flags"] != reqFlag:
						continue;
				if not player_mats.has(i.mat):
					player_mats.append(i.mat)
					
			recipie["Materials"] = player_mats
			right_elements["Needs"] = recipie
			right_array = []
			Panel2_enabled = false
			active_panel = LEFT
	$Panel1.text = ""
	$Panel2.text = ""
	draw_elements(left_elements,$Panel1)
	draw_elements(right_elements,$Panel2)
	
	if active_panel==LEFT:
		$Panel1/Highlight.position.y = linesFromTop(left_idx,left_elements)*32
		$Panel1/Highlight.position.x = 0
	else:
		$Panel1/Highlight.position.y = linesFromTop(right_idx,right_elements)*32
		$Panel1/Highlight.position.x = $Panel1/Highlight.size.x
	pass
	

func _unhandled_key_input(event: InputEvent) -> void:
	if DEF.gameState[&"focus"]!=DEF.Focus.GAME_MENU or event.is_released():
		return
	get_viewport().set_input_as_handled()
	if(event.is_action("ui_down")):
		if active_panel==LEFT:
			left_idx +=1
		else:
			right_idx+=1
		#if highlight_idx.y>=19:
			#highlight_idx.y -=1
			#$Panel1.scroll_to_line($Panel1.get_v_scroll_bar().value/32 + 1)
		pass
	if(event.is_action("ui_up")):
		if active_panel==LEFT:
			left_idx -=1
		else:
			right_idx-=1
		#if highlight_idx.y<0:
			#if $Panel1.get_v_scroll_bar().value/32 > 0:
				#highlight_idx.y +=1
				#$Panel1.scroll_to_line($Panel1.get_v_scroll_bar().value/32 - 1)
			#else:
				#highlight_idx.y = 18
				#$Panel1.scroll_to_line($Panel1.get_v_scroll_bar().max_value)
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
	match DEF.getEventAction(event):
		"auto":
			if $Pages.current_tab==$Pages.tab_count-1:
				$Pages.current_tab = 0
			else:
				$Pages.current_tab+=1
		"b_auto":
			if $Pages.current_tab==0:
				$Pages.current_tab = $Pages.tab_count - 1
			else:
				$Pages.current_tab-=1
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
	if(event.is_action("ui_select")):
		var selected = 0#highlight_idx.y + $Panel1.get_v_scroll_bar().value/32
		match $Pages.get_tab_title($Pages.current_tab):
			"Inventory":
				if active_panel==LEFT:
					%Popup.popInput(left_array[left_idx]._to_string_verbose())
				else:
					%Popup.popInput(right_array[right_idx]._to_string_verbose())
			"Keybinds":
				DEF.actionBinds[left_array[left_idx]] = await %Popup.popInput("Enter a new key:")
				DEF.keyBinds = DEF.reverseDict(DEF.actionBinds)
		#TODO: the thing
		pass
	if(event.is_action("ui_cancel")):
		close_menu()
