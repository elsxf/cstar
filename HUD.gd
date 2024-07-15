extends CanvasLayer

#updated by overworld.gd
var last_action_cost:int=-1
var last_action_name:String = "noAct"

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	#terminal update
	if not DEF.textBuffer.is_empty():
		$Panel/Term.append_text(DEF.textBuffer)
		DEF.textBuffer = ""
		
	#Info panel pdate
	$Panel/Info.text = "HP : "+str(DEF.playerM.Hp)+"/"+str(DEF.playerM.Hp_max)+"\n"\
	+"Last Action : "+last_action_name+"\n"\
	+"last action cost : "+str(last_action_cost)+"\n"\
	+"time units : "+str(DEF.playerM.time_u)+"\n"\
	+"world_c : "+str(DEF.playerM.world_c)+"\n"\
	+"dun_c : "+str(DEF.playerM.dun_c)+"\n"\
	+"d_level : "+str(DEF.playerM.d_level)+"\n"
	pass
