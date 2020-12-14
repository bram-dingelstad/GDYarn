tool extends Node

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

var locales = {}
var program

var dialogue
var dialogue_started = false

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
		if dialogue_started and \
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
	YarnCompiler.compile_string(source, file_name, program, locales, false, false)
	return program

func _handle_line(line):
	var text =  locales.get(line.id).text;
	_pass_line(text)

	return YarnGlobals.HandlerState.PauseExecution

func consume_line():
	_pass_line(next_line)
	next_line = ""

func _pass_line(line_text):
	if display != null and \
		not display.feed_line(line_text):
		next_line = line_text

func _handle_command(command):
	return YarnGlobals.HandlerState.ContinueExecution

func _handle_options(option_set):
	if not display:
		return

	var line_options = []
	for index in range(option_set.options.size()):
		line_options.append(locales[option_set.options[index].line.id].text)

	display.feed_options(line_options)

func _handle_dialogue_complete():
	if display != null:
		display._dialogue_finished()
	dialogue_started = false

func _handle_node_start(node):
	if !dialogue._visitedNodeCount.has(node):
		dialogue._visitedNodeCount[node] = 1
	else:
		dialogue._visitedNodeCount[node]+=1

func _handle_node_complete(node):
	return YarnGlobals.HandlerState.ContinueExecution

func start(node = start_node):
	if dialogue_started:
		return 

	dialogue_started = true
	dialogue.set_node(node)

