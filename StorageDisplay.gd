extends Label

export(NodePath) var storage_path
onready var storage = get_node(storage_path)

var strings = []

func _on_Storage_values_changed():
	strings.resize(0)
	strings.append("Stored Variables:\n")

	for key in storage.variables.keys():
		strings.append("\t%s : %s \n" % [key, storage.variables[key].as_string()])

	text = strings.join("");
