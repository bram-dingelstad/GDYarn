extends Label

export(NodePath) var storage_path
onready var storage = get_node(storage_path)

func _on_Storage_values_changed():
	text = ''
	text += "Stored Variables:\n"

	for key in storage.variables.keys():
		text += "\t%s : %s \n" % [key, storage.variables[key].as_string()]
		
