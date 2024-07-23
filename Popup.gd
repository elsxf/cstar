extends GridContainer

signal validInput(input)

var mode = MODE.INPUT
var highlight_idx = 0
var choices_array = []
enum MODE{INPUT,CHOICE,ALERT}


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
	return await Signal(self,'validInput')
	
func popVector(popupText):
	mode = MODE.INPUT
	self.visible = true
	DEF.changeFocus(DEF.Focus.POPUP_MENU)
	$PopupTitle.text = popupText
	var inputstr = await Signal(self,'validInput')
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
			break
		var chosen = choiceList[choice]
		if onChoiceLambda == null:
			return chosen
		onChoiceLambda.call(chosen)
		if closeOnChoice:
			break
	pass
	
func _unhandled_key_input(event: InputEvent) -> void:
	if DEF.gameState[&"focus"]!=DEF.Focus.POPUP_MENU or event.is_released():
		return
	get_viewport().set_input_as_handled()
	if(event.is_action("ui_cancel")):
			close_popup()
			validInput.emit(DEF.getEventStr(null))
	if (not DEF.getEventStr(event).is_empty()) and mode == MODE.INPUT:
		close_popup()
		validInput.emit(DEF.getEventStr(event))
	if (mode == MODE.CHOICE):
		if(event.is_action("ui_down")):
			highlight_idx +=1
		if(event.is_action("ui_up")):
			highlight_idx -=1
		if(event.is_action("ui_select")):
			validInput.emit(highlight_idx)
			#choices_array.pop_at(highlight_idx)

			
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	$PopupText/Highlight.position.y = highlight_idx*32
	$PopupText.text = DEF.listStr(choices_array)
	pass


func _on_visibility_changed() -> void:
	highlight_idx = 0
	if %GMenu.visible == false:
		position = Vector2i(0,0)
	else:
		position = Vector2i(-64,-256)
	pass # Replace with function body.
