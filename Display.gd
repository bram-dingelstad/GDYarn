extends Control

export(NodePath) var runner_path
onready var runner = get_node(runner_path)

func _ready():
	assert(not runner_path.is_empty(), 'Runner path isn\'t set')

func _on_YarnRunner_line(line):
	$Label.text = line.info.text

func _on_YarnRunner_options(options):
	$VBoxContainer.show()

	for button in $VBoxContainer.get_children():
		$VBoxContainer.remove_child(button)
		button.queue_free()
	
	for option in options:
		var button = Button.new()
		button.text = option.line.info.text
		button.connect('pressed', self, '_on_option_pressed', [option.id])
		$VBoxContainer.add_child(button)

func _on_option_pressed(id):
	runner.select_option(id)
	runner.dialogue.resume()
	$VBoxContainer.hide()

func _on_Next_pressed():
	runner.dialogue.resume()

func _on_YarnRunner_finished():
	yield(get_tree().create_timer(1.0), 'timeout')
	hide()
