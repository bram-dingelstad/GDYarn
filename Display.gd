extends Control

func _on_YarnRunner_line(line):
	$Label.text = line.info.text
