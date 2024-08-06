extends Control

var Oworld = preload("res://overworld.tscn").instantiate()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	DEF.process_json()
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func begin_game():
	get_tree().root.add_child(Oworld)
	queue_free()

func _on_new_pressed() -> void:
	#newgame stuff
	DEF.playerM = Mob.new("Player")
	
	Item.new("Wood","Sword").add_to_container(DEF.playerM.items,DEF.playerM)
	Item.new("Stone","Sword").add_to_container(DEF.playerM.items,DEF.playerM)
	Item.new("Metal","Sword").add_to_container(DEF.playerM.items,DEF.playerM)
	Item.new("Wood","Spear").add_to_container(DEF.playerM.items,DEF.playerM)
	Item.new("Stone","Spear").add_to_container(DEF.playerM.items,DEF.playerM)
	Item.new("Metal","Spear").add_to_container(DEF.playerM.items,DEF.playerM)
	
	GEN.init_random()
	
	GEN.gen_overworld(Vector2(0,0))
	DEF.playerM.add_to_data(DEF.current_mobs,Vector2i(DEF.chunk_size/2,DEF.chunk_size/2),-1)
	DEF.saveState[DEF.SAVE_OVERWORLD] = DEF.save_chunk()
	
	DEF.current_coords=null
	DEF.current_level=-1
	
	
	begin_game()
	pass # Replace with function body.


func _on_load_pressed() -> void:	
	if(FileAccess.file_exists("saveGame.sav")):
		DEF.load_from_file()
		begin_game()
	else:
		print("file not found, starting new game")
		_on_new_pressed()
	pass # Replace with function body.
