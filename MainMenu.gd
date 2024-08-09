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
	DEF.create_save_file()
	_on_load_pressed()
	pass # Replace with function body.


func _on_load_pressed() -> void:	
	if(FileAccess.file_exists("saveGame.sav")):
		DEF.load_from_file()
		begin_game()
	else:
		print("file not found, starting new game")
		_on_new_pressed()
	pass # Replace with function body.
