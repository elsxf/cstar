extends GridContainer

#I dont know how these functions work either

signal validInput(input)

var mode:int = MODE.INPUT
var highlight_idx:int = 0
var choices_array:Array = []
var num_choice:int = 0
var is_entering_number:bool = false
enum MODE{INPUT,CHOICE,ALERT,TILE}


func close_popup():
	self.visible = false
	$PopupText.text = ""
	$PopupTitle.text = ""
	choices_array = []
	DEF.prevFocus()

func popInput(popupText):
	mode = MODE.INPUT
	self.visible = true
	DEF.changeFocus(DEF.Focus.POPUP_MENU)
	$PopupTitle.text = popupText
	var result = await Signal(self,'validInput')
	close_popup()
	return result

func popVector(popupText):
	mode = MODE.INPUT
	self.visible = true
	DEF.changeFocus(DEF.Focus.POPUP_MENU)
	$PopupTitle.text = popupText
	var inputstr = await Signal(self,'validInput')
	close_popup()
	if DEF.keyBinds.has(inputstr):
		var inputAction = DEF.keyBinds[inputstr]
		if HEX.dir_str.has(inputAction):
			return HEX.dir_vec[HEX.dir_str[inputAction]]
	return null

func popChoice(popupText:String, choiceList:Array, closeOnChoice:bool = true, onChoiceLambda = null):
	mode = MODE.CHOICE
	self.visible = true
	DEF.changeFocus(DEF.Focus.POPUP_MENU)
	$PopupTitle.text = popupText
	choices_array = choiceList
	while 1:
		var choice = await Signal(self,'validInput')
		if typeof(choice)!=TYPE_INT:
			close_popup()
			return null
		var chosen = choiceList[choice]
		if onChoiceLambda == null:
			close_popup()
			return chosen
		if num_choice==-1 or num_choice==0:
			onChoiceLambda.call(chosen)
		else:
			onChoiceLambda.call(chosen,num_choice)
		if closeOnChoice:
			close_popup()
			break

	pass

func popTile(popupText:String, choiceVecList:Array[Vector3i], drawLine:bool = true):
	mode = MODE.TILE
	self.visible = false
	DEF.changeFocus(DEF.Focus.POPUP_MENU)
	$PopupTitle.text = popupText
	choices_array = choiceVecList
	highlight_idx = 0;
	Signals.emit_signal("HUD_clear_highlight")
	Signals.emit_signal("HUD_highlight_tiles", HEX.inLine(DEF.playerM.curr_c(),choices_array[highlight_idx]),DEF.Highlight_types.DOT)
	Signals.emit_signal("HUD_highlight_tiles", [choices_array[0]])
	var idx = await Signal(self,'validInput')
	if idx is String:# "NoAct":
		close_popup()
		return null
	else:
		var choice = choiceVecList[idx]
		close_popup()
		return choice

func _unhandled_key_input(event: InputEvent) -> void:
	if DEF.gameState[&"focus"]!=DEF.Focus.POPUP_MENU or event.is_released():
		return
	get_viewport().set_input_as_handled()
	if(event.is_action("ui_cancel")):
			#close_popup()
			validInput.emit(DEF.getEventStr(null))
	if (not DEF.getEventStr(event).is_empty()) and mode == MODE.INPUT:
		#close_popup()
		validInput.emit(DEF.getEventStr(event))
	if (mode == MODE.CHOICE):
		if(event.is_action("ui_down")):
			highlight_idx +=1
			if highlight_idx >= choices_array.size():
				highlight_idx = 0
		if(event.is_action("ui_up")):
			highlight_idx -=1
			if highlight_idx < 0:
				highlight_idx = choices_array.size()-1
		#
		if highlight_idx<0:
			highlight_idx = choices_array.size()-1
		if highlight_idx > choices_array.size()-1:
			highlight_idx = 0
		#
		if(event.is_action("ui_select")):
			if choices_array.size()==0:
				close_popup()
			else:
				validInput.emit(highlight_idx)
			#choices_array.pop_at(highlight_idx)
		if(is_entering_number):
			if((DEF.getEventStr(event)).is_valid_int()):
				num_choice *= 10
				num_choice += int(DEF.getEventStr(event))
			else:
				is_entering_number = false
				num_choice = -1
		if(DEF.getEventAction(event)=="number"):
			is_entering_number = true
			num_choice = 0
	if(mode == MODE.TILE):
		var horiz_vector = null
		match DEF.getEventAction(event):
			"Left":
				horiz_vector =HEX.dir_vec[3]
			"Right":
				horiz_vector =HEX.dir_vec[0]
			"URight":
				horiz_vector =HEX.dir_vec[1]
			"DRight":
				horiz_vector =HEX.dir_vec[5]
			"ULeft":
				horiz_vector =HEX.dir_vec[2]
			"DLeft":
				horiz_vector =HEX.dir_vec[4]
		if horiz_vector!=null:
			var new_vec = choices_array[highlight_idx] + horiz_vector
			var next_index = choices_array.find(new_vec)
			if next_index==-1:
				#new vector not valid choice, find closest vector that isn't the original
				var min_dist = DEF.INT_MAX
				var min_index = -1
				for i in choices_array.size():
					if choices_array[i] == choices_array[highlight_idx]:
						continue
					var this_dist = HEX.cube_dist(new_vec,choices_array[i])
					if this_dist<min_dist:
						min_dist = this_dist
						min_index = i
				highlight_idx = min_index
			else:
				highlight_idx = next_index
			Signals.emit_signal("HUD_clear_highlight")
			Signals.emit_signal("HUD_highlight_tiles", HEX.inLine(DEF.playerM.curr_c(),choices_array[highlight_idx]),DEF.Highlight_types.DOT)
			Signals.emit_signal("HUD_highlight_tiles", [choices_array[highlight_idx]])
		if(event.is_action("ui_select")or DEF.getEventAction(event)=="fire" or DEF.getEventAction(event)=="Force_fire"):
			validInput.emit(highlight_idx)
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	$PopupText/BackBufferCopy/Highlight.position.y = highlight_idx*32
	$PopupText.text = DEF.listStr(choices_array)
	pass


func _on_visibility_changed() -> void:
	highlight_idx = 0
	if %GMenu.visible == false:
		position = Vector2i(-256,-128)
	else:
		position = Vector2i(-256,-256)
	pass # Replace with function body.
