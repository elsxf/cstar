extends RichTextLabel

signal validInput(input)

func popInput(popupText):
	self.visible = true
	DEF.changeFocus(DEF.Focus.POPUP_MENU)
	self.text = popupText
	return await Signal(self,'validInput')
	
func popVector(popupText):
	self.visible = true
	DEF.changeFocus(DEF.Focus.POPUP_MENU)
	self.text = popupText
	var inputstr = await Signal(self,'validInput')
	var inputAction = DEF.keyBinds[inputstr]
	if HEX.dir_str.has(inputAction):
		return HEX.dir_vec[HEX.dir_str[inputAction]]
	return null
	
func _unhandled_key_input(event: InputEvent) -> void:
	if DEF.gameState["focus"]!=DEF.Focus.POPUP_MENU or event.is_released():
		return
	if not DEF.getEventStr(event).is_empty():
		self.visible = false
		DEF.prevFocus()
		validInput.emit(DEF.getEventStr(event))
		get_viewport().set_input_as_handled()
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_visibility_changed() -> void:
	if %MenuBack.visible == false:
		position = Vector2i(0,0)
	else:
		position = Vector2i(64,-256)
	pass # Replace with function body.
