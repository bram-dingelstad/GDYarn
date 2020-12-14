tool
extends Node

signal node_running(node)
signal command(command)
signal node_completed(node)
signal finished

# TODO: Try to tidy this up
const YarnProgram = preload("res://addons/kyper_gdyarn/core/program/program.gd")
const YarnCompiler = preload("res://addons/kyper_gdyarn/core/compiler/compiler.gd")
const YarnDialogue = preload("res://addons/kyper_gdyarn/core/dialogue.gd")

export(String, FILE, GLOBAL, "*.yarn") var path setget set_path
export(String) var start_node = "Start"
export(bool) var auto_start = false
export(NodePath) var variable_storage_path
export(NodePath) var display_interface_path

onready var display = get_node(display_interface_path)

var program

var dialogue
var running = false

var next_line = ""

func _ready():
	if not Engine.editor_hint:
		dialogue = YarnDialogue.new(get_node(variable_storage_path))
		dialogue.get_vm().lineHandler = funcref(self, "_handle_line")
		dialogue.get_vm().optionsHandler = funcref(self, "_handle_options")
		dialogue.get_vm().commandHandler = funcref(self, "_handle_command")
		dialogue.get_vm().nodeCompleteHandler = funcref(self, "_handle_node_complete")
		dialogue.get_vm().dialogueCompleteHandler = funcref(self, "_handle_dialogue_complete")
		dialogue.get_vm().nodeStartHandler = funcref(self, "_handle_node_start")

		dialogue.set_program(program)

		display._dialogue = dialogue
		display._dialogueRunner = self

		if auto_start:
			start()

func _process(delta):
	if not Engine.editor_hint:
		var state = dialogue.get_exec_state()
		if running and \
			state != YarnGlobals.ExecutionState.WaitingForOption and \
			state != YarnGlobals.ExecutionState.Suspended:
			dialogue.resume()

func set_path(_path):
	var file = File.new()
	file.open(_path, File.READ)
	var source = file.get_as_text()
	file.close()
	
	program = _load_program(source, _path)
	path = _path

func _load_program(source, file_name):
	var program = YarnProgram.new()
	YarnCompiler.compile_string(source, file_name, program, {}, false, false)
	return program

func _handle_line(line):
	emit_signal('line', line)
	return YarnGlobals.HandlerState.PauseExecution

func _handle_command(command):
	emit_signal('command', command)
	return YarnGlobals.HandlerState.ContinueExecution

func _handle_options(options):
	emit_signal('options', options)

func _handle_dialogue_complete():
	emit_signal('finished')
	running = false

func _handle_node_start(node):
	emit_signal('node_running', node)

	if !dialogue._visitedNodeCount.has(node):
		dialogue._visitedNodeCount[node] = 1
	else:
		dialogue._visitedNodeCount[node]+=1

func _handle_node_complete(node):
	emit_signal('node_completed', node)
	return YarnGlobals.HandlerState.ContinueExecution

func start(node = start_node):
	if running:
		return 

	emit_signal('running')

	running = true
	dialogue.set_node(node)

