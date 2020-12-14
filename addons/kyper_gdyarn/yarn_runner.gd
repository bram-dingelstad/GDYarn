tool
extends Node

signal node_started(node)
signal line(line)
signal options(options)
signal command(command)
signal node_completed(node)

signal running
signal finished

const YarnCompiler = preload("res://addons/kyper_gdyarn/core/compiler/compiler.gd")
const YarnDialogue = preload("res://addons/kyper_gdyarn/core/dialogue.gd")

export(String, FILE, "*.yarn") var path setget set_path
export(String) var start_node = "Start"
export(bool) var auto_start = false
export(NodePath) var variable_storage_path

onready var variable_storage = get_node(variable_storage_path)

var program

var dialogue
var running = false

func _ready():
	if Engine.editor_hint:
		return

	dialogue = YarnDialogue.new(variable_storage)

	dialogue.get_vm().lineHandler = funcref(self, "_handle_line")
	dialogue.get_vm().optionsHandler = funcref(self, "_handle_options")
	dialogue.get_vm().commandHandler = funcref(self, "_handle_command")
	dialogue.get_vm().nodeCompleteHandler = funcref(self, "_handle_node_complete")
	dialogue.get_vm().dialogueCompleteHandler = funcref(self, "_handle_dialogue_complete")
	dialogue.get_vm().nodeStartHandler = funcref(self, "_handle_node_start")

	dialogue.set_program(program)

	if auto_start:
		start()

func set_path(_path):
	var file = File.new()
	file.open(_path, File.READ)
	var source = file.get_as_text()
	file.close()
	program = YarnCompiler.compile_string(source, _path)
	path = _path

func _handle_line(line):
	emit_signal('line', line)
	return YarnGlobals.HandlerState.PauseExecution

func _handle_command(command):
	emit_signal('command', command)
	return YarnGlobals.HandlerState.PauseExecution

func _handle_options(options):
	emit_signal('options', options)

func _handle_dialogue_complete():
	emit_signal('finished')
	running = false

func _handle_node_start(node):
	emit_signal('node_started', node)
	dialogue.resume()

	if !dialogue._visitedNodeCount.has(node):
		dialogue._visitedNodeCount[node] = 1
	else:
		dialogue._visitedNodeCount[node]+=1

func _handle_node_complete(node):
	emit_signal('node_completed', node)
	return YarnGlobals.HandlerState.PauseExecution

func start(node = start_node):
	if running:
		return 

	emit_signal('running')

	running = true
	dialogue.set_node(node)
