extends Node

func _ready():
	var flag_path = OS.get_user_data_dir() + "/plugin_preview.flag"
	if not FileAccess.file_exists(flag_path):
		return
	
	await RenderingServer.frame_post_draw
	var img = get_viewport().get_texture().get_image()
	img.save_png(OS.get_user_data_dir() + "/preview_capture.png")
	
	# Borrar el flag
	DirAccess.remove_absolute(flag_path)
	get_tree().quit()
