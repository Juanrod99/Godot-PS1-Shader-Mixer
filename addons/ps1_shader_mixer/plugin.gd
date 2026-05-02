@tool
extends EditorPlugin

var panel

func _enter_tree():
	panel = preload("res://addons/ps1_shader_mixer/shader_mixer_panel.gd").new()
	panel.name = "PS1 Shader"
	add_control_to_dock(DOCK_SLOT_RIGHT_UL, panel)

func _exit_tree():
	remove_control_from_docks(panel)
	panel.queue_free()
