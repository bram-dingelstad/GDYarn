extends Node

signal values_changed

const Value = preload("res://addons/kyper_gdyarn/core/value.gd")

var variables = {}

func set_value(name, value):
    if !(value is Value):
        variables[name] = Value.new(value)
    else:
        variables[name] = value

    emit_signal('values_changed')

func get_value(name):
    return variables[name] if variables.has(name) else null

func clear_values():
    variables.clear()
    emit_signal('values_changed')
