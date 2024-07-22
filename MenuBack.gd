extends Panel

var highlight_idx = Vector2i(0,0)
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func enter_menu(menuName:String):
	highlight_idx = Vector2i(0,0)
	DEF.changeFocus(DEF.Focus.GAME_MENU)
	self.visible = true
	for i in $Pages.tab_count:
		if $Pages.get_tab_title(i) == menuName:
			$Pages.current_tab = i
			break
			
func close_menu():
	self.visible = false
	DEF.prevFocus()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not visible:
		return
	if DEF.gameState["focus"]!=DEF.Focus.GAME_MENU:
		return
	$Panel1/Highlight.position.y = highlight_idx.y*32
		
	match $Pages.get_tab_title($Pages.current_tab):
		"Inventory":
			$Panel1.text = "[color=pink][u]Items carried:[/u][/color]\n" + DEF.listStr(DEF.playerM.items)
			$Panel2.text = "[color=brown]Nothing wielded[/color]" if DEF.playerM.wield==null else str(DEF.playerM.wield)
			$Panel2.text += "\n[color=pink][u]Items Worn:[/u][/color]\n"+ DEF.listStr(DEF.playerM.worn)
		"Keybinds":
			$Panel1.text = DEF.listStr(DEF.actionBinds.keys())
			$Panel2.text = DEF.listStr(DEF.actionBinds.values())
		"Character":
			$Panel1.text = "todo:stuff goes here"
			$Panel2.text = "or here"
	pass
	
func _unhandled_key_input(event: InputEvent) -> void:
	if DEF.gameState["focus"]!=DEF.Focus.GAME_MENU or event.is_released():
		return
	if(event.is_action("ui_down")):
		highlight_idx.y +=1
		if highlight_idx.y>=19:
			highlight_idx.y -=1
			$Panel1.scroll_to_line($Panel1.get_v_scroll_bar().value/32 + 1)
			
	if(event.is_action("ui_up")):
		highlight_idx.y -=1
		if highlight_idx.y<0:
			highlight_idx.y +=1
			$Panel1.scroll_to_line($Panel1.get_v_scroll_bar().value/32 - 1)
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
		#TODO: the thing
		pass
	if(event.is_action("ui_cancel")):
		close_menu()
	get_viewport().set_input_as_handled()
