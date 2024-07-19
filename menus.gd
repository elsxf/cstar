extends Control

enum Mode{CHOICE_OF,DISPLAY,TILE}

var ContainerSrc = null
var ContainerSrc2 = null
var ContainerLambda = null
var highLight_idx = Vector2i(DEF.LEFT,0)
var title : String = ""
var mode : int = Mode.DISPLAY
var onChoiceLambda

func choiceOf(tabName:String, choices:Array, onchoice_lambda):
	title = tabName
	mode = Mode.CHOICE_OF
	onChoiceLambda = onchoice_lambda
	highLight_idx = Vector2i(DEF.LEFT,0)
	$MenuBack.visible = true
	$MenuBack/Panel2.visible = false
	$TitleCard.visible = false
	$Popup.visible = false
	DEF.changeFocus(DEF.Focus.GAME_MENU)
	ContainerSrc = choices
	
func choiceTile(tabName:String,onchoice_lambda):
	mode = Mode.TILE
	onChoiceLambda = onchoice_lambda
	$MenuBack.visible = false
	$TitleCard.visible = true
	$Popup.visible = false
	$TitleCard.text = tabName
	DEF.changeFocus(DEF.Focus.GAME_MENU)
	
func displayLists(tabName:String, panel1Lists:Array = [], panel1Names:Array = [], Panel2Lists:Array = [], Panel2Names:Array = []):
	title = tabName
	mode = Mode.DISPLAY
	highLight_idx = Vector2i(DEF.LEFT,0)
	$MenuBack.visible = true
	$TitleCard.visible = false
	$Popup.visible = false
	$MenuBack/Text.text = ""
	$MenuBack/Panel2.text = ""
	DEF.changeFocus(DEF.Focus.GAME_MENU)
	
	if not panel1Lists.is_empty():
		$MenuBack/Text.visible = true
		ContainerSrc = []
		for i in range(panel1Lists.size()):
			ContainerSrc.append_array(panel1Lists[i])
			if i<panel1Names.size():
				print("got here :",panel1Names[i])
				$MenuBack/Text.text+=panel1Names[i]
			$MenuBack/Text.text+=listStr(panel1Lists[i])
	
	if not Panel2Lists.is_empty():
		$MenuBack/Panel2.visible = true
		ContainerSrc2 = []
		for i in range(Panel2Lists.size()):
			ContainerSrc2.append_array(Panel2Lists[i])
			if i<Panel2Names.size()-1:
				$MenuBack/Panel2.text+=Panel2Names[i]
			$MenuBack/Panel2.text+=listStr(Panel2Lists[i])
	
func display(tabName:String, panel1:Array = [], panel2_lambda = null):
	#displays list in panel 1 and does panel2_lambda to each item and displays the result in panel 2
	title = tabName
	mode = Mode.DISPLAY
	highLight_idx = Vector2i(DEF.LEFT,0)
	$MenuBack.visible = true
	$TitleCard.visible = false
	$Popup.visible = false
	DEF.changeFocus(DEF.Focus.GAME_MENU)

	ContainerSrc = panel1
	#TODO: multiple panels
	if panel2_lambda==null:
		$MenuBack/Panel2.visible = false
		ContainerLambda = null
	else:
		ContainerLambda = panel2_lambda
		$MenuBack/Panel2.visible = true

func listStr(itemList:Array)->String:
	var result = ""
	for i in itemList:
		result+=str(i)+"\n"
	return result
	
func lambdaStr(itemList:Array)->String:
	var result = ""
	for i in itemList:
		result+=str(ContainerLambda.call(i))+"\n"
	return result
	
func closeMenu():
	$MenuBack.visible = false
	$TitleCard.visible = false
	$Popup.visible = false
	ContainerLambda=null
	ContainerSrc=null
	ContainerSrc2=null
	DEF.changeFocus(DEF.Focus.WORLD)
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if DEF.gameState["focus"]==DEF.Focus.GAME_MENU:
		$MenuBack/Title.text = "[color=pink][u]"+title+"[/u][/color]\n"
		if(ContainerSrc!=null):
			$MenuBack/Text.text = listStr(ContainerSrc)
		if (ContainerSrc2!=null):
			$MenuBack/Panel2.text = listStr(ContainerSrc2)
		elif(ContainerLambda!=null):
			$MenuBack/Panel2.text = lambdaStr(ContainerSrc)
		#move highlight
		if( $MenuBack/Text/Highlight.position.y!=-1):
			$MenuBack/Text/Highlight.position.x= 0 if highLight_idx.x else $MenuBack.size.x/2
			$MenuBack/Text/Highlight.position.y = 32 * highLight_idx.y

func _unhandled_key_input(event):
	if DEF.gameState["focus"]!=DEF.Focus.GAME_MENU or event.is_released() or not event.is_action_type():
		return
	if event.is_action("ui_down", true):
		highLight_idx.y+=1
		var vis = 19#TODO: use non-shitty function
		if highLight_idx.y>=vis:
			highLight_idx.y-=1
			$MenuBack/Text.scroll_to_line($MenuBack/Text.get_v_scroll_bar().value/32+1)
			$MenuBack/Panel2.scroll_to_line($MenuBack/Text.get_v_scroll_bar().value/32+1)
	if event.is_action("ui_up", true):
		highLight_idx.y-=1
		if highLight_idx.y<0:
			highLight_idx.y+=1
			$MenuBack/Text.scroll_to_line($MenuBack/Text.get_v_scroll_bar().value/32-1)
			$MenuBack/Panel2.scroll_to_line($MenuBack/Text.get_v_scroll_bar().value/32-1)
	if event.is_action("ui_left", true) or event.is_action("ui_right", true):
		highLight_idx.x= 0 if highLight_idx.x else 1
	if event.is_action("ui_select"):
		var select_idx = highLight_idx.y + $MenuBack/Text.get_v_scroll_bar().value/32
		match mode:
			Mode.CHOICE_OF:
				var choiceMade = ContainerSrc.pop_at(select_idx)
				var action_lambda = func menu_action_lambda(calc):
					return onChoiceLambda.call(choiceMade,calc)
				Signals.emit_signal("Player_take_action",action_lambda)
			Mode.DISPLAY:
				match title:
					"Inventory":
						#TODO: verbose display of item
						pass
					"Keybindings":
						DEF.actionBinds[ContainerSrc[select_idx]] = await $Popup.popInput("Enter a new Key:")
						DEF.keyBinds = DEF.reverseDict(DEF.actionBinds)
						#TODO: remap keys
						pass
	
	if mode == Mode.TILE:
		var horiz_vector = null
		if(event.is_action("Left")):
			horiz_vector =HEX.dir_vec[3]
		if(event.is_action("Right")):
			horiz_vector =HEX.dir_vec[0]
		if(event.is_action("URight")):
			horiz_vector =HEX.dir_vec[1]
		if(event.is_action("DRight")):
			horiz_vector =HEX.dir_vec[5]
		if(event.is_action("ULeft")):
			horiz_vector =HEX.dir_vec[2]
		if(event.is_action("DLeft")):
			horiz_vector =HEX.dir_vec[4]
		if(horiz_vector!=null):
			var choiceMade = HEX.add_2_3(DEF.playerM.curr_c(),horiz_vector)
			var action_lambda = func menu_action_lambda(calc):
				return onChoiceLambda.call(choiceMade,calc)
			Signals.emit_signal("Player_take_action",action_lambda)
			closeMenu()
					
	
	
	if(event.is_action("OpenInventory", true)||event.is_action("ui_cancel", true)):
		closeMenu()
		
	get_viewport().set_input_as_handled()


func _on_text_visibility_changed() -> void:
	$MenuBack/Text.scroll_to_line(1)
	pass # Replace with function body.
