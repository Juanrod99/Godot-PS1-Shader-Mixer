@tool
extends Control

const EffectData = preload("res://addons/ps1_shader_mixer/effect_data.gd")

var effects = EffectData.EFFECTS
var preview_texture_rect: TextureRect
var shader_material: ShaderMaterial
var checkboxes: Array = []
var sliders: Array = []

func _ready():
	name = "PS1 Shader"
	custom_minimum_size = Vector2(300, 400)
	set_process_input(true)
	mouse_filter = Control.MOUSE_FILTER_PASS
	shader_material = ShaderMaterial.new()
	shader_material.shader = load("res://addons/ps1_shader_mixer/ps1_shader.gdshader")

	var hbox = HBoxContainer.new()
	hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(hbox)

	hbox.add_child(_build_left_panel())
	hbox.add_child(VSeparator.new())
	hbox.add_child(_build_right_panel())

func _build_left_panel() -> VBoxContainer:
	var panel = VBoxContainer.new()
	panel.custom_minimum_size = Vector2(200, 0)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var title = Label.new()
	title.text = "Efectos"
	panel.add_child(title)
	panel.add_child(HSeparator.new())

	for effect in effects:
		_add_effect(panel, effect)
	
	panel.add_child(HSeparator.new())
	_build_presets(panel)

	panel.add_child(HSeparator.new())
	_build_export_button(panel)

	return panel

func _build_right_panel() -> VBoxContainer:
	var panel = VBoxContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var title = Label.new()
	title.text = "Vista Previa"
	panel.add_child(title)
	panel.add_child(HSeparator.new())

	var load_btn = Button.new()
	load_btn.text = "Cargar imagen"
	load_btn.pressed.connect(_load_image)
	panel.add_child(load_btn)

	var capture_btn = Button.new()
	capture_btn.text = "Capturar escena"
	capture_btn.pressed.connect(_capture_viewport)
	panel.add_child(capture_btn)

	var viewport_container = SubViewportContainer.new()
	viewport_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	viewport_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	viewport_container.stretch = true
	panel.add_child(viewport_container)

	var viewport = SubViewport.new()
	viewport.size = Vector2(640, 360)
	viewport_container.add_child(viewport)
	viewport_container.resized.connect(func():
		viewport.size = viewport_container.size
	)
	viewport_container.mouse_filter = Control.MOUSE_FILTER_PASS
	viewport.gui_disable_input = true

	preview_texture_rect = TextureRect.new()
	preview_texture_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	preview_texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	preview_texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	preview_texture_rect.material = shader_material
	viewport.add_child(preview_texture_rect)
	
	return panel

func _add_effect(parent: VBoxContainer, effect: Dictionary):
	var container = VBoxContainer.new()
	parent.add_child(container)
	
	var check = CheckBox.new()
	check.text = effect["label"]
	check.button_pressed = true
	container.add_child(check)
	
	var slider = HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.01
	slider.value = effect["default"]
	container.add_child(slider)
	
	parent.add_child(HSeparator.new())
	
	checkboxes.append(check)
	sliders.append(slider)
	
	check.toggled.connect(func(pressed):
		shader_material.set_shader_parameter(effect["bool"], pressed)
	)
	slider.value_changed.connect(func(value):
		shader_material.set_shader_parameter(effect["float"], value)
	)
	
	shader_material.set_shader_parameter(effect["bool"], true)
	shader_material.set_shader_parameter(effect["float"], effect["default"])

func _build_presets(parent: VBoxContainer):
	var label = Label.new()
	label.text = "Presets"
	parent.add_child(label)
	
	var presets = [
		{"name": "PS1 clásico", "bools": [true, true, false, false, true], "floats": [0.3, 0.4, 0.0, 0.0, 0.6]},
		{"name": "VHS sucio", "bools": [false, true, true, true, false], "floats": [0.0, 0.6, 0.4, 0.7, 0.0]},
		{"name": "Game Boy", "bools": [true, false, false, false, true], "floats": [0.8, 0.0, 0.0, 0.0, 0.2]},
		{"name": "Sin efectos", "bools": [false, false, false, false, false], "floats": [0.0, 0.0, 0.0, 0.0, 0.0]},
	]
	
	for preset in presets:
		var btn = Button.new()
		btn.text = preset["name"]
		btn.pressed.connect(func():
			for i in range(checkboxes.size()):
				checkboxes[i].button_pressed = preset["bools"][i]
				sliders[i].value = preset["floats"][i]
				shader_material.set_shader_parameter(effects[i]["bool"], preset["bools"][i])
				shader_material.set_shader_parameter(effects[i]["float"], preset["floats"][i])
		)
		parent.add_child(btn)

func _build_export_button(parent: VBoxContainer):
	var btn = Button.new()
	btn.text = "Exportar shader"
	btn.pressed.connect(_export_shader)
	parent.add_child(btn)

func _load_image():
	var dialog = EditorFileDialog.new()
	dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_FILE
	dialog.filters = ["*.png, *.jpg, *.jpeg, *.webp ; Imágenes"]
	dialog.file_selected.connect(func(path):
		var img = load(path)
		if img:
			preview_texture_rect.texture = img
		dialog.queue_free()
	)
	add_child(dialog)
	dialog.popup_centered(Vector2(800, 600))

func _export_shader():
	var values = {}
	for i in range(effects.size()):
		values[effects[i]["bool"]] = checkboxes[i].button_pressed
		values[effects[i]["float"]] = sliders[i].value
	
	var code = "shader_type canvas_item;\n\n"
	code += "uniform sampler2D SCREEN_TEXTURE: hint_screen_texture, filter_linear_mipmap;\n\n"
	
	for i in range(effects.size()):
		var b = effects[i]["bool"]
		var f = effects[i]["float"]
		code += "uniform bool %s = %s;\n" % [b, str(values[b]).to_lower()]
		code += "uniform float %s: hint_range(0.0, 1.0) = %s;\n" % [f, str(snappedf(values[f], 0.01))]
	
	code += """
float random(vec2 uv) {
    return fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
    vec2 uv = SCREEN_UV;

    if (use_crt) {
        vec2 centered = uv * 2.0 - 1.0;
        centered *= 1.0 + dot(centered.yx, centered.yx) * crt_amount * 0.3;
        uv = (centered + 1.0) / 2.0;
    }

    if (use_pixelate) {
        float pixels = mix(512.0, 32.0, pixel_size);
        uv = floor(uv * pixels) / pixels;
    }

    vec4 col = texture(SCREEN_TEXTURE, uv);

    if (use_chromatic_aberration) {
        float amount = aberration_amount * 0.05;
        col.r = texture(SCREEN_TEXTURE, uv + vec2(amount, 0.0)).r;
        col.b = texture(SCREEN_TEXTURE, uv - vec2(amount, 0.0)).b;
    }

    if (use_color_quantization) {
        float levels = mix(2.0, 32.0, color_levels);
        col.rgb = floor(col.rgb * levels) / levels;
    }

    if (use_dithering) {
        float dither = random(uv + vec2(TIME * 0.01)) * dithering_intensity * 0.1;
        col.rgb += dither;
    }

    if (use_scanlines) {
        float scan = sin(uv.y / SCREEN_PIXEL_SIZE.y) * 0.5 + 0.5;
        col.rgb -= scan * scanlines_opacity * 0.2;
    }

    if (use_vhs_noise) {
        float noise = random(vec2(uv.y + TIME, 0.0)) * noise_intensity * 0.1;
        col.rgb += noise;
    }

    if (use_crt) {
        if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
            col = vec4(0.0, 0.0, 0.0, 1.0);
        }
    }

    COLOR = col;
}
"""
	
	var dialog = EditorFileDialog.new()
	dialog.file_mode = EditorFileDialog.FILE_MODE_SAVE_FILE
	dialog.filters = ["*.gdshader ; Shader de Godot"]
	dialog.current_file = "mi_shader_ps1.gdshader"
	dialog.file_selected.connect(func(path):
		var file = FileAccess.open(path, FileAccess.WRITE)
		file.store_string(code)
		file.close()
		dialog.queue_free()
		print("Shader exportado en: ", path)
	)
	add_child(dialog)
	dialog.popup_centered(Vector2(800, 600))

func _can_drop_data(at_position: Vector2, data) -> bool:
	if typeof(data) == TYPE_DICTIONARY and data.has("files"):
		var files = data["files"]
		if files.size() > 0:
			var ext = files[0].get_extension().to_lower()
			return ext in ["png", "jpg", "jpeg", "webp"]
	return false

func _drop_data(at_position: Vector2, data) -> void:
	if typeof(data) == TYPE_DICTIONARY and data.has("files"):
		var path = data["files"][0]
		var img = load(path)
		if img:
			preview_texture_rect.texture = img

func _capture_viewport() -> void:
	var viewport = EditorInterface.get_editor_viewport_3d(0)
	if viewport == null:
		viewport = EditorInterface.get_editor_viewport_2d()
	if viewport == null:
		print("No se pudo capturar el viewport")
		return
	
	await RenderingServer.frame_post_draw
	var img = viewport.get_texture().get_image()
	if img:
		var tex = ImageTexture.create_from_image(img)
		preview_texture_rect.texture = tex
